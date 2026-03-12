---
description: "Erledigte Tasks/Stories in GitLab schließen, wieder geöffnete reopenen"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# Erledigte Issues in GitLab schließen

Synchronisiert den lokalen Erledigungsstatus (Checkboxen in `tasks.md`) nach GitLab: Erledigte Tasks/Stories werden geschlossen, wieder geöffnete werden reopened.

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

### Step 3: Mapping-Datei und tasks.md laden

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml`. Falls keine Mapping-Datei existiert:
- Informiere den Benutzer, dass zuerst `/speckit.gitlab.tasks-to-issues` ausgeführt werden muss
- Brich ab

Lies `tasks.md` im Feature-Verzeichnis und extrahiere für jeden Task:
- **Task-ID**: z.B. `T001`
- **Status**: `[x]` = erledigt, `[ ]` = offen

### Step 4: Aktuellen GitLab-Status abfragen

Für jede Issue-Nummer aus der Mapping-Datei (sowohl `tasks:` als auch `stories:` Section), rufe den aktuellen Status ab:

```bash
glab_view_issue "$ISSUE_NUMBER"
```

Extrahiere den `state` (`opened` oder `closed`).

### Step 5: Tasks abgleichen und Issues schließen/reopenen

Für jeden Task in der Mapping-Datei:

1. **Lokal erledigt (`[x]`) + GitLab offen (`opened`)** → Issue schließen:
   ```bash
   glab_close_issue "$ISSUE_NUMBER"
   ```

2. **Lokal offen (`[ ]`) + GitLab geschlossen (`closed`)** → Issue reopenen:
   ```bash
   glab_reopen_issue "$ISSUE_NUMBER"
   ```

3. **Status stimmt überein** → Überspringen

### Step 6: Stories abgleichen

Stories haben keine Checkboxen in `spec.md`. Stattdessen gilt eine Story als erledigt, wenn **alle zugehörigen Tasks** erledigt sind.

Für jede Story in der Mapping-Datei:

1. Ermittle alle Tasks die zu dieser Story gehören (Tasks mit `[USx]` Referenz in `tasks.md`)
2. Falls **alle** zugehörigen Tasks `[x]` haben und das Story-Issue offen ist → Issue schließen
3. Falls **nicht alle** Tasks erledigt sind und das Story-Issue geschlossen ist → Issue reopenen
4. Falls die Story keine Tasks hat → Überspringen

### Step 7: Feature-Issue abgleichen (optional)

Falls ein Feature-Issue in der Mapping-Datei vorhanden ist (`feature:` Eintrag):

1. Prüfe ob **alle** Story-Issues geschlossen sind
2. Falls ja und das Feature-Issue offen ist → Frage den Benutzer:
   > Alle Stories sind erledigt. Soll das Feature-Issue #232 geschlossen werden?
3. Falls nicht alle Stories erledigt sind und das Feature-Issue geschlossen ist → Informiere den Benutzer:
   > Feature-Issue #232 ist geschlossen, aber es gibt noch offene Stories. Soll es wieder geöffnet werden?

### Step 8: Zusammenfassung

Zeige eine Übersicht:

```
Issues geschlossen/geöffnet für Feature: <feature-name>
========================================================

Geschlossen:
  T001 → #42 (closed)
  T003 → #44 (closed)
  US1  → #10 (closed, alle Tasks erledigt)

Wieder geöffnet:
  T002 → #43 (reopened)

Unverändert:
  T004 → #45 (bereits geschlossen)
  T005 → #46 (bereits offen)

Zusammenfassung:
  Geschlossen: 3
  Wieder geöffnet: 1
  Unverändert: 2
```
