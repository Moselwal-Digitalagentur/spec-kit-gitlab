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
  feature_label: "feature"

mapping:
  priority_to_label: true          # P1/P2/P3 → priority::1/2/3
  feature_to_milestone: true       # Feature-Name als GitLab Milestone
  feature_to_issue: true           # Feature als GitLab Issue erstellen
  link_tasks_to_stories: true      # Tasks mit Story-Issues verlinken
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

### `/speckit.gitlab.feature-to-issue`

Erstellt ein GitLab Issue für das aktuelle Feature und verlinkt bestehende Story-Issues damit. Verwendet den Feature-Verzeichnisnamen als Titel und den Kontext aus `spec.md` als Beschreibung. Labels: `spec-kit`, `feature`.

### `/speckit.gitlab.import-feature`

Importiert ein bestehendes GitLab Issue als Feature. Argument: Issue-Nummer (z.B. `232` oder `#232`). Schreibt das Mapping, erstellt optional eine `spec.md` aus der Issue-Beschreibung und verlinkt bestehende Stories.

### `/speckit.gitlab.stories-to-issues`

Erstellt GitLab Issues für alle User Stories aus `spec.md`. Erwartet das Format `### US1: Titel [P1]` und vergibt automatisch Labels (`spec-kit`, `user-story`, `priority::X`). Verlinkt neue Stories automatisch mit dem Feature-Issue (falls vorhanden).

### `/speckit.gitlab.tasks-to-issues`

Erstellt GitLab Issues (Type: Task) für alle Tasks aus `tasks.md`. Erwartet das Format `- [ ] T001 [P1] [US1] Beschreibung`. Verlinkt Tasks automatisch mit ihren Story-Issues.

### `/speckit.gitlab.sync`

Synchronisiert GitLab Issue-Status in die lokalen `tasks.md` Dateien. Aktualisiert Checkboxen basierend auf dem Issue-Status (open/closed). Zeigt Feature-Issue Status an (falls vorhanden). Optional: Importiert neue GitLab Issues mit `--import`.

### `/speckit.gitlab.status`

Zeigt eine Übersicht aller GitLab Issues mit aktuellem Status (Task-ID, Issue-Nummer, Status, Assignee) und aktualisiert `tasks.md`. Zeigt Feature-Issue Status am Anfang der Übersicht an. Enthält Fortschrittsstatistik (offen, geschlossen, Prozent).

## Workflow

### Push-Workflow (Lokal → GitLab)

```
1. /speckit.gitlab.init              → GitLab-Verbindung einrichten
2. /speckit.spec                     → spec.md erstellen
3. /speckit.gitlab.feature-to-issue  → Feature als GitLab Issue erstellen
4. /speckit.tasks                    → tasks.md generieren
5. /speckit.gitlab.stories-to-issues → Stories als GitLab Issues (verlinkt mit Feature)
6. /speckit.gitlab.tasks-to-issues   → Tasks als GitLab Issues (verlinkt mit Stories)
7. /speckit.gitlab.status            → Status synchronisieren
```

### Pull-Workflow (GitLab → Lokal)

```
1. /speckit.gitlab.import-feature 232  → Bestehendes Issue als Feature importieren
2. /speckit.spec                       → Spezifikation erstellen/verfeinern
3. /speckit.tasks                      → Tasks generieren
4. /speckit.gitlab.stories-to-issues   → Stories als GitLab Issues
5. /speckit.gitlab.tasks-to-issues     → Tasks als GitLab Issues
```

## Mapping-Datei

Die Extension pflegt eine `.gitlab-mapping.yml` im Feature-Verzeichnis, um Idempotenz sicherzustellen:

```yaml
feature: "#232 https://gitlab.example.com/group/project/-/issues/232"
stories:
  US1: "#10 https://gitlab.example.com/group/project/-/issues/10"
tasks:
  T001: "#42 https://gitlab.example.com/group/project/-/issues/42"
```

Das `feature:`-Feld wird von `/speckit.gitlab.feature-to-issue` (Push) oder `/speckit.gitlab.import-feature` (Pull) gesetzt. Stories werden automatisch mit dem Feature-Issue verlinkt.

Dadurch können Commands mehrfach ausgeführt werden, ohne Duplikate zu erzeugen.

## Hook

Nach `/speckit.tasks` wird automatisch gefragt, ob Tasks als GitLab Issues erstellt werden sollen.

## Lizenz

MIT — Moselwal Digitalagentur GmbH
