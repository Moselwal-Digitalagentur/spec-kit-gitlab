# spec-kit GitLab Extension

GitLab-Integration für [spec-kit](https://github.com/specify-cli/specify-cli): Issues erstellen, synchronisieren und Status-Updates via `glab` CLI.

Unterstützt self-hosted GitLab-Instanzen.

## Voraussetzungen

- **spec-kit** >= 0.1.0
- **glab CLI** >= 1.0.0 ([GitLab CLI](https://gitlab.com/gitlab-org/cli))

## Installation

```bash
# glab CLI installieren und authentifizieren
brew install glab
glab auth login --hostname gitlab.example.com

# Extension installieren (Development-Modus)
cd /path/to/your/spec-kit-project
specify extension add --dev ~/spec-kit-gitlab/
```

## Konfiguration

Am einfachsten per interaktivem Setup:

```bash
/speckit.gitlab.init
```

Das erstellt die Konfigurationsdatei unter `.specify/extensions/gitlab/gitlab-config.yml`:

```yaml
gitlab:
  url: "https://gitlab.example.com"
  project: "group/project"

labels:
  story_label: "user-story"
  task_label: "task"
  speckit_label: "spec-kit"

mapping:
  priority_to_label: true        # P1/P2/P3 → priority::1/2/3
  phase_to_milestone: false      # Phase als Milestone abbilden
  link_tasks_to_stories: true    # Tasks mit Story-Issues verlinken
```

Alternativ via Umgebungsvariablen:

```bash
export GITLAB_URL="https://gitlab.example.com"
export GITLAB_PROJECT="group/project"
export GITLAB_TOKEN="glpat-xxxxxxxxxxxx"
```

## Commands

### `/speckit.gitlab.init`

Interaktive Einrichtung der GitLab-Konfiguration. Prüft `glab`-Installation, testet die Verbindung und schreibt die Konfigurationsdatei.

### `/speckit.gitlab.stories-to-issues`

Erstellt GitLab Issues für alle User Stories aus `spec.md`. Erwartet das Format `### US1: Titel [P1]` und vergibt automatisch Labels (`spec-kit`, `user-story`, `priority::X`).

### `/speckit.gitlab.tasks-to-issues`

Erstellt GitLab Issues (Type: Task) für alle Tasks aus `tasks.md`. Erwartet das Format `- [ ] T001 [P1] [US1] Beschreibung`. Verlinkt Tasks automatisch mit ihren Story-Issues.

### `/speckit.gitlab.sync`

Synchronisiert GitLab Issue-Status in die lokalen `tasks.md` Dateien. Aktualisiert Checkboxen basierend auf dem Issue-Status (open/closed). Optional: Importiert neue GitLab Issues mit `--import`.

### `/speckit.gitlab.status`

Zeigt eine Übersicht aller GitLab Issues mit aktuellem Status (Task-ID, Issue-Nummer, Status, Assignee) und aktualisiert `tasks.md`. Enthält Fortschrittsstatistik (offen, geschlossen, Prozent).

## Workflow

```
1. /speckit.gitlab.init              → GitLab-Verbindung einrichten
2. /speckit.spec                     → spec.md erstellen
3. /speckit.tasks                    → tasks.md generieren
4. /speckit.gitlab.stories-to-issues → Stories als GitLab Issues anlegen
5. /speckit.gitlab.tasks-to-issues   → Tasks als GitLab Issues (verlinkt mit Stories)
6. /speckit.gitlab.status            → Status synchronisieren
```

## Mapping-Datei

Die Extension pflegt eine `.gitlab-mapping.yml` im Feature-Verzeichnis, um Idempotenz sicherzustellen:

```yaml
stories:
  US1: "#10 https://gitlab.example.com/group/project/-/issues/10"
tasks:
  T001: "#42 https://gitlab.example.com/group/project/-/issues/42"
```

Dadurch können Commands mehrfach ausgeführt werden, ohne Duplikate zu erzeugen.

## Hook

Nach `/speckit.tasks` wird automatisch gefragt, ob Tasks als GitLab Issues erstellt werden sollen.

## Lizenz

MIT — Moselwal Digitalagentur GmbH
