# spec-kit GitLab Extension

GitLab-Integration für [spec-kit](https://github.com/specify-cli/specify-cli): Issues erstellen, synchronisieren und Status-Updates via `glab` CLI.

Unterstützt self-hosted GitLab-Instanzen.

## Installation

```bash
# Voraussetzung: glab CLI installiert und authentifiziert
# https://gitlab.com/gitlab-org/cli
brew install glab
glab auth login --hostname gitlab.example.com

# Extension installieren (Development-Modus)
cd /path/to/your/spec-kit-project
specify extension add --dev ~/spec-kit-gitlab/
```

## Konfiguration

Nach der Installation die Konfigurationsdatei anpassen:

```bash
# Datei: .specify/extensions/gitlab/gitlab-config.yml
```

```yaml
gitlab:
  url: "https://gitlab.example.com"
  project: "group/project"

labels:
  story_label: "user-story"
  task_label: "task"
  speckit_label: "spec-kit"

mapping:
  priority_to_label: true
  phase_to_milestone: false
  link_tasks_to_stories: true
```

Alternativ via Umgebungsvariablen:

```bash
export GITLAB_URL="https://gitlab.example.com"
export GITLAB_PROJECT="group/project"
export GITLAB_TOKEN="glpat-xxxxxxxxxxxx"
```

## Commands

### `/speckit.gitlab.stories-to-issues`

Erstellt GitLab Issues für alle User Stories aus `spec.md`.

### `/speckit.gitlab.tasks-to-issues`

Erstellt GitLab Issues (Type: Task) für alle Tasks aus `tasks.md`. Verlinkt Tasks automatisch mit ihren Story-Issues.

### `/speckit.gitlab.sync`

Synchronisiert GitLab Issue-Status in die lokalen `tasks.md` Dateien. Optional: Importiert neue GitLab Issues mit `--import`.

### `/speckit.gitlab.status`

Zeigt eine Übersicht aller GitLab Issues mit aktuellem Status und aktualisiert `tasks.md`.

## Workflow

```
1. /speckit.spec          → spec.md erstellen
2. /speckit.tasks         → tasks.md erstellen
3. /speckit.gitlab.stories-to-issues → Stories als GitLab Issues
4. /speckit.gitlab.tasks-to-issues   → Tasks als GitLab Issues (verlinkt mit Stories)
5. /speckit.gitlab.status            → Status synchronisieren
```

## Hook

Nach `/speckit.tasks` wird automatisch gefragt, ob Tasks als GitLab Issues erstellt werden sollen.
