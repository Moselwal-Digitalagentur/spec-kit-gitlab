---
description: "GitLab Issues in spec-kit Dateien importieren und synchronisieren"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# GitLab Issues synchronisieren

Synchronisiere GitLab Issues mit den lokalen spec-kit Dateien (`tasks.md`).

## Prerequisites

- `glab` CLI ist installiert und authentifiziert (`GITLAB_TOKEN` gesetzt)
- GitLab-Konfiguration existiert (`.specify/extensions/gitlab/gitlab-config.yml`)
- Feature-Verzeichnis mit `tasks.md` ist vorhanden

## User Input

$ARGUMENTS

## Steps

### Step 1: Feature-Verzeichnis ermitteln

Nutze `{SCRIPT:check-prerequisites.sh}` um das aktuelle Feature-Verzeichnis zu ermitteln.

Falls kein Feature-Verzeichnis gefunden wird, informiere den Benutzer und brich ab.

### Step 2: Konfiguration laden

Lade die GitLab-Konfiguration aus `.specify/extensions/gitlab/gitlab-config.yml`. Nutze die Helper-Funktionen aus `{SCRIPT:gitlab-helpers.sh}`.

### Step 3: Offene und geschlossene Issues von GitLab holen

Lade alle Issues mit dem `spec-kit` Label aus dem konfigurierten GitLab-Projekt:

```bash
# Alle Issues mit spec-kit Label (offen und geschlossen)
glab issue list --repo "$GITLAB_PROJECT" --label "spec-kit" --state all --output json
```

Parse die JSON-Ausgabe und extrahiere für jedes Issue:
- **Issue-Nummer**: z.B. `#42`
- **Titel**: z.B. "T001: Task-Beschreibung"
- **Status**: `opened` oder `closed`
- **Labels**: Alle Labels des Issues
- **URL**: Web-URL des Issues

### Step 4: Mapping-Datei laden

Lies die bestehende Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml` (falls vorhanden).

### Step 5: tasks.md aktualisieren

Für jedes Issue, das in der Mapping-Datei oder in `tasks.md` (via `<!-- gitlab:#123 -->` Kommentar) referenziert wird:

1. **Geschlossene Issues**: Setze die Checkbox auf `[x]`
   ```
   - [x] T001 [P1] [US1] Task-Beschreibung <!-- gitlab:#42 -->
   ```

2. **Offene Issues**: Setze die Checkbox auf `[ ]`
   ```
   - [ ] T002 [P2] [US1] Andere Task-Beschreibung <!-- gitlab:#43 -->
   ```

### Step 6: Neue Issues importieren (optional)

Falls der Benutzer `--import` als Argument übergeben hat oder bestätigt:

Für jedes GitLab Issue mit `spec-kit` Label, das noch NICHT in `tasks.md` steht:

1. Ermittle die Task-ID aus dem Issue-Titel (z.B. "T001" aus "T001: Beschreibung")
2. Falls keine Task-ID im Titel: Generiere die nächste freie Task-ID
3. Ermittle Priority aus Labels (z.B. `priority::1` → `P1`)
4. Ermittle Story-Referenz aus Labels (z.B. `story::US1` → `US1`)
5. Füge den Task am Ende von `tasks.md` hinzu:
   ```
   - [ ] T099 [P2] [US3] Importierte Task-Beschreibung <!-- gitlab:#99 -->
   ```

### Step 7: Mapping-Datei aktualisieren

Aktualisiere die Mapping-Datei mit allen neuen Zuordnungen.

### Step 8: Zusammenfassung

Zeige eine Übersicht:
- Anzahl aktualisierte Tasks (Status geändert)
- Anzahl neu importierte Tasks (falls --import)
- Anzahl unveränderte Tasks
- Eventuelle Konflikte oder Warnungen
