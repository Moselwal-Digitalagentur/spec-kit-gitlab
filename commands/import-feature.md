---
description: "Bestehendes GitLab Issue als Feature importieren"
scripts:
  check-prerequisites.sh: "../../scripts/check-prerequisites.sh"
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# GitLab Issue als Feature importieren

Nimmt ein bestehendes GitLab Issue und adoptiert es als Feature in spec-kit.

## Prerequisites

- `glab` CLI ist installiert und authentifiziert (`GITLAB_TOKEN` gesetzt)
- GitLab-Konfiguration existiert (`.specify/extensions/gitlab/gitlab-config.yml`)

## User Input

$ARGUMENTS

Das Argument ist die **Issue-Nummer** des zu importierenden GitLab Issues (z.B. `232` oder `#232`).

## Steps

### Step 1: Issue-Nummer ermitteln

Extrahiere die Issue-Nummer aus dem Argument. Akzeptiere Formate wie `232`, `#232` oder eine volle GitLab-URL.

Falls kein Argument übergeben wurde, frage den Benutzer nach der Issue-Nummer.

### Step 2: Konfiguration laden

Lade die GitLab-Konfiguration aus `.specify/extensions/gitlab/gitlab-config.yml`. Nutze die Helper-Funktionen aus `{SCRIPT:gitlab-helpers.sh}`.

### Step 3: Issue von GitLab abrufen

Rufe die Issue-Details ab:

```bash
glab_view_issue "$ISSUE_NUMBER"
```

Extrahiere:
- **Titel**: z.B. `user-authentication`
- **Beschreibung**: Issue-Body
- **Status**: `opened` oder `closed`
- **Labels**: Aktuelle Labels
- **URL**: Web-URL des Issues

Falls das Issue nicht gefunden wird, informiere den Benutzer und brich ab.

### Step 4: Feature-Verzeichnis ermitteln

Nutze `{SCRIPT:check-prerequisites.sh}` um das aktuelle Feature-Verzeichnis zu ermitteln.

Falls kein Feature-Verzeichnis gefunden wird:
- Leite den Verzeichnisnamen aus dem Issue-Titel ab (lowercase, Leerzeichen durch Bindestriche ersetzen)
- Informiere den Benutzer über den vorgeschlagenen Pfad
- Frage ob das Verzeichnis erstellt werden soll

### Step 5: Idempotenz prüfen

Lies die Mapping-Datei `FEATURE_DIR/.gitlab-mapping.yml` (falls vorhanden). Prüfe den `feature:`-Eintrag.

Falls bereits ein anderes Feature-Issue gemappt ist, warne den Benutzer:
> Feature-Verzeichnis ist bereits mit Issue #XYZ verknüpft.
> Soll das Mapping auf #232 aktualisiert werden?

### Step 6: Mapping schreiben

Initialisiere die Mapping-Datei (falls nötig) und schreibe das Feature-Mapping:

```bash
MAPPING_PATH="$(init_mapping_file "$FEATURE_DIR")"
write_feature_mapping "$MAPPING_PATH" "$ISSUE_NUMBER" "$ISSUE_URL"
```

### Step 7: Optional — spec.md Seed

Falls noch keine `spec.md` im Feature-Verzeichnis existiert und das Issue eine Beschreibung hat:

1. Erstelle eine initiale `spec.md` mit der Issue-Beschreibung als Ausgangspunkt:
   ```markdown
   # Feature-Titel

   <!-- Importiert von GitLab Issue #232 -->

   <Issue-Beschreibung>

   ## User Stories

   <!-- Erstelle User Stories mit /speckit.spec -->
   ```

2. Informiere den Benutzer:
   > `spec.md` wurde mit der Issue-Beschreibung als Seed erstellt.
   > Verfeinere die Spezifikation mit `/speckit.spec`.

Falls `spec.md` bereits existiert, überspringe diesen Schritt.

### Step 8: Bestehende Stories verlinken

Falls Story-Issues in der Mapping-Datei vorhanden sind (`stories:` Section), verlinke sie mit dem Feature-Issue:

```bash
glab_add_relation "$STORY_ISSUE_NUMBER" "$FEATURE_ISSUE_NUMBER"
```

### Step 9: Zusammenfassung und nächste Schritte

Zeige eine Übersicht:
- Importiertes Issue: `#232 - user-authentication`
- Status: `Open`
- Feature-Verzeichnis: `<pfad>`
- Mapping geschrieben: ja
- spec.md Seed: erstellt / übersprungen (bereits vorhanden)
- Verlinkte Stories: Anzahl

Nächste Schritte:
```
1. /speckit.spec                      → Spezifikation erstellen/verfeinern
2. /speckit.tasks                     → Tasks generieren
3. /speckit.gitlab.stories-to-issues  → Stories als GitLab Issues
4. /speckit.gitlab.tasks-to-issues    → Tasks als GitLab Issues
```
