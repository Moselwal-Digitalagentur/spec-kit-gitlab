#!/usr/bin/env bash
# gitlab-helpers.sh - Shared Helper-Funktionen für spec-kit GitLab Extension
set -euo pipefail

# ============================================================================
# Konfiguration laden
# ============================================================================

load_gitlab_config() {
  local config_file="${1:-.specify/extensions/gitlab/gitlab-config.yml}"
  local local_override="${config_file%.yml}.local.yml"

  if [[ -f "$local_override" ]]; then
    config_file="$local_override"
  fi

  if [[ ! -f "$config_file" ]]; then
    echo "ERROR: GitLab-Konfiguration nicht gefunden: $config_file" >&2
    echo "Führe 'specify extension add --dev ~/spec-kit-gitlab/' aus." >&2
    return 1
  fi

  # Werte aus Config extrahieren (einfaches YAML-Parsing)
  GITLAB_URL="${GITLAB_URL:-$(grep '^\s*url:' "$config_file" | head -1 | sed 's/.*url:\s*//' | tr -d '"' | tr -d "'")}"
  GITLAB_PROJECT="${GITLAB_PROJECT:-$(grep '^\s*project:' "$config_file" | head -1 | sed 's/.*project:\s*//' | tr -d '"' | tr -d "'")}"
  GITLAB_STORY_LABEL="$(grep '^\s*story_label:' "$config_file" | head -1 | sed 's/.*story_label:\s*//' | tr -d '"' | tr -d "'")"
  GITLAB_TASK_LABEL="$(grep '^\s*task_label:' "$config_file" | head -1 | sed 's/.*task_label:\s*//' | tr -d '"' | tr -d "'")"
  GITLAB_SPECKIT_LABEL="$(grep '^\s*speckit_label:' "$config_file" | head -1 | sed 's/.*speckit_label:\s*//' | tr -d '"' | tr -d "'")"
  GITLAB_PRIORITY_TO_LABEL="$(grep '^\s*priority_to_label:' "$config_file" | head -1 | sed 's/.*priority_to_label:\s*//' | tr -d ' ')"
  GITLAB_LINK_TASKS="$(grep '^\s*link_tasks_to_stories:' "$config_file" | head -1 | sed 's/.*link_tasks_to_stories:\s*//' | tr -d ' ')"
  GITLAB_FEATURE_TO_MILESTONE="$(grep '^\s*feature_to_milestone:' "$config_file" | head -1 | sed 's/.*feature_to_milestone:\s*//' | tr -d ' ')"

  # Defaults
  GITLAB_STORY_LABEL="${GITLAB_STORY_LABEL:-user-story}"
  GITLAB_TASK_LABEL="${GITLAB_TASK_LABEL:-task}"
  GITLAB_SPECKIT_LABEL="${GITLAB_SPECKIT_LABEL:-spec-kit}"
  GITLAB_PRIORITY_TO_LABEL="${GITLAB_PRIORITY_TO_LABEL:-true}"
  GITLAB_LINK_TASKS="${GITLAB_LINK_TASKS:-true}"
  GITLAB_FEATURE_TO_MILESTONE="${GITLAB_FEATURE_TO_MILESTONE:-true}"

  # Validierung
  if [[ -z "$GITLAB_URL" || "$GITLAB_URL" == '${GITLAB_URL}' ]]; then
    echo "ERROR: GITLAB_URL nicht konfiguriert. Setze die URL in gitlab-config.yml oder als Umgebungsvariable." >&2
    return 1
  fi
  if [[ -z "$GITLAB_PROJECT" || "$GITLAB_PROJECT" == '${GITLAB_PROJECT}' ]]; then
    echo "ERROR: GITLAB_PROJECT nicht konfiguriert." >&2
    return 1
  fi
}

# ============================================================================
# glab-Wrapper
# ============================================================================

glab_cmd() {
  # Führt glab mit korrektem Host aus
  GITLAB_HOST="$GITLAB_URL" glab "$@" --repo "$GITLAB_PROJECT"
}

glab_create_issue() {
  local title="$1"
  local description="${2:-}"
  local labels="${3:-}"
  local issue_type="${4:-}"
  local milestone="${5:-}"

  local args=(issue create --title "$title" --yes)

  if [[ -n "$description" ]]; then
    args+=(--description "$description")
  fi
  if [[ -n "$labels" ]]; then
    args+=(--label "$labels")
  fi
  if [[ -n "$issue_type" ]]; then
    args+=(--type "$issue_type")
  fi
  if [[ -n "$milestone" ]]; then
    args+=(--milestone "$milestone")
  fi

  glab_cmd "${args[@]}" 2>&1
}

glab_list_issues() {
  local labels="${1:-$GITLAB_SPECKIT_LABEL}"
  local state="${2:-all}"

  glab_cmd issue list --label "$labels" --state "$state" --output json 2>/dev/null || echo "[]"
}

glab_view_issue() {
  local issue_number="$1"
  glab_cmd issue view "$issue_number" --output json 2>/dev/null
}

glab_add_relation() {
  local child_issue="$1"
  local parent_issue="$2"
  # Verlinkt Child-Issue mit Parent-Issue
  glab_cmd issue relation add "$child_issue" --related "$parent_issue" 2>/dev/null || true
}

# ============================================================================
# Mapping-Datei Management
# ============================================================================

MAPPING_FILE=".gitlab-mapping.yml"

init_mapping_file() {
  local feature_dir="$1"
  local mapping_path="$feature_dir/$MAPPING_FILE"

  if [[ ! -f "$mapping_path" ]]; then
    cat > "$mapping_path" << 'YAML'
# GitLab Issue Mapping - automatisch generiert von spec-kit GitLab Extension
# Format: spec-kit ID → GitLab Issue Nummer und URL
stories: {}
tasks: {}
YAML
  fi
  echo "$mapping_path"
}

read_mapping() {
  local mapping_path="$1"
  local section="$2"  # "stories" oder "tasks"
  local id="$3"

  if [[ ! -f "$mapping_path" ]]; then
    return 1
  fi

  # Liest Issue-Nummer für gegebene ID aus der Mapping-Datei
  local in_section=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^${section}: ]]; then
      in_section=true
      continue
    fi
    if [[ "$in_section" == true ]]; then
      if [[ "$line" =~ ^[a-z] ]]; then
        break  # Neue Section beginnt
      fi
      if [[ "$line" =~ ^[[:space:]]+${id}: ]]; then
        echo "$line" | sed "s/.*${id}:\s*//" | tr -d '"' | tr -d "'"
        return 0
      fi
    fi
  done < "$mapping_path"

  return 1
}

write_mapping() {
  local mapping_path="$1"
  local section="$2"  # "stories" oder "tasks"
  local id="$3"
  local issue_number="$4"
  local issue_url="${5:-}"

  if [[ ! -f "$mapping_path" ]]; then
    init_mapping_file "$(dirname "$mapping_path")" > /dev/null
  fi

  local entry="  ${id}: \"#${issue_number}"
  if [[ -n "$issue_url" ]]; then
    entry+=" ${issue_url}"
  fi
  entry+="\""

  # Prüfe ob Eintrag bereits existiert
  if grep -q "^\s*${id}:" "$mapping_path" 2>/dev/null; then
    # Update bestehenden Eintrag
    sed -i.bak "s|^\(\s*\)${id}:.*|${entry}|" "$mapping_path"
    rm -f "${mapping_path}.bak"
  else
    # Neuen Eintrag nach Section-Header einfügen
    sed -i.bak "/^${section}:/a\\
${entry}" "$mapping_path"
    rm -f "${mapping_path}.bak"
  fi
}

# ============================================================================
# Issue-URL aus glab-Output extrahieren
# ============================================================================

extract_issue_url() {
  local output="$1"
  echo "$output" | grep -oE 'https?://[^ ]+/issues/[0-9]+' | head -1
}

extract_issue_number() {
  local output="$1"
  echo "$output" | grep -oE '/issues/([0-9]+)' | head -1 | grep -oE '[0-9]+'
}

# ============================================================================
# Priority-Mapping
# ============================================================================

priority_to_label() {
  local priority="$1"
  case "$priority" in
    P1|p1) echo "priority::1" ;;
    P2|p2) echo "priority::2" ;;
    P3|p3) echo "priority::3" ;;
    P4|p4) echo "priority::4" ;;
    *) echo "" ;;
  esac
}

# ============================================================================
# Milestone-Management
# ============================================================================

get_feature_name() {
  local feature_dir="$1"
  # Feature-Name = Name des Feature-Verzeichnisses
  basename "$feature_dir"
}

glab_find_milestone() {
  # Sucht einen Milestone nach Titel, gibt die Milestone-ID zurück
  local title="$1"
  glab_cmd api "projects/:id/milestones?title=$(printf '%s' "$title" | jq -sRr @uri)" 2>/dev/null \
    | jq -r ".[0].id // empty" 2>/dev/null || true
}

glab_create_milestone() {
  # Erstellt einen neuen Milestone und gibt die ID zurück
  local title="$1"
  local description="${2:-Automatisch erstellt von spec-kit für Feature: $title}"
  glab_cmd api "projects/:id/milestones" -f "title=$title" -f "description=$description" 2>/dev/null \
    | jq -r ".id" 2>/dev/null
}

glab_ensure_milestone() {
  # Findet oder erstellt einen Milestone, gibt den Titel zurück (für --milestone Flag)
  local feature_name="$1"

  local milestone_id
  milestone_id="$(glab_find_milestone "$feature_name")"

  if [[ -z "$milestone_id" ]]; then
    milestone_id="$(glab_create_milestone "$feature_name")"
    if [[ -n "$milestone_id" ]]; then
      echo "Milestone '$feature_name' erstellt (ID: $milestone_id)" >&2
    else
      echo "WARN: Milestone '$feature_name' konnte nicht erstellt werden" >&2
      return 1
    fi
  fi

  # glab issue create --milestone erwartet den Titel
  echo "$feature_name"
}
