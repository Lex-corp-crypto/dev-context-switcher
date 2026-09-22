# Dev Context Switcher 🚀

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)](https://flutter.dev/desktop)

> 🇫🇷 **[Cliquez ici pour lire la version française](#-version-française)**

A modern, cross-platform developer workspace manager built with Flutter and Riverpod. Capture, switch, and instantly restore your complete development environment—including application windows, terminal sessions with working directories, background processes, Git branches, Docker containers, and browser tabs.

---

## ⚡ Key Features

- **📸 Intelligent & Selective System Capture**:
  - Live inspection of active desktop windows (titles, geometry, X/Y/Width/Height bounds).
  - Dev process detection with filtering (Node, Python, Dart/Flutter, VS Code, Rust, Go, Docker, Java) including live CPU & RAM usage.
  - Active terminal sessions detection with working directory (`/proc/$pid/cwd` resolution).
  - Docker containers inspection (running containers, images, exposed ports, status).
  - Git repository state capture (active branch, short commit hash, uncommitted changes indicator).
  - Browser reference URLs and dev localhost tabs.
- **🚀 1-Click Instant Restoration**:
  - Automatically re-opens terminals in their respective working directories.
  - Checks out the exact Git branch.
  - Starts stopped Docker containers.
  - Launches development processes and IDEs.
  - Opens reference URLs in the default browser.
  - Detailed restoration log report with success/failure breakdowns.
- **🎯 Intelligent Project Auto-Detection**:
  - Continuously analyzes active project directories (Flutter, React, Next.js, Node, Python, Rust, Go, Java, Git).
  - Prominently displays a top banner with a 1-click *"Capture this project context"* button.
- **⌨️ Keyboard Shortcuts & Quick Switcher**:
  - Quick access bar with shortcuts `Ctrl+1` through `Ctrl+9` for instantaneous workspace switching.
  - `Ctrl+K` command palette for fast workspace searching.
  - `Ctrl+N` for instant capture, `Ctrl+F` for filtering.
- **📦 Pre-Built Workspace Templates**:
  - *Flutter Desktop & Web* (VS Code, test/run terminals, pub.dev reference).
  - *Full-Stack Web* (React/Next.js frontend, Node backend, localhost tabs).
  - *Python AI & Data Science* (Jupyter notebook, FastAPI server, venv).
  - *DevOps & Microservices* (Docker Compose, PostgreSQL, Redis, Adminer).
- **🛠️ Integrated System Diagnostics**:
  - Live health check for Git, Docker daemon, VS Code CLI (`code`), terminal emulators (`cosmic-term`, `konsole`, `x-terminal-emulator`, `xterm`), and display server (Wayland / X11).
- **💾 JSON Backup, Export & Sharing**:
  - Safe local JSON storage.
  - Export single or all workspaces for team sharing and migration.

---

## 🏗️ Architecture

Built with **Clean Architecture** principles and **Riverpod** state management:

```
lib/
├── app.dart                                # Root app, Material 3, Dark & Light theme setup
├── main.dart                               # Entrypoint with ProviderScope
├── routing/                                # Routes and declarative AppRouter
├── domain/                                 # Domain layer (Entities, Repository contracts)
│   ├── entities/                           # Workspace, WindowSnapshot, ProcessSnapshot, GitSnapshot...
│   └── repositories/                       # Abstract repository contracts
├── data/                                   # Data layer
│   ├── models/                             # JSON-serializable models
│   └── repositories/                       # File-based implementations with ~/.config persistence
├── services/                               # Application services
│   ├── workspace_capture_service.dart     # System inspector and snapshot builder
│   ├── workspace_restoration_service.dart # Modular restoration engine with detailed report
│   └── project_detector_service.dart       # Multi-language project detector
├── platform/                               # OS-specific adapters
│   ├── contracts/                          # WindowManager, TerminalManager, DockerManager contracts
│   ├── linux/                              # Linux implementations (xdotool, wmctrl, /proc, shells)
│   ├── macos/                              # macOS implementations (AppleScript, open)
│   ├── windows/                            # Windows implementations (User32 FFI, start)
│   └── shared/                             # Cross-platform controllers (Git, VS Code, Browser)
└── presentation/                           # UI layer
    ├── providers/                          # Riverpod notifiers (workspaces, settings, active project)
    └── pages/
        ├── home/                           # Dashboard, quick restore bar, search, tags, cards
        ├── capture/                        # Capture studio with real-time inspector and pickers
        ├── workspace_detail/               # Workspace inspection, selective restore, visualizer
        ├── templates/                      # Ready-to-use developer presets
        └── settings/                       # Theme mode, diagnostics, backup import/export
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Recommended tools on host: `git`, `docker`, `code` (VS Code)

### Run on Linux Desktop
```bash
flutter pub get
flutter run -d linux
```

### Launch Script
For convenience, you can use the provided launch script:
```bash
./start.sh          # Gets dependencies and runs the app
./start.sh -d linux # Explicitly specify Linux
./start.sh --release # Run in release mode
```
The script (`start.sh`) automatically handles dependency fetching and launches the app with any additional Flutter arguments you provide.

### Run Tests
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```

---
---

# 🇫🇷 Version Française

> 🇬🇧 **[Click here to go back to English version](#dev-context-switcher-)**

Gestionnaire d'environnements de développement desktop moderne, multiplateforme et réactif, conçu avec Flutter et Riverpod. Il permet de capturer, basculer et restaurer en un instant l'intégralité de vos sessions de travail : fenêtres applicatives, terminaux positionnés dans leurs répertoires, processus d'arrière-plan, branches Git, conteneurs Docker et onglets de référence.

---

## ✨ Fonctionnalités Détaillées

- **📸 Capture Intelligente & Sélective (Capture Studio)** :
  - Détection en direct des fenêtres actives avec dimensions et coordonnées (X, Y, Largeur, Hauteur).
  - Filtrage automatique des processus développeurs pertinents (Node, Python, Dart, Flutter, VS Code, Rust, Go, Docker) avec consommation CPU et RAM.
  - Détection automatique des sessions de terminaux et de leurs répertoires de travail via `/proc/$pid/cwd`.
  - Détection des conteneurs Docker en cours d'exécution avec statut et mappage de ports.
  - Capture de l'état Git (branche active, hash de commit, présence de modifications non commitées).
  - Gestion des onglets web et URLs localhost de travail.
- **⚡ Restauration Instantanée & Modulaire** :
  - Relance automatique des terminaux dans les bons dossiers.
  - Checkout transparent de la branche Git du projet.
  - Démarrage automatique des conteneurs Docker requis.
  - Lancement des applications et fenêtres associées.
  - Ouverture des URLs dans le navigateur par défaut.
  - Rapport d'exécution en direct (`RestorationReport`) avec journal des opérations.
- **🎯 Détection Automatique de Projet** :
  - Détection instantanée de vos projets locaux (Flutter, React, Next.js, Node, Python, Rust, Go, Java, Git).
  - Bannière intelligente en haut du tableau de bord avec action directe *"Capturer ce contexte"*.
- **⌨️ Raccourcis Clavier & Accès Rapide** :
  - Raccourcis `Ctrl+1` à `Ctrl+9` pour commuter instantanément d'un workspace à l'autre.
  - Palette de commandes `Ctrl+K`.
  - `Ctrl+N` pour lancer un nouveau snapshot et `Ctrl+F` pour la recherche.
- **📦 Modèles Préconfigurés (Templates)** :
  - *Flutter Desktop & Web*
  - *Full-Stack Web (Node & React)*
  - *Python AI & Data Science (Jupyter & FastAPI)*
  - *DevOps & Docker Microservices (Postgres & Redis)*
- **🛠️ Diagnostics Système Intégrés** :
  - Vérification continue de Git, Docker, VS Code, émulateurs de terminaux (`cosmic-term`, `konsole`, `x-terminal-emulator`, `xterm`) et serveur d'affichage (Wayland / X11).
- **💾 Sauvegarde & Export JSON** :
  - Sauvegarde locale sécurisée dans `~/.config/dev_context_switcher/workspaces`.
  - Export individuel ou global pour partage d'équipe ou sauvegarde.

---

## 🛠️ Commandes Utiles

```bash
# Récupération des dépendances
flutter pub get

# Lancement de l'application en mode Desktop
flutter run -d linux

# Exécution de la suite de tests automatisés
flutter test

# Analyse statique du code (0 warnings, 0 errors)
flutter analyze
```

---

## 📄 Licence
Projet sous licence MIT.
