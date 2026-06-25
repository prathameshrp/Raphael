# Raphael // Cyberpunk Cognitive Advisor & Focus HUD

Raphael is a premium, sardonically supportive ADHD cognitive advisor and cockpit-style HUD widget built for the **KDE Plasma** desktop environment. It actively monitors your focus vectors, cleans active tabs/titles with zero overhead, helps you self-correct during distractions via challenging excuse evaluations, and compiles session insights into a visually stunning cyberpunk telemetry dashboard.

---

## ⚡ Core Features

*   **Cyberpunk Cockpit HUD Widget**: Frameless, frosted glass windows (`leftQuotePanel` and `rightInsightPanel`) stay on top to display live insights, media track context, and a live focus efficiency rating meter.
*   **Active Tab & Document Tracking**: Zero-overhead window parser that extracts exact browser tabs (stripping browser branding) or IDE files, avoiding generic "Google Chrome" classification.
*   **Telemetry excuse Challenges**: Categorizes window titles as focus or distraction. If you get distracted, Raphael prompts you with sardonically witty or caring questions, requiring detailed justification before resetting warning alarms.
*   **Behavioral Custom Directives**: Remembers custom guidelines you set dynamically in chat (e.g. *"remind me in 20 minutes to stretch"*, *"from now on never ask about music"*).
*   **Active Monitoring Switch**: A settings toggle to pause focus/distraction tracking and popup alarms entirely while keeping chat, music, and screen-vision reading active.
*   **Web Control Dashboard**: A highly polished Chart.js dashboard displaying cumulative focus timelines, active window doughnut charts, a live goal checkbox checklist, and dynamic advisor feedback.

---

## 🚀 Setup & Launch

### 1. Requirements
*   Python 3.8+
*   KDE Plasma 6.0+ (minimum requirement)
*   Groq API Key (configure `GROQ_API_KEY` in your system environment or `~/.bashrc`)

### 2. Launch Backend Daemon
Run the setup and execution script to launch the background Flask daemon:
```bash
./run.sh
```
Logs are stored locally in `daemon.log`. The daemon listens on port `5757`.

### 3. Access Dashboard
Once the daemon is active, open the dashboard in your default browser:
```
http://127.0.0.1:5757/dashboard
```
Alternatively, click the **DASHBOARD** console button on the Plasma widget.

### 4. Reloading widget Changes
If you modify QML codes and want to reload the Plasma layout instantly:
```bash
killall plasmashell && kstart plasmashell
```
