---
description: "Tasks aus tasks.md als GitLab Issues (Type: Task) erstellen"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# Tasks als GitLab Issues erstellen

Erstelle für jeden Task in `tasks.md` ein GitLab Issue vom Typ "Task".

## Prerequisites

- `glab` CLI ist installiert und authentifiziert (`GITLAB_TOKEN` gesetzt)
- GitLab-Konfiguration existiert (`.specify/extensions/gitlab/gitlab-config.yml`)
- Feature-Verzeichnis mit `tasks.md` ist vorhanden

## User Input

$ARGUMENTS

## Steps

### Step 1: Feature-Verzeichnis ermitteln

Nutze `{SCRIPT:check-prerequisites.sh}` um das aktuelle Feature-Verzeichnis zu ermitteln. Das Feature-Verzeichnis enthält `tasks.md`.

Falls kein Feature-Verzeichnis gefunden wird, informiere den Benutzer und brich ab.

### Step 2: Konfiguration laden

Lade die GitLab-Konfiguration aus `.specify/extensions/gitlab/gitlab-config.yml`. Nutze die Helper-Funktionen aus `{SCRIPT:gitlab-helpers.sh}`.

Folgende Werte werden benötigt:
- `GITLAB_URL` - URL des GitLab-Servers
- `GITLAB_PROJECT` - Projekt-Pfad (z.B. "group/project")
- Labels: `spec-kit`, `task` und ggf. Priority-Labels
- `GITLAB_FEATURE_TO_MILESTONE` - ob Feature als Milestone gemappt wird

Falls `GITLAB_URL` oder `GITLAB_PROJECT` nicht gesetzt sind, prüfe auch die Umgebungsvariablen.

Falls `feature_to_milestone: true`, ermittle den Feature-Namen und stelle sicher, dass ein Milestone existiert:

```bash
MILESTONE_TITLE="$(glab_ensure_milestone "$(get_feature_name "$FEATURE_DIR")")"
```

### Step 3: tasks.md lesen und parsen

Lies die Datei `tasks.md` im Feature-Verzeichnis. Parse jeden Task im Format:

```
- [ ] T001 [P1] [US1] Task-Beschreibung
- [x] T002 [P2] [US1] Bereits erledigter Task
```

Extrahiere für jeden Task:
- **Task-ID**: z.B. `T001`
- **Priority**: z.B. `P1` (aus `[P1]`)
- **Story-Referenz**: z.B. `US1` (aus `[US1]`)
- **Beschreibung**: Der Rest der Zeile
- **Status**: `[ ]` = offen, `[x]` = erledigt

### Step 4: Idempotenz prüfen

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml` (falls vorhanden). Überspringe Tasks, die dort bereits eine GitLab Issue-Nummer haben.

Prüfe auch, ob in `tasks.md` bereits GitLab-URLs als Kommentare stehen (Format: `<!-- gitlab:#123 -->`). Diese Tasks ebenfalls überspringen.

### Step 5: GitLab Issues erstellen

Für jeden noch nicht erstellten Task:

1. **Labels zusammenstellen:**
   - Immer: `spec-kit`, `task`
   - Bei gesetzter Priority: `priority::1` (für P1), `priority::2` (für P2) etc.
   - Story-Label: `story::US1` (falls Story-Referenz vorhanden)

2. **Issue erstellen** via `glab`:
   ```bash
   glab issue create \
     --repo "$GITLAB_PROJECT" \
     --title "T001: Task-Beschreibung" \
     --description "**Task-ID:** T001\n**Priority:** P1\n**Story:** US1\n\nTask-Beschreibung" \
     --label "spec-kit,task,priority::1,story::US1" \
     --type "task" \
     --milestone "$MILESTONE_TITLE" \
     --yes
   ```

   Den `--milestone`-Parameter nur setzen, wenn `feature_to_milestone: true` und `MILESTONE_TITLE` gesetzt ist. Nutze `glab_create_issue` mit dem 5. Parameter für den Milestone.

3. **Issue-URL und Nummer** aus dem Output extrahieren.

4. **Mit Story-Issue verlinken** (falls `link_tasks_to_stories: true` und Story-Issue existiert):
   ```bash
   glab issue relation add <task-issue-nr> --related <story-issue-nr> --repo "$GITLAB_PROJECT"
   ```

### Step 6: Mapping und tasks.md aktualisieren

1. **Mapping-Datei** (`FEATURE_DIR/.gitlab-mapping.yml`) aktualisieren:
   ```yaml
   tasks:
     T001: "#42 https://gitlab.example.com/group/project/-/issues/42"
     T002: "#43 https://gitlab.example.com/group/project/-/issues/43"
   ```

2. **tasks.md** mit GitLab-Referenzen ergänzen (als HTML-Kommentar am Zeilenende):
   ```
   - [ ] T001 [P1] [US1] Task-Beschreibung <!-- gitlab:#42 -->
   ```

### Step 7: Zusammenfassung

Zeige eine Übersicht:
- Anzahl erstellte Issues
- Anzahl übersprungene Issues (bereits vorhanden)
- Links zu den erstellten Issues
- Eventuelle Fehler
