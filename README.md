# Raphael


[![Version](https://img.shields.io/badge/version-1.0.0-cyan?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PC9zdmc+)](https://github.com/yourusername/raphael/releases)
[![Python](https://img.shields.io/badge/python-3.8%2B-blue?style=flat-square&logo=python&logoColor=white)](https://www.python.org/downloads/)
[![KDE Plasma](https://img.shields.io/badge/KDE%20Plasma-6.0%2B-1d99f3?style=flat-square&logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![Flask](https://img.shields.io/badge/flask-daemon-black?style=flat-square&logo=flask)](https://flask.palletsprojects.com/)
[![Groq](https://img.shields.io/badge/powered%20by-Groq-orange?style=flat-square)](https://groq.com/)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

Raphael is a sardonically supportive **ADHD cognitive advisor** that lives on your KDE Plasma desktop as a cockpit-style HUD. It watches your active windows, calls out your distractions with surgical wit, makes you justify them in writing, and turns your whole session into a telemetry dashboard.

---

## Table of Contents

- [Screenshots](#screenshots)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Dashboard](#dashboard)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Screenshots
<img width="363" height="666" alt="image" src="https://github.com/user-attachments/assets/2cb5f32f-edf7-4bd3-b4a8-62b585115f75" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/309f5951-011f-48b0-a0f7-a1510e88a6d2" />
<img width="1868" height="1035" alt="image" src="https://github.com/user-attachments/assets/f9f99a05-71ee-4d21-9185-c6c4d5fa44c3" />
<img width="1916" height="940" alt="image" src="https://github.com/user-attachments/assets/d6612b2a-e757-441e-b435-ebcb7bac41ab" />

---

## Features

### 🖥️ HUD
Two frameless, frosted-glass overlay panels (`leftQuotePanel` and `rightInsightPanel`) stay pinned above all windows and display live advisor quotes, active media track context, and a real-time focus efficiency rating.

### 🔍 Precise Window & Tab Tracking
A zero-overhead active window parser extracts the **exact browser tab title** or IDE filename from the window title, stripping browser chrome branding. so Raphael classifies what you're actually reading, not just "Google Chrome."

### ⚡ Distraction Challenges
When Raphael detects an off-task window, it fires a sardonically witty popup requiring you to provide a detailed written justification before the warning alarm resets. No free passes.

### 🧠 Behavioral Custom Directives
Tell Raphael how to behave mid-session in plain language and it remembers for the rest of the session. Examples:
- *"Remind me in 20 minutes to stretch."*
- *"From now on, never ask about music."*
- *"Be more aggressive with warnings."*

### 🔇 Active Monitoring Toggle
A settings switch lets you pause all focus/distraction tracking and popup alarms without shutting Raphael down. chat, media context, and screen-reading stay fully active.

### 📊 Web Telemetry Dashboard
A polished [Chart.js](https://www.chartjs.org/) dashboard served locally at `http://127.0.0.1:5757/dashboard`, displaying:
- Cumulative focus timeline 
- Active window distribution 
- Live session goal checklist
- Dynamic advisor feedback panel

---

## Requirements

| Dependency | Version | Notes |
|---|---|---|
| Python | 3.8+ | Core runtime |
| KDE Plasma | 6.0+ | Required for QML widget layer |
| Groq API Key | — | Set as `GROQ_API_KEY` env variable |
| Flask | Latest | Auto-installed via `run.sh` |
| Chart.js | 4.x (CDN) | Dashboard frontend |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/raphael.git
cd raphael
```

### 2. Set Your Groq API Key

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export GROQ_API_KEY="your_key_here"
```

Then reload your shell:

```bash
source ~/.bashrc
```

### 3. Install the KDE Plasma Widget

```bash
plasmapkg2 --install plasma-widget/
```

Or right-click your Plasma desktop → *Add Widgets* → *Get New Widgets* → *Install from local file* and select the widget package.

### 4. Launch the Backend Daemon

```bash
chmod +x run.sh
./run.sh
```

This installs Python dependencies, starts the Flask daemon in the background, and writes logs to `daemon.log`. The daemon listens on port `5757`.

---

## Configuration

All runtime configuration lives in `config.py` (or environment variables where noted):

| Key | Default | Description |
|---|---|---|
| `GROQ_API_KEY` | *(env)* | Your Groq API key — set in environment, not in code |
| `PORT` | `5757` | Port the Flask daemon listens on |
| `POLL_INTERVAL_S` | `5` | Seconds between active window polls |
| `DISTRACTION_THRESHOLD_S` | `30` | Seconds on a distraction window before alarm fires |
| `LOG_FILE` | `daemon.log` | Daemon log output path |

---

## Usage

### Accessing the Dashboard

Once the daemon is running, open:

```
http://127.0.0.1:5757/dashboard
```

Or click the **DASHBOARD** button directly on the Plasma widget.

### Reloading the Widget After QML Changes

If you modify any QML files and want to hot-reload the Plasma shell:

```bash
killall plasmashell && kstart plasmashell
```

> **Note:** This restarts the entire Plasma shell. All widgets reload; your daemon continues running untouched.

### Stopping the Daemon

```bash
pkill -f "raphael_daemon"
```

Or check `daemon.log` for the process PID and kill it directly.

---

## Dashboard

The web dashboard at `/dashboard` is self-contained and auto-refreshes. Sections:

- **Focus Timeline** — minute-by-minute chart of focused vs. distracted time across your session
- **Window Breakdown** — doughnut chart of time spent per application/tab category
- **Session Goals** — live checklist you set at session start, checkable from the dashboard
- **Advisor Feed** — scrolling log of Raphael's commentary and challenge responses

---

## Project Structure

```
raphael/
├── run.sh                  # Setup + daemon launch script
├── daemon.log              # Runtime log (generated on first run)
├── config.py               # Runtime configuration
├── raphael_daemon.py       # Main Flask backend + window monitor
├── templates/
│   └── dashboard.html      # Chart.js telemetry dashboard
├── plasma-widget/
│   ├── metadata.json       # Widget manifest
│   ├── contents/
│   │   └── ui/
│   │       ├── main.qml           # Root widget layout
│   │       ├── leftQuotePanel.qml # Left HUD overlay
│   │       └── rightInsightPanel.qml # Right HUD overlay
└── README.md
```

---

## Troubleshooting

**Daemon fails to start**
Check `daemon.log` for the error. Ensure `GROQ_API_KEY` is exported in the environment that runs `run.sh`, not just your IDE terminal.

**Widget shows blank / can't connect**
Confirm the daemon is running: `curl http://127.0.0.1:5757/health`. If it returns nothing, rerun `./run.sh`.

**Window titles showing generic app names**
Some Wayland compositors restrict window title access. Raphael relies on `xdotool` or KWin scripting — ensure you're not running a pure Wayland session without XWayland available.

**Plasma widget not appearing after install**
Run `plasmapkg2 --list` to confirm the widget is registered, then add it via the widget picker. If the widget picker crashes, check `~/.xsession-errors`.

---

## Contributing

Issues and PRs are welcome. For larger changes, open an issue first to discuss the direction.

```bash
# Run linting before submitting
pip install ruff
ruff check .
```

---

## License

[MIT](LICENSE) — © 2026 prathameshrp
