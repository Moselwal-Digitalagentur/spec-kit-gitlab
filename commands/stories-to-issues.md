---
description: "User Stories aus spec.md als GitLab Issues erstellen"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# User Stories als GitLab Issues erstellen

Erstelle für jede User Story in `spec.md` ein übergeordnetes GitLab Issue.

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
- Labels: `spec-kit`, `user-story`

### Step 3: spec.md lesen und User Stories extrahieren

Lies die Datei `spec.md` im Feature-Verzeichnis. Extrahiere alle User Stories. User Stories sind typischerweise in diesem Format:

```markdown
## User Stories

### US1: Story-Titel [P1]
Als <Rolle> möchte ich <Funktion>, damit <Nutzen>.

**Akzeptanzkriterien:**
- Kriterium 1
- Kriterium 2

### US2: Story-Titel [P2]
...
```

Extrahiere für jede Story:
- **Story-ID**: z.B. `US1`
- **Titel**: z.B. "Story-Titel"
- **Priority**: z.B. `P1`
- **Beschreibung**: Die User Story im "Als... möchte ich... damit..."-Format
- **Akzeptanzkriterien**: Liste der Kriterien

### Step 4: Idempotenz prüfen

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml` (falls vorhanden). Überspringe Stories, die dort bereits eine GitLab Issue-Nummer haben.

### Step 5: GitLab Issues erstellen

Für jede noch nicht erstellte Story:

1. **Labels zusammenstellen:**
   - Immer: `spec-kit`, `user-story`
   - Bei gesetzter Priority: `priority::1` (für P1), `priority::2` (für P2) etc.

2. **Issue-Beschreibung formatieren:**
   ```markdown
   **Story-ID:** US1
   **Priority:** P1

   ## User Story
   Als <Rolle> möchte ich <Funktion>, damit <Nutzen>.

   ## Akzeptanzkriterien
   - [ ] Kriterium 1
   - [ ] Kriterium 2
   ```

3. **Issue erstellen** via `glab`:
   ```bash
   glab issue create \
     --repo "$GITLAB_PROJECT" \
     --title "US1: Story-Titel" \
     --description "<formatierte Beschreibung>" \
     --label "spec-kit,user-story,priority::1" \
     --yes
   ```

4. **Issue-URL und Nummer** aus dem Output extrahieren.

### Step 6: Mapping-Datei aktualisieren

Schreibe/aktualisiere die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml`:

```yaml
stories:
  US1: "#10 https://gitlab.example.com/group/project/-/issues/10"
  US2: "#11 https://gitlab.example.com/group/project/-/issues/11"
tasks: {}
```

### Step 7: Zusammenfassung

Zeige eine Übersicht:
- Anzahl erstellte Story-Issues
- Anzahl übersprungene Stories (bereits vorhanden)
- Links zu den erstellten Issues
- Hinweis: "Führe `/speckit.gitlab.tasks-to-issues` aus, um Tasks mit diesen Stories zu verlinken."
