#!/usr/local/bin/bash

#############################################################################
# GitHub Issues Batch Creator
# Optimized for Bash 5+ (Homebrew) and GitHub CLI
#
# Read GITHUB_ISSUES_AND_PROJECT_BOARD.md for full instructions and tasks.json schema rules.
#
#############################################################################

set -e

#############################################################################
# Configuration (overridable via environment variables)
#############################################################################
REPO="${REPO:-monetarium/monetarium-explorer}"
MILESTONE="${MILESTONE:-v1}"
TASKS_FILE="tasks.json"
DRY_RUN=false
STATE_FILE=".create_issues_state.json"

#############################################################################
# Parse CLI arguments
#############################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --file)
            TASKS_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--dry-run] [--file <tasks_file.json>]"
            exit 1
            ;;
    esac
done

#############################################################################
# Check dependencies
#############################################################################
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Run: brew install jq"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "Error: gh is not installed. Run: brew install gh && gh auth login"
    exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
    echo "Error: Tasks file '$TASKS_FILE' not found!"
    exit 1
fi

#############################################################################
# Validate tasks.json structure
#############################################################################
echo "--- Validating $TASKS_FILE ---"

task_count=$(jq '.tasks | length' "$TASKS_FILE")

if [[ "$task_count" -eq 0 ]]; then
    echo "Error: No tasks found in $TASKS_FILE."
    exit 1
fi

validation_errors=0

for (( i=0; i<task_count; i++ )); do
    type=$(jq -r ".tasks[$i].type" "$TASKS_FILE")
    title=$(jq -r ".tasks[$i].title" "$TASKS_FILE")

    # Validate type
    if [[ "$type" != "parent" && "$type" != "sub-issue" && "$type" != "issue" ]]; then
        echo "  [!] tasks[$i]: Invalid type '$type'. Must be 'parent', 'sub-issue', or 'issue'."
        (( validation_errors++ )) || true
    fi

    # Validate title
    if [[ -z "$title" || "$title" == "null" ]]; then
        echo "  [!] tasks[$i]: Missing or null 'title'."
        (( validation_errors++ )) || true
    fi

    # Validate parent index for sub-issues
    if [[ "$type" == "sub-issue" ]]; then
        parent_idx=$(jq -r ".tasks[$i].parent" "$TASKS_FILE")

        if [[ -z "$parent_idx" || "$parent_idx" == "null" ]]; then
            echo "  [!] tasks[$i] ('$title'): sub-issue is missing 'parent' index."
            (( validation_errors++ )) || true
        elif [[ "$parent_idx" -ge "$task_count" ]]; then
            echo "  [!] tasks[$i] ('$title'): 'parent' index $parent_idx is out of bounds (max: $((task_count - 1)))."
            (( validation_errors++ )) || true
        else
            parent_type=$(jq -r ".tasks[$parent_idx].type" "$TASKS_FILE")
            if [[ "$parent_type" != "parent" ]]; then
                echo "  [!] tasks[$i] ('$title'): 'parent' index $parent_idx does not point to a 'parent' type task."
                (( validation_errors++ )) || true
            fi
            if [[ "$parent_idx" -ge "$i" ]]; then
                echo "  [!] tasks[$i] ('$title'): 'parent' index $parent_idx must appear BEFORE the sub-issue in the array."
                (( validation_errors++ )) || true
            fi
        fi
    fi
done

if [[ "$validation_errors" -gt 0 ]]; then
    echo ""
    echo "Validation failed with $validation_errors error(s). Fix $TASKS_FILE and re-run."
    exit 1
fi

echo "  ✅ Validation passed ($task_count tasks found)."
echo ""

#############################################################################
# Dry-run notice
#############################################################################
if $DRY_RUN; then
    echo "⚠️  DRY-RUN MODE: No issues will be created. Showing plan:"
    echo ""
    for (( i=0; i<task_count; i++ )); do
        type=$(jq -r ".tasks[$i].type" "$TASKS_FILE")
        title=$(jq -r ".tasks[$i].title" "$TASKS_FILE")
        assignee=$(jq -r ".tasks[$i].assignee // \"(unassigned)\"" "$TASKS_FILE")
        labels=$(jq -r '(.tasks['"$i"'].labels // ["enhancement"]) | join(", ")' "$TASKS_FILE")
        if [[ "$type" == "parent" ]]; then
            issue_type=$(jq -r ".tasks[$i].issue_type // \"Feature\"" "$TASKS_FILE")
            echo "  [PARENT]    $title | type: $issue_type | assignee: $assignee | labels: $labels"
        elif [[ "$type" == "sub-issue" ]]; then
            issue_type=$(jq -r ".tasks[$i].issue_type // \"Task\"" "$TASKS_FILE")
            parent_idx=$(jq -r ".tasks[$i].parent" "$TASKS_FILE")
            parent_title=$(jq -r ".tasks[$parent_idx].title" "$TASKS_FILE")
            echo "  [SUB-ISSUE] $title | type: $issue_type | assignee: $assignee | labels: $labels | parent: [$parent_title]"
        else
            issue_type=$(jq -r ".tasks[$i].issue_type // \"Task\"" "$TASKS_FILE")
            echo "  [ISSUE]     $title | type: $issue_type | assignee: $assignee | labels: $labels"
        fi
    done
    echo ""
    echo "Dry-run complete. Re-run without --dry-run to create issues."
    exit 0
fi

#############################################################################
# Load or initialize idempotency state
#############################################################################
if [[ ! -f "$STATE_FILE" ]]; then
    echo "{}" > "$STATE_FILE"
    echo "No state file found. Starting fresh."
else
    echo "Found existing state file ($STATE_FILE). Resuming — already-created issues will be skipped."
fi
echo ""

# Associative array: JSON index -> GitHub issue number
declare -A ISSUE_MAP

# Load previously created parent issues from state
state_keys=$(jq -r 'keys[]' "$STATE_FILE" 2>/dev/null || true)
for key in $state_keys; do
    num=$(jq -r ".\"$key\"" "$STATE_FILE")
    ISSUE_MAP[$key]=$num
done

#############################################################################
# Fetch Org Issue Types Mapping
# Issue types require their numeric database ID for the PATCH API.
# This queries the org once to map names to IDs.
#############################################################################
declare -A ISSUE_TYPES
ORG_NAME=$(echo "$REPO" | cut -d'/' -f1)
echo "--- Fetching Org Issue Types ($ORG_NAME) ---"
if types_raw=$(gh api "/orgs/$ORG_NAME/issue-types" 2>/dev/null); then
    # jq parses the array of objects into lines of "Name|NodeID"
    while IFS="|" read -r t_name t_node_id; do
        ISSUE_TYPES["$t_name"]="$t_node_id"
    done <<< "$(echo "$types_raw" | jq -r '.[]? | "\(.name)|\(.node_id)"')"
    echo "  Loaded ${#ISSUE_TYPES[@]} issue types: ${!ISSUE_TYPES[*]}"
else
    echo "  (No issue types found for org '$ORG_NAME' or token lacks permission. Continuing without types...)"
fi
echo ""

#############################################################################
# Helper: build --label flags from a JSON array or default
#############################################################################
build_label_flags() {
    local idx=$1
    local raw_labels
    raw_labels=$(jq -r ".tasks[$idx].labels // [\"enhancement\"] | .[]" "$TASKS_FILE")
    local flags=""
    while IFS= read -r label; do
        flags="$flags --label \"$label\""
    done <<< "$raw_labels"
    echo "$flags"
}

#############################################################################
# Helper: set GitHub issue type (Feature / Task / Bug) via REST API
# Requires the org to have issue types configured in GitHub settings.
# Fails gracefully — a type error will NOT abort the script.
#############################################################################
set_issue_type() {
    local issue_node_id="$1"
    local type_name="$2"
    local type_node_id="${ISSUE_TYPES[$type_name]:-""}"

    if [[ -z "$type_node_id" ]]; then
        echo -n "(type '$type_name' not found in org settings) "
        return
    fi
    if [[ -z "$issue_node_id" ]]; then
        echo -n "(type not set - missing issue node id) "
        return
    fi

    # Issue types MUST be set via GraphQL (REST API PATCH ignores it silently)
    if gh api graphql -f query="
        mutation {
            updateIssue(input: {
                id: \"$issue_node_id\",
                issueTypeId: \"$type_node_id\"
            }) {
                issue { number }
            }
        }" &>/dev/null; then
        echo -n "(type: $type_name) "
    else
        echo -n "(type not set) "
    fi
}

#############################################################################
# Stats counters
#############################################################################
parents_created=0
parents_skipped=0
subissues_created=0
subissues_skipped=0
declare -a created_parent_nums=()

#############################################################################
# Step 1: Create PARENT issues
#############################################################################
echo "--- Step 1: Creating Parent Issues ---"

for (( i=0; i<task_count; i++ )); do
    type=$(jq -r ".tasks[$i].type" "$TASKS_FILE")
    [[ "$type" != "parent" ]] && continue

    # Idempotency check
    if [[ -n "${ISSUE_MAP[$i]+_}" ]]; then
        echo "  ⏭️  Skipping parent tasks[$i] — already created as #${ISSUE_MAP[$i]}"
        (( parents_skipped++ )) || true
        continue
    fi

    title=$(jq -r ".tasks[$i].title" "$TASKS_FILE")
    description=$(jq -r ".tasks[$i].description // \"\"" "$TASKS_FILE")
    assignee=$(jq -r ".tasks[$i].assignee // empty" "$TASKS_FILE")

    # Build label flags
    label_flags=()
    while IFS= read -r label; do
        label_flags+=("--label" "$label")
    done < <(jq -r ".tasks[$i].labels // [\"enhancement\"] | .[]" "$TASKS_FILE")

    # Build assignee flag
    assignee_flags=()
    [[ -n "$assignee" ]] && assignee_flags=("--assignee" "$assignee")

    issue_type=$(jq -r ".tasks[$i].issue_type // \"Feature\"" "$TASKS_FILE")
    echo -n "  Creating: [$title]... "

    url=$(gh issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$description" \
        --milestone "$MILESTONE" \
        "${label_flags[@]}" \
        "${assignee_flags[@]+"${assignee_flags[@]}"}")

    num=$(echo "$url" | grep -oE '[0-9]+$')
    ISSUE_MAP[$i]=$num

    # Get the GraphQL node ID so we can set the issue type
    issue_node_id=$(gh api "/repos/$REPO/issues/$num" --jq '.node_id' 2>/dev/null || echo "")

    # Persist to state file
    tmp=$(jq ". + {\"$i\": $num}" "$STATE_FILE")
    echo "$tmp" > "$STATE_FILE"

    # Set GitHub issue type via GraphQL
    set_issue_type "$issue_node_id" "$issue_type"

    (( parents_created++ )) || true
    created_parent_nums+=("#$num")
    echo "✅ #$num"

    sleep 0.5  # Rate limiting
done

echo ""

#############################################################################
# Step 2: Create SUB-ISSUES and link natively to parents
#############################################################################
echo "--- Step 2: Creating Sub-Issues ---"

for (( i=0; i<task_count; i++ )); do
    type=$(jq -r ".tasks[$i].type" "$TASKS_FILE")
    [[ "$type" != "sub-issue" ]] && continue

    # Idempotency check
    if [[ -n "${ISSUE_MAP[$i]+_}" ]]; then
        echo "  ⏭️  Skipping sub-issue tasks[$i] — already created as #${ISSUE_MAP[$i]}"
        (( subissues_skipped++ )) || true
        continue
    fi

    title=$(jq -r ".tasks[$i].title" "$TASKS_FILE")
    description=$(jq -r ".tasks[$i].description // \"\"" "$TASKS_FILE")
    assignee=$(jq -r ".tasks[$i].assignee // empty" "$TASKS_FILE")
    parent_idx=$(jq -r ".tasks[$i].parent" "$TASKS_FILE")
    parent_num=${ISSUE_MAP[$parent_idx]:-""}

    # Append "Part of #N" to body only if native linking not available as fallback
    if [[ -n "$parent_num" ]]; then
        full_body="${description}"$'\n\n'"Part of #$parent_num"
    else
        full_body="$description"
    fi

    # Build label flags
    label_flags=()
    while IFS= read -r label; do
        label_flags+=("--label" "$label")
    done < <(jq -r ".tasks[$i].labels // [\"enhancement\"] | .[]" "$TASKS_FILE")

    # Build assignee flag
    assignee_flags=()
    [[ -n "$assignee" ]] && assignee_flags=("--assignee" "$assignee")

    issue_type=$(jq -r ".tasks[$i].issue_type // \"Task\"" "$TASKS_FILE")
    echo -n "  Creating: [$title] (child of #$parent_num)... "

    child_url=$(gh issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$full_body" \
        --milestone "$MILESTONE" \
        "${label_flags[@]}" \
        "${assignee_flags[@]+"${assignee_flags[@]}"}")

    child_num=$(echo "$child_url" | grep -oE '[0-9]+$')
    ISSUE_MAP[$i]=$child_num

    # Fetch IDs necessary for setting type and linking sub-issues
    child_resp=$(gh api "/repos/$REPO/issues/$child_num" --jq '{db_id: .id, node_id: .node_id}' 2>/dev/null || echo "{}")
    child_db_id=$(echo "$child_resp" | jq -r '.db_id // empty')
    child_node_id=$(echo "$child_resp" | jq -r '.node_id // empty')

    # Persist to state file
    tmp=$(jq ". + {\"$i\": $child_num}" "$STATE_FILE")
    echo "$tmp" > "$STATE_FILE"

    # Set GitHub issue type via GraphQL
    set_issue_type "$child_node_id" "$issue_type"

    # Native sub-issue linking via GitHub API
    if [[ -n "$parent_num" ]]; then
        # The sub_issues endpoint requires the database ID (not the issue #number)
        if [[ -n "$child_db_id" ]]; then
            gh api --method POST "/repos/$REPO/issues/$parent_num/sub_issues" \
                --field sub_issue_id="$child_db_id" &>/dev/null \
                && echo -n "(linked natively) " \
                || echo -n "(link failed) "
        else
            echo -n "(could not fetch db id) "
        fi
    fi

    (( subissues_created++ )) || true
    echo "✅ #$child_num"

    sleep 0.5  # Rate limiting
done



#############################################################################
# Summary
#############################################################################
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Done! Summary for [$REPO] @ milestone [$MILESTONE]"
echo "────────────────────────────────────────────────"
echo "  Parent issues created : $parents_created  (skipped: $parents_skipped)"
echo "  Sub-issues created    : $subissues_created  (skipped: $subissues_skipped)"
if [[ ${#created_parent_nums[@]} -gt 0 ]]; then
    echo "  New parent issue #s   : ${created_parent_nums[*]}"
fi
echo "════════════════════════════════════════════════"

# Clean up state on full success
rm -f "$STATE_FILE"
echo "  State file cleaned up."
echo ""
