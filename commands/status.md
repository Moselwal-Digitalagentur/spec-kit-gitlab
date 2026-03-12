---
description: "Status von GitLab Issues in tasks.md updaten und Übersicht anzeigen"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# GitLab Issue-Status synchronisieren

Aktualisiere den Status der Tasks in `tasks.md` basierend auf dem aktuellen GitLab Issue-Status und zeige eine Übersicht.

## Prerequisites

- `glab` CLI ist installiert und authentifiziert (`GITLAB_TOKEN` gesetzt)
- GitLab-Konfiguration existiert (`.specify/extensions/gitlab/gitlab-config.yml`)
- Feature-Verzeichnis mit `tasks.md` und `.gitlab-mapping.yml` vorhanden

## User Input

$ARGUMENTS

## Steps

### Step 1: Feature-Verzeichnis ermitteln

Nutze `{SCRIPT:check-prerequisites.sh}` um das aktuelle Feature-Verzeichnis zu ermitteln.

Falls kein Feature-Verzeichnis gefunden wird, informiere den Benutzer und brich ab.

### Step 2: Konfiguration laden

Lade die GitLab-Konfiguration aus `.specify/extensions/gitlab/gitlab-config.yml`. Nutze die Helper-Funktionen aus `{SCRIPT:gitlab-helpers.sh}`.

### Step 3: Mapping-Datei laden

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml`. Diese enthält die Zuordnung von Task-IDs zu GitLab Issue-Nummern.

Falls keine Mapping-Datei existiert, prüfe `tasks.md` auf `<!-- gitlab:#123 -->` Kommentare und baue daraus eine temporäre Zuordnung.

Falls weder Mapping-Datei noch Kommentare vorhanden sind:
- Informiere den Benutzer, dass zuerst `/speckit.gitlab.tasks-to-issues` ausgeführt werden muss
- Brich ab

### Step 4: Status jedes Issues abfragen

Für jede Issue-Nummer aus der Mapping-Datei:

```bash
glab issue view <issue-nummer> --repo "$GITLAB_PROJECT" --output json
```

Extrahiere:
- **Status**: `opened` oder `closed`
- **Labels**: Aktuelle Labels
- **Assignee**: Zugewiesene Person (falls vorhanden)
- **Updated at**: Letztes Update-Datum

### Step 5: tasks.md aktualisieren

Für jeden Task mit zugeordnetem GitLab Issue:

1. **Geschlossenes Issue** → Setze `[x]` in tasks.md
2. **Offenes Issue** → Setze `[ ]` in tasks.md

Nur tatsächliche Änderungen vornehmen (keine unnötigen Schreibvorgänge).

### Step 6: Übersicht anzeigen

Zeige eine formatierte Tabelle:

```
GitLab Issue-Status für Feature: <feature-name>
================================================

| Task  | GitLab  | Status      | Assignee    |
|-------|---------|-------------|-------------|
| T001  | #42     | ✅ Closed   | @username   |
| T002  | #43     | 🔄 Open    | @other      |
| T003  | #44     | 🔄 Open    | -           |

Zusammenfassung:
  Offen:      2
  Geschlossen: 1
  Gesamt:      3
  Fortschritt: 33%

Stories:
| Story | GitLab  | Status      |
|-------|---------|-------------|
| US1   | #10     | 🔄 Open    |

Letzte Aktualisierung: <aktuelles Datum/Uhrzeit>
```

### Step 7: Bidirektionale Warnung

Falls es Diskrepanzen gibt (z.B. Task in tasks.md als `[x]` markiert, aber GitLab Issue ist noch offen):
- Zeige eine Warnung mit den betroffenen Tasks
- Frage den Benutzer, ob der GitLab-Status oder der lokale Status gelten soll
