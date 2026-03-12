---
description: "GitLab-Konfiguration interaktiv einrichten"
scripts:
  gitlab-helpers.sh: "../scripts/bash/gitlab-helpers.sh"
---

# GitLab-Konfiguration einrichten

Richte die GitLab-Integration interaktiv ein, indem alle nötigen Konfigurationswerte abgefragt und in die Config-Datei geschrieben werden.

## Prerequisites

- `glab` CLI ist installiert
- spec-kit GitLab Extension ist installiert (`specify extension add --dev ~/spec-kit-gitlab/`)

## User Input

$ARGUMENTS

## Steps

### Step 1: Prüfen ob glab CLI verfügbar ist

Prüfe ob `glab` installiert ist:

```bash
command -v glab
```

Falls nicht vorhanden, informiere den Benutzer:
- macOS: `brew install glab`
- Linux: siehe https://gitlab.com/gitlab-org/cli

### Step 2: Bestehende Konfiguration prüfen

Prüfe ob bereits eine Konfigurationsdatei existiert unter `.specify/extensions/gitlab/gitlab-config.yml`.

Falls ja, lies die bestehenden Werte aus und zeige sie dem Benutzer an. Frage ob er sie aktualisieren oder beibehalten möchte.

### Step 3: GitLab-URL abfragen

Frage den Benutzer nach der GitLab-Server URL:

> **GitLab-Server URL?**
> z.B. `https://gitlab.example.com` oder `https://gitlab.moselwal.io`

Validierung:
- Muss mit `https://` oder `http://` beginnen
- Kein trailing Slash

Falls die Umgebungsvariable `GITLAB_URL` gesetzt ist, schlage diesen Wert als Default vor.

### Step 4: GitLab-Projekt abfragen

Frage den Benutzer nach dem Projekt-Pfad:

> **GitLab Projekt-Pfad?**
> z.B. `group/project` oder `group/subgroup/project`

Falls `glab` bereits authentifiziert ist, versuche die verfügbaren Projekte zu listen als Hilfe:

```bash
glab repo list --output json 2>/dev/null | head -20
```

Falls die Umgebungsvariable `GITLAB_PROJECT` gesetzt ist, schlage diesen Wert als Default vor.

### Step 5: glab-Authentifizierung prüfen

Prüfe ob `glab` für den angegebenen GitLab-Server authentifiziert ist:

```bash
glab auth status --hostname <gitlab-host>
```

Falls nicht authentifiziert, informiere den Benutzer:

> `glab` ist nicht für `<gitlab-host>` authentifiziert.
> Bitte führe aus: `glab auth login --hostname <gitlab-host>`
> Oder setze die Umgebungsvariable: `export GITLAB_TOKEN="glpat-..."`

Frage ob trotzdem fortgefahren werden soll (Config kann auch ohne Auth geschrieben werden).

### Step 6: Label-Konfiguration abfragen

Frage den Benutzer nach den Labels (mit Defaults):

> **Label für User Stories?** (Default: `user-story`)
> **Label für Tasks?** (Default: `task`)
> **Label für spec-kit Tracking?** (Default: `spec-kit`)
> **Label für Feature-Issues?** (Default: `feature`)

Die meisten Benutzer werden die Defaults akzeptieren.

### Step 7: Mapping-Optionen abfragen

Frage nach den Mapping-Optionen (mit Defaults):

> **Priority als Label mappen?** (z.B. P1 → `priority::1`) (Default: ja)
> **Tasks mit Story-Issues verlinken?** (Default: ja)
> **Feature als Milestone anlegen?** (Der Feature-Name wird als GitLab Milestone verwendet) (Default: ja)
> **Feature als GitLab Issue erstellen?** (Erstellt ein übergeordnetes Issue pro Feature) (Default: ja)

### Step 8: Konfigurationsdatei schreiben

Erstelle die Konfigurationsdatei unter `.specify/extensions/gitlab/gitlab-config.yml`:

```yaml
gitlab:
  url: "<eingegebene URL>"
  project: "<eingegebener Projekt-Pfad>"

labels:
  story_label: "<eingegebenes Label>"
  task_label: "<eingegebenes Label>"
  speckit_label: "<eingegebenes Label>"
  feature_label: "<eingegebenes Label>"

mapping:
  priority_to_label: <true/false>
  feature_to_milestone: <true/false>
  feature_to_issue: <true/false>
  link_tasks_to_stories: <true/false>
```

Stelle sicher, dass das Verzeichnis `.specify/extensions/gitlab/` existiert.

### Step 9: Verbindung testen

Falls `glab` authentifiziert ist, teste die Verbindung:

```bash
glab api projects/:id --repo "<project-path>" 2>/dev/null
```

Zeige bei Erfolg:
> Verbindung zu `<gitlab-url>` erfolgreich. Projekt `<project>` gefunden.

Bei Fehler:
> Verbindung fehlgeschlagen. Bitte prüfe URL, Projekt-Pfad und Authentifizierung.

### Step 10: Zusammenfassung und nächste Schritte

Zeige eine Zusammenfassung der geschriebenen Konfiguration und die nächsten Schritte:

```
GitLab-Konfiguration gespeichert.

  Server:  <url>
  Projekt: <project>
  Labels:  <speckit-label>, <story-label>, <task-label>

Nächste Schritte:
  1. /speckit.spec                      → Spezifikation erstellen
  2. /speckit.tasks                     → Tasks generieren
  3. /speckit.gitlab.stories-to-issues  → Stories als GitLab Issues
  4. /speckit.gitlab.tasks-to-issues    → Tasks als GitLab Issues

Tipp: Die Config kann jederzeit mit /speckit.gitlab.init aktualisiert werden.
      Lokale Overrides: .specify/extensions/gitlab/gitlab-config.local.yml
```
