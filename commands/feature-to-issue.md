---
description: "Feature als GitLab Issue erstellen und Stories verlinken"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# Feature als GitLab Issue erstellen

Erstellt ein GitLab Issue für das aktuelle Feature und verlinkt bestehende Story-Issues damit.

## Prerequisites

- `glab` CLI ist installiert und authentifiziert (`GITLAB_TOKEN` gesetzt)
- GitLab-Konfiguration existiert (`.specify/extensions/gitlab/gitlab-config.yml`)
- Feature-Verzeichnis mit `spec.md` ist vorhanden

## User Input

$ARGUMENTS

## Steps

### Step 1: Feature-Verzeichnis ermitteln

Nutze `{SCRIPT:check-prerequisites.sh}` um das aktuelle Feature-Verzeichnis zu ermitteln. Das Feature-Verzeichnis enthält `spec.md`.

Falls kein Feature-Verzeichnis gefunden wird, informiere den Benutzer und brich ab.

### Step 2: Konfiguration laden

Lade die GitLab-Konfiguration aus `.specify/extensions/gitlab/gitlab-config.yml`. Nutze die Helper-Funktionen aus `{SCRIPT:gitlab-helpers.sh}`.

Folgende Werte werden benötigt:
- `GITLAB_URL` - URL des GitLab-Servers
- `GITLAB_PROJECT` - Projekt-Pfad
- `GITLAB_FEATURE_TO_ISSUE` - ob Feature als Issue erstellt wird
- `GITLAB_FEATURE_LABEL` - Label für Feature-Issues
- `GITLAB_FEATURE_TO_MILESTONE` - ob Feature als Milestone gemappt wird

Falls `GITLAB_FEATURE_TO_ISSUE` nicht `true` ist, informiere den Benutzer und brich ab:
> Feature-to-Issue ist in der Konfiguration deaktiviert (`feature_to_issue: false`).

### Step 3: Idempotenz prüfen

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml` (falls vorhanden). Prüfe den `feature:`-Eintrag mit `read_feature_mapping`.

Falls bereits ein Feature-Issue gemappt ist, zeige die bestehende Zuordnung und brich ab:
> Feature-Issue existiert bereits: #232 (https://...)
> Überspringe Erstellung.

### Step 4: Feature-Issue erstellen

1. **Feature-Name** ermitteln: Verzeichnisname des Feature-Verzeichnisses (z.B. `user-authentication`).

2. **Beschreibung** aus `spec.md` extrahieren: Lies den Inhalt vor `## User Stories` (Übersicht/Kontext des Features). Falls `## User Stories` nicht existiert, verwende den gesamten Inhalt von `spec.md`.

3. **Labels zusammenstellen:**
   - Immer: `spec-kit`, den konfigurierten `GITLAB_FEATURE_LABEL` (Default: `feature`)

4. **Milestone** ermitteln (falls `feature_to_milestone: true`):
   ```bash
   MILESTONE_TITLE="$(glab_ensure_milestone "$(get_feature_name "$FEATURE_DIR")")"
   ```

5. **Issue erstellen** via `glab_create_issue`:
   - Titel: Feature-Name (human-readable, z.B. `user-authentication`)
   - Beschreibung: Extrahierter Kontext aus `spec.md`
   - Labels: `spec-kit,feature`
   - Milestone: Falls gesetzt, `MILESTONE_TITLE`

6. **Issue-URL und Nummer** aus dem Output extrahieren.

### Step 5: Mapping schreiben

Schreibe das Feature-Mapping in `FEATURE_DIR/.gitlab-mapping.yml`:

```bash
write_feature_mapping "$MAPPING_PATH" "$ISSUE_NUMBER" "$ISSUE_URL"
```

Das ergibt z.B.:
```yaml
feature: "#232 https://gitlab.example.com/group/project/-/issues/232"
stories:
  US1: "#10 https://..."
tasks: {}
```

### Step 6: Bestehende Stories verlinken

Lies alle Einträge aus `stories:` in der Mapping-Datei. Für jeden Story-Eintrag:

1. Extrahiere die Story-Issue-Nummer
2. Verlinke das Story-Issue mit dem Feature-Issue:
   ```bash
   glab_add_relation "$STORY_ISSUE_NUMBER" "$FEATURE_ISSUE_NUMBER"
   ```

Falls keine Stories vorhanden sind, überspringe diesen Schritt mit einem Hinweis:
> Keine bestehenden Story-Issues zum Verlinken gefunden.

### Step 7: Zusammenfassung

Zeige eine Übersicht:
- Feature-Issue erstellt: `#232 - user-authentication`
- URL: `https://gitlab.example.com/.../issues/232`
- Milestone: Falls gesetzt
- Verlinkte Stories: Anzahl und Liste
- Hinweis: "Führe `/speckit.gitlab.stories-to-issues` aus, um neue Stories zu erstellen — diese werden automatisch verlinkt."
