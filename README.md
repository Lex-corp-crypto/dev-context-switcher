# Dev Context Switcher 🚀 (Ultimate Edition)

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)](https://flutter.dev/desktop)

> 🇫🇷 **[Cliquez ici pour lire la version française](#-version-française)**

A modern, cross-platform developer workspace manager built with Flutter and Riverpod. Capture, switch, and instantly restore your complete development environment—including application windows, virtual screen topologies, terminal sessions with working directories, background processes, Git branches, Docker containers, browser tabs, interactive task checklists, scratchpad notes, and custom startup commands.

---

## ⚡ Key Features

- **📸 Intelligent & Selective System Capture**:
  - Live inspection of active desktop windows (titles, geometry, X/Y/Width/Height bounds).
  - Dev process detection with filtering (Node, Python, Dart/Flutter, VS Code, Rust, Go, Docker, Java, C++) including live CPU & RAM usage.
  - Active terminal sessions detection with working directory (`/proc/$pid/cwd` resolution).
  - Docker containers inspection (running containers, images, exposed ports, status).
  - Git repository state capture (active branch, short commit hash, uncommitted changes indicator).
  - Browser reference URLs and dev localhost tabs.
  - Custom color themes and initial tasks/notes during capture.
- **🖥️ 2D Virtual Desktop Window Layout Canvas**:
  - Proportional virtual monitor visualization scaling windows with pixel geometry badges, app icons, and interactive hover highlights.
- **✅ Interactive Objectives & Tasks Checklist**:
  - Integrated task checklist per workspace with real-time completion tracking and progress bar.
- **📝 Context Scratchpad & Notes**:
  - Persistent notes and reminders (documentation links, credentials, next steps) attached to each context.
- **⚡ Custom Startup Commands & Environment Variables**:
  - Configure pre/post launch commands (e.g., `npm run dev`, `docker compose up -d`, `cargo watch`) executed seamlessly upon context restoration.
- **🚀 1-Click Instant Restoration**:
  - Automatically re-opens terminals in their respective working directories.
  - Checks out the exact Git branch.
  - Starts stopped Docker containers.
  - Executes configured startup commands with environment variables.
  - Repositions windows and opens reference URLs.
  - Detailed restoration log report with execution time and statistics.
- **⭐ Favorites & Custom Sorting**:
  - Pin favorite workspaces to the top with 1-click star icons.
  - Filter by "Favorites" or tags.
  - Sort by "Favorites first", "Newest", "Last restored", or "Alphabetical".
- **🎯 Multi-Stack Project Auto-Detection**:
  - Analyzes local directories: Flutter, React, Next.js, Vue, Svelte, Astro, Node, Python, Rust, Go, Java, Kotlin, PHP, C++, Docker Compose, Git.
  - Top dashboard banner with 1-click *"Capture this project context"* button.
- **⌨️ Keyboard Shortcuts & Command Palette**:
  - Quick access bar with `Ctrl+1` through `Ctrl+9` for instantaneous workspace switching.
  - `Ctrl+K` command palette for fast workspace searching and action execution.
  - `Ctrl+N` for instant capture, `Ctrl+F` for filtering.
- **📦 Pre-Built Developer Templates**:
  - *Flutter Desktop & Web*
  - *Full-Stack Web (Node & React)*
  - *Rust Systems & High-Perf Backend*
  - *Python AI & Data Science*
  - *Next.js & Supabase Modern Fullstack*
  - *DevOps & Docker Microservices*
- **🛠️ Integrated System Diagnostics**:
  - Live health check for Git, Docker daemon, VS Code CLI (`code`), terminal emulators (`ptyxis`, `cosmic-term`, `konsole`, `alacritty`, `kitty`, `gnome-terminal`, `xterm`), window managers (`xdotool`, `wmctrl`), and display server (Wayland / X11).
- **💾 JSON Backup, Export & Sharing**:
  - Safe local JSON storage.
  - 1-click export to clipboard or JSON file.
  - 1-click JSON import modal with format validation.

---

## 🏗️ Architecture

Built with **Clean Architecture** principles and **Riverpod** state management:

```
lib/
├── app.dart                                # Root app, Material 3, Dark & Light theme setup
├── main.dart                               # Entrypoint with ProviderScope
├── routing/                                # Routes and declarative AppRouter
├── domain/                                 # Domain layer (Entities, Repository contracts)
│   ├── entities/                           # Workspace, WorkspaceTask, WindowSnapshot, GitSnapshot...
│   └── repositories/                       # Abstract repository contracts
├── data/                                   # Data layer
│   ├── models/                             # JSON-serializable models
│   └── repositories/                       # File-based implementations with ~/.config persistence
├── services/                               # Application services
│   ├── workspace_capture_service.dart     # System inspector and snapshot builder
│   ├── workspace_restoration_service.dart # Modular restoration engine with startup commands & report
│   └── project_detector_service.dart       # Multi-language project detector (Rust, Go, Python, Node...)
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
        ├── workspace_detail/               # Workspace inspection, selective restore, 2D visualizer, tasks
        ├── templates/                      # Ready-to-use developer presets
        └── settings/                       # Theme mode, diagnostics, backup import/export
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.16.0)
- Recommended tools on host: `git`, `docker`, `code` (VS Code)

### Run on Linux Desktop
```bash
flutter pub get
flutter run -d linux
```

### Launch Script
```bash
./start.sh          # Gets dependencies and runs the app
./start.sh -d linux # Explicitly specify Linux
./start.sh --release # Run in release mode
```

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

> 🇬🇧 **[Click here to go back to English version](#dev-context-switcher--ultimate-edition)**

Gestionnaire d'environnements de développement desktop moderne, ultra-complet et réactif, conçu avec Flutter et Riverpod. Il permet de capturer, basculer et restaurer en un instant l'intégralité de vos sessions de travail : fenêtres applicatives avec topologie visuelle 2D, terminaux positionnés dans leurs répertoires, processus d'arrière-plan, branches Git, conteneurs Docker, onglets web, objectifs/tâches interactifs, bloc-notes et commandes de démarrage automatisées.

---

## ✨ Fonctionnalités Détaillées

- **📸 Capture Intelligente & Sélective (Capture Studio)** :
  - Détection en direct des fenêtres actives avec dimensions et coordonnées (X, Y, Largeur, Hauteur).
  - Filtrage automatique des processus développeurs pertinents (Node, Python, Dart, Flutter, VS Code, Rust, Go, Docker, C++) avec consommation CPU et RAM.
  - Détection automatique des sessions de terminaux et de leurs répertoires de travail via `/proc/$pid/cwd`.
  - Détection des conteneurs Docker en cours d'exécution avec statut et mappage de ports.
  - Capture de l'état Git (branche active, hash de commit, présence de modifications non commitées).
  - Personnalisation de couleur d'accent, favori, objectifs initiaux et commandes de démarrage dès la capture.
- **🖥️ Topologie Visuelle 2D des Fenêtres (Virtual Monitor)** :
  - Rendu proportionnel des fenêtres sur un canevas virtuel interactif avec badges de géométrie en pixels, icônes applicatives et mise en surbrillance au survol.
- **✅ Liste de Tâches & Objectifs Intégrée** :
  - Suivi en temps réel des tâches par contexte avec barre de progression dynamique.
- **📝 Bloc-notes & Mémo de Contexte** :
  - Bloc-notes persistant pour conserver les liens de documentation, instructions, identifiants locaux et prochaines étapes.
- **⚡ Commandes de Démarrage & Variables d'Environnement** :
  - Configuration de commandes personnalisées (ex : `npm run dev`, `docker compose up -d`, `cargo watch`) exécutées automatiquement lors de la restauration.
- **⚡ Restauration Instantanée & Modulaire** :
  - Relance automatique des terminaux dans les bons dossiers.
  - Checkout transparent de la branche Git du projet.
  - Démarrage automatique des conteneurs Docker requis.
  - Exécution des commandes de démarrage personnalisées.
  - Repositionnement intelligent des fenêtres et ouverture des URLs web.
  - Rapport d'exécution en direct (`RestorationReport`) avec journal des opérations.
- **⭐ Favoris & Tri Personnalisé** :
  - Épinglage des contextes favoris en 1 clic (étoile dorée).
  - Filtre "Favoris" et tri par : "Favoris d'abord", "Plus récents", "Dernière restauration", "Alphabétique".
- **🎯 Détection Automatique Multi-Langages** :
  - Détection instantanée : Flutter, React, Next.js, Vue, Svelte, Astro, Node, Python, Rust, Go, Java, Kotlin, PHP, C++, Docker Compose, Git.
  - Bannière intelligente en haut du tableau de bord avec action directe *"Capturer ce contexte"*.
- **⌨️ Raccourcis Clavier & Accès Rapide** :
  - Raccourcis `Ctrl+1` à `Ctrl+9` pour commuter instantanément d'un workspace à l'autre.
  - Palette de commandes `Ctrl+K`.
  - `Ctrl+N` pour lancer un nouveau snapshot et `Ctrl+F` pour la recherche.
- **📦 Modèles Préconfigurés (Templates)** :
  - *Flutter Desktop & Web*
  - *Full-Stack Web (Node & React)*
  - *Rust Systems & High-Perf Backend*
  - *Python AI & Data Science*
  - *Next.js & Supabase Modern Fullstack*
  - *DevOps & Docker Microservices*
- **🛠️ Diagnostics Système Intégrés** :
  - Vérification continue de Git, Docker, VS Code, émulateurs de terminaux (`ptyxis`, `cosmic-term`, `konsole`, `alacritty`, `kitty`, `gnome-terminal`, `xterm`), outils de fenêtrage (`xdotool`, `wmctrl`) et serveur d'affichage (Wayland / X11).
- **💾 Sauvegarde & Export JSON** :
  - Sauvegarde locale sécurisée dans `~/.config/dev_context_switcher/workspaces`.
  - Export individuel ou global avec copie dans le presse-papiers en un clic.
  - Modal d'importation JSON avec validation de syntaxe.

---

## 🛠️ Commandes Utiles

```bash
# Récupération des dépendances
flutter pub get

# Lancement de l'application en mode Desktop
flutter run -d linux

# Exécution de la suite de tests automatisés
flutter test

# Analyse statique du code (0 avertissements, 0 erreurs)
flutter analyze
```

---

## 📄 Licence
Projet sous licence MIT.
