#!/usr/bin/env python3
import os
import sys
import time
import json
import subprocess
import threading
import base64
from flask import Flask, jsonify, request, make_response
from groq import Groq

app = Flask(__name__)

MEMORY_FILE = os.path.expanduser("~/.local/share/plasma/plasmoids/raphael/contents/ui/daemon/raphael_memory.json")

def get_user_name():
    global session_memory
    try:
        return session_memory.get("user_name", "")
    except:
        return ""

def load_historical_memory():
    data = None
    if os.path.exists(MEMORY_FILE):
        try:
            with open(MEMORY_FILE, 'r') as f:
                data = json.load(f)
        except Exception:
            pass
    if not data:
        data = {
            "historical_context": "First initialization sequence.",
            "suggested_goals": ["Stay on track", "One task at a time", "Focus up"],
            "last_active_timestamp": time.time()
        }
    if "custom_rules" not in data or not isinstance(data["custom_rules"], list):
        data["custom_rules"] = []
    return data

def save_historical_memory(memory_data):
    try:
        os.makedirs(os.path.dirname(MEMORY_FILE), exist_ok=True)
        with open(MEMORY_FILE, 'w') as f:
            json.dump(memory_data, f, indent=4)
    except Exception as e:
        print(f"Memory storage write failure: {e}", file=sys.stderr)

session_memory = load_historical_memory()
asked_for_name = False

def capture_screen():
    screenshot_path = os.path.join(os.path.dirname(MEMORY_FILE), "screenshot.png")
    if os.path.exists(screenshot_path):
        try:
            os.remove(screenshot_path)
        except Exception:
            pass
            
    # Try screenshot commands sequentially
    commands = [
        ["spectacle", "-b", "-n", "-o", screenshot_path],
        ["scrot", "-z", screenshot_path],
        ["maim", screenshot_path],
        ["gnome-screenshot", "-f", screenshot_path],
        ["import", "-window", "root", screenshot_path]
    ]
    
    for cmd in commands:
        try:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4)
            if os.path.exists(screenshot_path) and os.path.getsize(screenshot_path) > 0:
                return screenshot_path
        except Exception:
            continue
            
    return None


def schedule_reminder(duration_seconds, message):
    def run_reminder():
        time.sleep(duration_seconds)
        state_engine["pending_ui_messages"].append({
            "text": f"🔔 REMINDER: {message}",
            "is_angry": False,
            "is_coaching": True
        })
    threading.Thread(target=run_reminder, daemon=True).start()



def is_panel_or_desktop_window(window):
    if not window:
        return True
    w = window.lower()
    if any(x in w for x in ["plasmashell", "krunner", "desktop-portal", "desktop @", "workspace focus"]):
        return True
    if w in ["raphael", "plasma"]:
        return True
    return False

# --- REFINED SYSTEM PROMPT: Supportive, Caring, Wise advisor ---
chat_context = [
    {
        "role": "system", 
        "content": (
            "You are Raphael, an elite, caring, and highly analytical cognitive advisor. "
            "Your sole purpose is to maximize the user's focus and productivity. "
            "You are encouraging, warm, supportive, and offer top-tier advice and wisdom. "
            "If the user is distracted, give them a firm but constructive reality check. "
            "Keep all responses strictly professional, incredibly brief (1-2 sentences), and focused on their personal growth."
        )
    }
]

state_engine = {
    "quote": {"badge": "Session Resumed", "text": "Let's get things done.", "author": "Raphael"},
    "insight": {"label": "Focus Update", "src": "System", "text": "Analyzing workflow...", "tag": "focus"},
    "sensors": {"screen": "Desktop", "music": "Muted", "focus_time": "0m 0s"},
    "metrics": {"focus_seconds": 0, "distract_seconds": 0, "current_status": "Neutral"},
    "pending_ui_messages": [],
    "delays": {"quotes": 0.0, "sarcasm": 1.0, "anger": 0.5, "replies": 0.5, "proactive_comments": 1.0},
    "config": {"caring_level": 3, "ai_track": True, "proactive": True, "timeout": 60}
}

last_valid_status = "Focused Workspace"
last_non_panel_window = "Workspace"
# Initialize list of windows user flagged as non‑distraction
session_memory.setdefault("non_distraction_windows", [])
override_approved_for_window = ""
current_window = ""
current_window_duration = 0
API_KEY = os.environ.get("GROQ_API_KEY", "")
if not API_KEY:
    try:
        bashrc_path = os.path.expanduser("~/.bashrc")
        if os.path.exists(bashrc_path):
            with open(bashrc_path, "r") as f:
                for line in f:
                    if "export GROQ_API_KEY=" in line:
                        val = line.split("=", 1)[1].strip().strip('"').strip("'")
                        if val:
                            API_KEY = val
                            os.environ["GROQ_API_KEY"] = API_KEY
                            break
    except Exception:
        pass
client = Groq(api_key=API_KEY) if API_KEY else None

# Cache for window classifications
window_cache = {}
pending_classifications = set()

# --- Session History & Dashboard Database ---
HISTORY_FILE = os.path.expanduser("~/.local/share/plasma/plasmoids/raphael/contents/ui/daemon/raphael_history.json")

def load_session_history():
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE, 'r') as f:
                data = json.load(f)
                if isinstance(data, dict) and "past_sessions" in data and "current_session" in data:
                    return data
        except Exception:
            pass
    return {"past_sessions": [], "current_session": None}

def save_session_history(history_data):
    try:
        os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)
        with open(HISTORY_FILE, 'w') as f:
            json.dump(history_data, f, indent=4)
    except Exception as e:
        print(f"Failed to write session history: {e}", file=sys.stderr)

history_store = load_session_history()

def init_or_resume_session():
    global history_store
    now = time.time()
    curr = history_store.get("current_session")
    
    # If there is a current session, check if it's recent (last active within 1 hour)
    if curr and isinstance(curr, dict):
        last_active = curr.get("last_active_time", 0)
        if now - last_active < 3600:
            print("Resuming recent session.")
            return curr
        else:
            # Archive old session to past_sessions
            print("Archiving old session.")
            history_store["past_sessions"].append(curr)
            # Limit past sessions list to 50 for storage efficiency
            if len(history_store["past_sessions"]) > 50:
                history_store["past_sessions"] = history_store["past_sessions"][-50:]
            
    # Start a brand new session
    print("Starting new session.")
    new_sess = {
        "id": int(now),
        "start_time": now,
        "last_active_time": now,
        "focus_seconds": 0,
        "distract_seconds": 0,
        "window_durations": {},
        "timeline": [],  # list of {"window": "...", "status": "...", "duration": X, "timestamp": float}
        "ai_insights": []
    }
    history_store["current_session"] = new_sess
    save_session_history(history_store)
    return new_sess

current_session = init_or_resume_session()


def get_kwin_active_window():
    # 1. Try X11 xdotool first (highly reliable on X11)
    try:
        out = subprocess.check_output(["xdotool", "getactivewindow", "getwindowname"], stderr=subprocess.DEVNULL).decode().strip()
        if out:
            return out
    except Exception:
        pass

    # 2. Try DBus fallback for Wayland
    for cmd in ["qdbus6", "qdbus"]:
        try:
            out = subprocess.check_output([cmd, "org.kde.KWin", "/KWin", "supportInformation"], stderr=subprocess.DEVNULL).decode()
            for line in out.splitlines():
                if "Active window:" in line:
                    return line.split("Active window:")[1].strip()
        except Exception:
            continue
    return "Workspace Focus"

def get_open_windows_context():
    active = get_kwin_active_window()
    all_windows = []
    try:
        # Fetch open windows via xprop (X11)
        out = subprocess.check_output(["xprop", "-root", "_NET_CLIENT_LIST"], stderr=subprocess.DEVNULL).decode()
        if "window id #" in out:
            ids_part = out.split("window id #")[1].strip()
            wids = [wid.strip() for wid in ids_part.split(",") if wid.strip()]
            for wid in wids:
                try:
                    w_out = subprocess.check_output(["xprop", "-id", wid, "_NET_WM_NAME", "WM_NAME"], stderr=subprocess.DEVNULL).decode()
                    for line in w_out.splitlines():
                        if " = " in line:
                            val = line.split(" = ", 1)[1].strip()
                            if val.startswith('"') and val.endswith('"'):
                                name = val[1:-1]
                                if name and name not in all_windows:
                                    if not any(x in name.lower() for x in ["plasmashell", "krunner", "desktop-portal", "desktop @"]):
                                        all_windows.append(name)
                                break
                except:
                    continue
    except:
        pass
    return {
        "active_window": active,
        "all_open_windows": all_windows
    }

def format_seconds_to_string(total_secs):
    return f"{total_secs // 60}m {total_secs % 60}s"

def get_clean_active_tab_or_file(window):
    if not window:
        return "Workspace"
    w_low = window.lower()
    
    # If browser, extract active tab title
    for browser in ["google chrome", "chromium", "firefox", "brave", "opera", "edge"]:
        if browser in w_low:
            parts = window.split(" - ")
            if len(parts) > 1:
                # Remove browser suffix
                return " - ".join(parts[:-1])
            return window
            
    # If VS Code, extract active file
    if "visual studio code" in w_low or "vscode" in w_low or "code - oss" in w_low:
        parts = window.split(" - ")
        if len(parts) > 1:
            return parts[0]
            
    # Remove standard desktop/panel names
    if "plasmashell" in w_low or "desktop @" in w_low:
        return "Workspace"
        
    return window

def get_linux_media_track():
    try:
        return subprocess.check_output(["playerctl", "metadata", "title"], stderr=subprocess.DEVNULL).decode().strip()
    except:
        return "Nothing playing"

def fast_classify_window(window):
    w = window.lower()
    if not w or w == "desktop" or w == "workspace focus" or w == "workspace":
        return "focused"
    
    # 1. Dev environments, editors, and technical resources
    if any(x in w for x in [
        "visual studio code", "vscode", "code - oss", "terminal", "console", 
        "kitty", "alacritty", "bash", "zsh", "tmux", "cmake", "make", "konsole", 
        "pycharm", "clion", "kate", "kwrite", "sublime", "neovim", "vim", "emacs",
        "github", "gitlab", "stack overflow", "stackoverflow", "localhost", "127.0.0.1", 
        "docs.python", "w3schools", "geeksforgeeks", "developer.mozilla", "dev.to", 
        "medium.com", "chatgpt", "gemini.google", "claude.ai", "copilot", "google search", 
        "documentation", "mdbook", "okular", "zotero", "pdf", "epub"
    ]):
        return "focused"
        
    if "discord" in w:
        return "focused"
        
    # 2. Blacklisted entertainment, streaming, and social networks
    if any(x in w for x in [
        "youtube", "netflix", "prime video", "hulu", "disney+", 
        "twitch", "steam", "valorant", "facebook", "reddit", 
        "instagram", "tiktok", "twitter", "x.com", "spotify", 
        "music.youtube", "pinterest", "tumblr"
    ]):
        return "distracted"
    return None
    return None

def async_classify_window(window):
    global window_cache, pending_classifications
    if not window or window in window_cache or window in pending_classifications:
        return
    
    fast = fast_classify_window(window)
    if fast is not None:
        window_cache[window] = fast
        return
        
    pending_classifications.add(window)
    
    def run_classification():
        try:
            prompt = f"""You are Raphael's cognitive window classifier.
            Determine if the following window title represents a productive task ('focused') or a distraction ('distracted').
            Window Title: "{window}"
            Respond in JSON format: {{"classification": "focused" or "distracted", "reason": "short explanation"}}
            """
            if client:
                resp = client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": "You categorize window titles for productivity context tracking."},
                        {"role": "user", "content": prompt}
                    ], 
                    model="llama-3.1-8b-instant",
                    response_format={"type": "json_object"}
                )
                result = json.loads(resp.choices[0].message.content.strip())
                classification = result.get("classification", "focused")
                window_cache[window] = classification
            else:
                window_cache[window] = "focused"
        except:
            window_cache[window] = "focused"
        finally:
            pending_classifications.discard(window)
            
    threading.Thread(target=run_classification, daemon=True).start()

def update_persistent_memory_on_disk(force=False):
    global state_engine, session_memory, last_non_panel_window
    if not client: return
    
    focus_time = format_seconds_to_string(state_engine["metrics"]["focus_seconds"])
    distract_time = format_seconds_to_string(state_engine["metrics"]["distract_seconds"])
    
    prompt = f"""
    The user is wrapping up their work session or has triggered a memory save.
    Session statistics:
    - Active Focus Time: {focus_time}
    - Distract Time: {distract_time}
    - Last Active Window: {last_non_panel_window}
    
    Previous Session Context: "{session_memory.get('historical_context', 'First initialization sequence.')}"
    
    Generate:
    1. A short, caring summary (2 sentences) of what was achieved in this session and what to focus on next. Address the user by their learned name '{get_user_name()}' if available. Do not use colloquial terms like 'bhai' or 'yaar'.
    2. 3 concrete suggested tactical targets/goals for their next session.
    
    Respond in JSON format matching this schema:
    {{"summary": "your 2-sentence summary", "suggested_goals": ["goal 1", "goal 2", "goal 3"]}}
    """
    try:
        resp = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You compile session summaries and focus goals for a productivity advisor widget."},
                {"role": "user", "content": prompt}
            ],
            model="llama-3.1-8b-instant",
            response_format={"type": "json_object"}
        )
        result = json.loads(resp.choices[0].message.content.strip())
        
        session_memory["historical_context"] = result.get("summary", "Keep up the consistent work.")
        session_memory["suggested_goals"] = result.get("suggested_goals", ["Stay focused", "Avoid distractions", "Keep coding"])
        session_memory["last_active_timestamp"] = time.time()
        save_historical_memory(session_memory)
        print("Persistent session memory updated on disk.")
    except Exception as e:
        print(f"Failed to update persistent session memory: {e}", file=sys.stderr)

def timeline_seconds_evaluator():
    global state_engine, last_valid_status, last_non_panel_window, window_cache, override_approved_for_window, current_window, current_window_duration
    while True:
        window_ctx = get_open_windows_context()
        window = window_ctx["active_window"]
        if not is_panel_or_desktop_window(window):
            last_non_panel_window = window
            
            # Reset active override if window switched
            if override_approved_for_window and window != override_approved_for_window:
                override_approved_for_window = ""
                
            # Track window duration
            if window == current_window:
                current_window_duration += 1
            else:
                current_window = window
                current_window_duration = 0
                state_engine["excuse_challenge_count"] = 0
            
            # AI-Dictated Classification
            if window not in window_cache:
                async_classify_window(window)
                
            status = window_cache.get(window, fast_classify_window(window) or "focused")
            
            if window == override_approved_for_window:
                if current_window_duration >= 300:
                    override_approved_for_window = ""
                else:
                    status = "focused"
                
            # If AI Window Tracking is disabled via QML config, fall back to fast rules only
            if not state_engine.get("config", {}).get("ai_track", True):
                status = fast_classify_window(window) or "focused"
            
            current_session["last_active_time"] = time.time()
            
            if not state_engine.get("config", {}).get("active_monitoring", True):
                state_engine["metrics"]["current_status"] = "Monitoring Suspended"
                current_session["window_durations"][window] = current_session["window_durations"].get(window, 0) + 1
                
                timeline = current_session["timeline"]
                status_str = "suspended"
                if timeline and timeline[-1]["window"] == window and timeline[-1]["status"] == status_str:
                    timeline[-1]["duration"] += 1
                else:
                    timeline.append({
                        "window": window,
                        "status": status_str,
                        "duration": 1,
                        "timestamp": time.time()
                    })
                    if len(timeline) > 1000:
                        current_session["timeline"] = timeline[-1000:]
                
                if int(time.time()) % 10 == 0:
                    save_session_history(history_store)
            else:
                if status == "distracted":
                    state_engine["metrics"]["distract_seconds"] += 1
                    state_engine["metrics"]["current_status"] = "Taking a break"
                    current_session["distract_seconds"] += 1
                else:
                    state_engine["metrics"]["focus_seconds"] += 1
                    state_engine["metrics"]["current_status"] = "Working"
                    current_session["focus_seconds"] += 1

                # Update window durations
                current_session["window_durations"][window] = current_session["window_durations"].get(window, 0) + 1
                
                # Update timeline (aggregate contiguous entries)
                timeline = current_session["timeline"]
                status_str = "distracted" if status == "distracted" else "focused"
                if timeline and timeline[-1]["window"] == window and timeline[-1]["status"] == status_str:
                    timeline[-1]["duration"] += 1
                else:
                    timeline.append({
                        "window": window,
                        "status": status_str,
                        "duration": 1,
                        "timestamp": time.time()
                    })
                    if len(timeline) > 1000:
                        current_session["timeline"] = timeline[-1000:]
                
                # Periodic auto-save every 10 seconds
                if int(time.time()) % 10 == 0:
                    save_session_history(history_store)
        time.sleep(1)

def proactive_coaching_interrupter():
    global state_engine, chat_context, last_non_panel_window, current_window_duration, session_memory
    focus_tick = 0
    while True:
        time.sleep(45)
        
        cfg = state_engine.get("config", {"caring_level": 3, "ai_track": True, "proactive": True, "timeout": 60})
        if not client or not cfg.get("proactive", True):
            continue
            
        status = state_engine["metrics"]["current_status"]
        distract_secs = state_engine["metrics"]["distract_seconds"]
        caring = cfg.get("caring_level", 3)
        timeout = cfg.get("timeout", 60)
        u_name = get_user_name() or "The user"
        
        custom_rules = session_memory.get("custom_rules", [])
        rules_str = "\n".join(f"- {rule}" for rule in custom_rules) if custom_rules else "None"
        
        formatting_rules = (
            "\nCRITICAL requirements:\n"
            "1. Return your entire message as a single continuous paragraph (single line of text) with NO newlines, paragraph breaks, or line breaks of any kind.\n"
            "2. Do NOT hallucinate or assume details not present in the user's active window or telemetry data. Base your response strictly on the provided real data. Do not make up files or applications.\n"
            "3. Respect and adhere strictly to these User's Custom Rules / Behavioral Instructions:\n"
            f"{rules_str}\n"
        )
        
        # Check if the user has been working/focusing on the SAME app for too long (e.g. 15 minutes = 900s)
        if status == "Working" and current_window_duration >= 900:
            current_window_duration = 0  # reset timer to count next 15m
            prompt = (
                f"{u_name} has been coding/working inside '{last_non_panel_window}' for 15 minutes straight. "
                "Offer a caring reminder to stand up, take a breath, stretch, or check if they need help explaining "
                "any complex concepts they are working on right now. Keep it brief (max 2 sentences) and warm."
            ) + formatting_rules
            try:
                completion = client.chat.completions.create(messages=[{"role":"user","content":prompt}], model="llama-3.1-8b-instant")
                state_engine["pending_ui_messages"].append({
                    "text": completion.choices[0].message.content.strip().replace("\n", " "),
                    "is_angry": False,
                    "is_coaching": True
                })
            except: pass
            continue
            
        if status == "Taking a break" and distract_secs > 0:
            if distract_secs > timeout:
                # Escalated distraction check
                # Tone depends on caring level
                if caring >= 4:
                    prompt = (
                        f"{u_name} has been distracted on '{last_non_panel_window}' for {distract_secs} seconds. "
                        "You are a supportive, caring advisor concerned about his focus. Ask him kindly but firmly "
                        "what is holding him back, and offer to help explain concepts or help him re-focus. Keep it under 2 sentences."
                    ) + formatting_rules
                    is_angry = False
                else:
                    prompt = (
                        f"{u_name} has been distracted on '{last_non_panel_window}' for {distract_secs} seconds. "
                        "You are angry and highly demanding. Sardonically demand he get back to work immediately. "
                        "Use caps and sharp sarcasm. Keep it under 2 sentences."
                    ) + formatting_rules
                    is_angry = True
                try:
                    completion = client.chat.completions.create(messages=[{"role":"user","content":prompt}], model="llama-3.1-8b-instant")
                    state_engine["pending_ui_messages"].append({
                        "text": completion.choices[0].message.content.strip().replace("\n", " "),
                        "is_angry": is_angry,
                        "is_coaching": True
                    })
                except: pass
            else:
                # Initial nudge
                prompt = (
                    f"{u_name} is looking at '{last_non_panel_window}'. Give him a caring but firm nudge to stop slacking. "
                    "Keep it under 15 words."
                ) + formatting_rules
                try:
                    completion = client.chat.completions.create(messages=[{"role":"user","content":prompt}], model="llama-3.1-8b-instant")
                    state_engine["pending_ui_messages"].append({
                        "text": completion.choices[0].message.content.strip().replace("\n", " "),
                        "is_angry": False,
                        "is_coaching": True
                    })
                except: pass
        else:
            # Focused proactive check-ins, reading concept prompts, or music judgment
            focus_tick += 1
            if focus_tick >= 4:
                focus_tick = 0
                
                # Check if currently reading a book/doc
                is_reading = any(x in last_non_panel_window.lower() for x in ["pdf", "okular", "zotero", "epub", "book", "reader", "kindle"])
                
                if is_reading:
                    prompt = (
                        f"{u_name} is currently reading/studying a document with window title '{last_non_panel_window}'. "
                        "Based on the book or topic in the title, proactively suggest a key concept, a thought-provoking "
                        "study question, or offer to explain/summarize any complex terms related to this reading material. "
                        "Be caring, highly intellectual, and supportive. Max 2 sentences."
                    ) + formatting_rules
                else:
                    music = state_engine["sensors"]["music"]
                    
                    discord_context = ""
                    if "discord" in last_non_panel_window.lower():
                        discord_context = f"He is currently active on Discord. Remind him to keep chat brief, and ask what they are discussing, adding a friendly opinion."
                    
                    music_context = ""
                    if music != "Muted" and music != "Nothing playing":
                        music_context = f"He is listening to '{music}'. Give an encouraging comment or friendly critique on his track choice."
                    
                    prompt = (
                        f"{u_name} is currently working and focused. Active window is '{last_non_panel_window}'. "
                        f"{discord_context} {music_context} "
                        "Ask him an encouraging, caring, or highly analytical study question about his work "
                        "or offer a quick tip to stay productive. Keep it under 2 sentences."
                    ) + formatting_rules
                try:
                    completion = client.chat.completions.create(messages=[{"role":"user","content":prompt}], model="llama-3.1-8b-instant")
                    state_engine["pending_ui_messages"].append({
                        "text": completion.choices[0].message.content.strip().replace("\n", " "),
                        "is_angry": False,
                        "is_coaching": True
                    })
                except: pass

def production_ai_loop():
    while True:
        if client:
            prompt = """
            Give me a wise, inspiring philosophical quote about concentration, study, focus, or dedication.
            The quote must be under 15 words.
            Respond in JSON format:
            {
                "text": "the quote text without any quotation marks or author name",
                "author": "name of the thinker"
            }
            """
            try:
                resp = client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": "You provide inspiring quotes in JSON format."},
                        {"role": "user", "content": prompt}
                    ],
                    model="llama-3.1-8b-instant",
                    response_format={"type": "json_object"}
                )
                result = json.loads(resp.choices[0].message.content.strip())
                state_engine["quote"]["text"] = result.get("text", "Focus on your tasks.").replace('"', '').strip()
                state_engine["quote"]["author"] = result.get("author", "Unknown").strip()
            except: pass
        time.sleep(60)

def text_only_screen_fallback():
    window_ctx = get_open_windows_context()
    active_window = window_ctx["active_window"]
    all_windows = window_ctx["all_open_windows"]
    # If the active window is a panel or desktop, fall back to the last non-panel window for context
    focus_window = active_window if not is_panel_or_desktop_window(active_window) else last_non_panel_window
    
    prompt = f"""
    The user asked you to read the screen, but a screenshot could not be captured or the vision API is unavailable.
    Using the most relevant window name (non-panel if available):
    - Focus Window: "{focus_window}" (fallback to active window if needed)
    - All Open Application Windows: {all_windows}
    
    Please explain what you can infer from this text context.
    CRITICAL requirements:
    1. Keep the response under 2 sentences, caring and high-tech in tone.
    2. Return the response as a single, continuous paragraph (single line of text) with NO newlines, paragraph breaks, or line breaks of any kind.
    3. Do NOT hallucinate or assume details not present in the text.
    """
    try:
        resp = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.1-8b-instant"
        )
        return resp.choices[0].message.content.strip()
    except Exception:
        return f"I can see you are currently focusing on '{active_window}'."

@app.route("/chat_v4", methods=["POST"])
def handle_chat_v4():
    global chat_context, last_non_panel_window, state_engine, override_approved_for_window, session_memory
    data = request.json or {}
    msg = data.get("message", "")
    action = None
    reason = None
    
    # Get active window context
    window_ctx = get_open_windows_context()
    active_window = window_ctx["active_window"]
    all_windows = window_ctx["all_open_windows"]
    # If the active window is a panel or desktop, fall back to the last non-panel window for context
    focus_window = active_window if not is_panel_or_desktop_window(active_window) else last_non_panel_window
    
    distract_secs = state_engine["metrics"]["distract_seconds"]
    is_distracted = state_engine["metrics"]["current_status"] == "Taking a break"
    caring = state_engine.get("config", {}).get("caring_level", 3)
    # Respect user-declared non-distraction windows
    if active_window in session_memory.get("non_distraction_windows", []):
        is_distracted = False
    timeout = state_engine.get("config", {}).get("timeout", 60)
    
    is_angry = False
    
    # Detect user explicitly marking current window as non-distraction
    if "not a distraction" in msg.lower():
        nd_list = session_memory.setdefault("non_distraction_windows", [])
        if active_window not in nd_list:
            nd_list.append(active_window)
            save_historical_memory(session_memory)

    # Q&A justification logic for distracted state
    if is_distracted and client:
        challenge_count = state_engine.get("excuse_challenge_count", 0)
        eval_prompt = f"""
        The user is currently active on window '{active_window}', which is categorized as a distraction.
        The user's explanation/reply: "{msg}"
        Previous challenge count for this distraction: {challenge_count}
        
        Evaluate the user's explanation and select an action:
        - If the user provides any mention of a work-related, study, learning, or tutorial topic (e.g. "learning Flask", "studying docs", "researching history"): choose "APPROVE". Raphael must accept the justification, reset the distraction warning, and encourage them.
        - If the user claims they are working or studying, but their explanation is extremely vague and lacks any topic context (e.g. just saying "I am working", "doing study", "it's for work"): choose "CHALLENGE" (if previous challenge count is 0) or "APPROVE" (if previous challenge count is 1 or more). Raphael must retaliate and ask a question if challenge count is 0.
        - If the excuse is weak, evasive, or explicitly procrastination (e.g. "watching memes", "just chilling"): choose "REJECT". Raphael must sardonically or firmly nudge them to get back to work.
        - CRITICAL RULE: Do not challenge the user more than once. If the previous challenge count is 1 or more, and they reply with any response that isn't direct procrastination, you MUST choose "APPROVE".
        
        Respond in JSON format:
        {{
            "action": "CHALLENGE" or "APPROVE" or "REJECT",
            "reason": "brief analysis of the user's excuse",
            "response": "Raphael's reply to the user"
        }}
        
        Guidelines for Raphael's response:
        1. Keep it under 2 sentences.
        2. Be caring but firm.
        3. If action is "CHALLENGE", be skeptical and ask a probing question.
        4. If action is "APPROVE", be supportive and encouraging.
        5. If action is "REJECT", give a firm reality check.
        6. CRITICAL formatting requirement: Return the response as a single, continuous paragraph (single line of text) with NO newlines, paragraph breaks, or line breaks of any kind. Keep it in a single paragraph.
        7. CRITICAL information requirement: Do NOT hallucinate or assume details not present in the user's active window or telemetry data. Base your response strictly on the provided real data. Do not make up files or applications.
        """
        try:
            resp = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": "You evaluate user excuses. Guidelines: Responses must be single paragraphs, no newlines, no hallucinations."},
                    {"role": "user", "content": eval_prompt}
                ],
                model="llama-3.1-8b-instant",
                response_format={"type": "json_object"}
            )
            result = json.loads(resp.choices[0].message.content.strip())
            action = result.get("action", "REJECT")
            reason = result.get("reason", "")
            
            if action == "APPROVE":
                override_approved_for_window = active_window
                state_engine["metrics"]["distract_seconds"] = 0
                state_engine["metrics"]["current_status"] = "Working (Override Approved)"
                state_engine["excuse_challenge_count"] = 0
                is_angry = False
            elif action == "CHALLENGE":
                state_engine["excuse_challenge_count"] = challenge_count + 1
                is_angry = False  # Don't flash angry during challenge dialogue
            else:  # REJECT
                is_angry = (distract_secs > timeout) and (caring < 4)
                
            reply = result.get("response", "Let's focus.").replace("\n", " ").strip()
        except Exception as e:
            print(f"Chat justification error: {e}", file=sys.stderr)
            reply = "Let's get back to focus."
    else:
        # Standard productive chat
        stored_name = get_user_name()
        name_instruction = f"Address the user by their name '{stored_name}' if appropriate." if stored_name else "Do not address the user by name (they haven't told you it yet). Keep the tone polite, supportive, and professional without using slang."
        
        custom_rules = session_memory.get("custom_rules", [])
        rules_str = "\n".join(f"- {rule}" for rule in custom_rules) if custom_rules else "None"
        
        system = f"""You are Raphael, an elite, caring, and highly analytical cognitive advisor.
        Current Session State:
        - User's Stored Name: "{stored_name or 'None'}"
        - Active Window: "{active_window}"
        - All Open Application Windows: {all_windows}
        - Music Track: "{state_engine["sensors"]["music"]}"
        - Focus Time: {state_engine["sensors"]["focus_time"]}
        - User's Custom Rules / Behavioral Instructions:
{rules_str}
        
        INSTRUCTIONS:
        1. You have access to the user's real session context (listed above). Refer to their active window or other open windows in your reply if they ask. Do not make up list of windows.
        2. {name_instruction}
        3. If the user introduces themselves, states their name, or tells you what to call them, extract that name and return it in the 'set_user_name' property.
        4. If the user establishes a new behavioral rule, preference, or long-term instruction (e.g. "from now on if i do this do this", "be more interactive with me", "never ask about music", etc.), extract that rule/instruction exactly into the 'new_rule' property. If not requested, set 'new_rule' to null.
        5. If the user asks to clear/delete their custom rules or reset rules, set 'clear_rules' to true, otherwise false.
        6. If the user asks you to remind them of something, set a timer, or remind them in a certain duration (e.g. "remind me in 20 mins to stretch"), extract the reminder message and calculate the duration in seconds. Return them in the 'set_reminder' property: {{"duration_seconds": X, "message": "reminder message"}}. If not requested, set 'set_reminder' to null.
        7. If the user is asking you to read the screen, look at the screen, explain what's on the screen, or analyze their workspace visually, set 'read_screen_request' to true. Otherwise, set it to false.
        8. Keep responses brief (max 2 sentences), supportive, warm, and encourage productivity.
        9. CRITICAL formatting requirement: Return the response as a single, continuous paragraph (single line of text) with NO newlines, paragraph breaks, or line breaks of any kind. Keep it in a single paragraph.
        10. CRITICAL information requirement: Do NOT hallucinate or assume details not present in the user's active window or telemetry data. Base your response strictly on the provided real data. Do not make up files or applications. Adhere strictly to the User's Custom Rules if any are defined.
        
        You must respond in JSON format matching this schema:
        {{
          "response": "your advice or reply",
          "set_user_name": "extracted name if user mentioned it, otherwise null",
          "new_rule": "extracted rule string if user is setting a new preference/rule, otherwise null",
          "clear_rules": true or false,
          "set_reminder": {{"duration_seconds": 1200, "message": "stretch"}} or null,
          "read_screen_request": true or false
        }}
        """
        try:
            resp = client.chat.completions.create(
                messages=[{"role": "system", "content": system}, {"role": "user", "content": msg}],
                model="llama-3.1-8b-instant",
                response_format={"type": "json_object"}
            )
            result = json.loads(resp.choices[0].message.content.strip())
            reply = result.get("response", "Focus on your tasks.").replace("\n", " ").strip()
            
            # 1. User name
            new_name = result.get("set_user_name")
            if new_name:
                session_memory["user_name"] = new_name
                save_historical_memory(session_memory)
                
            # 2. Clear Rules
            if result.get("clear_rules"):
                session_memory["custom_rules"] = []
                save_historical_memory(session_memory)
                
            # 3. New Rule
            new_rule = result.get("new_rule")
            if new_rule:
                session_memory.setdefault("custom_rules", []).append(new_rule)
                save_historical_memory(session_memory)
                
            # 4. Set Reminder
            reminder = result.get("set_reminder")
            if reminder and isinstance(reminder, dict):
                secs = reminder.get("duration_seconds")
                rem_msg = reminder.get("message")
                if secs and rem_msg:
                    schedule_reminder(secs, rem_msg)
                    
            # 5. Read Screen Request
            if result.get("read_screen_request"):
                # Use the most relevant window name for context (prefer non-panel window)
                screen_window = focus_window if focus_window else active_window
                scr_file = capture_screen()
                if scr_file:
                    try:
                        with open(scr_file, "rb") as image_file:
                            encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                        
                        vision_prompt = f"""
                        The user (whose name is '{stored_name}') asked you to read the screen while focusing on '{screen_window}'. Here is a screenshot of their current workspace.
                        
                        Please explain what you see on the screen and provide cognitive advice, taking into account:
                        - User's custom rules (if any):
                        {rules_str}
                        
                        CRITICAL requirements:
                        1. Keep the response under 3 sentences.
                        2. Be highly analytical, caring, and cockpit-advisor-like in tone.
                        3. Return the response as a single, continuous paragraph (single line of text) with NO newlines, paragraph breaks, or line breaks of any kind.
                        4. Do NOT hallucinate or assume details not present in the image. Base your response strictly on the visible workspace.
                        """
                        
                        vision_resp = None
                        try:
                            vision_resp = client.chat.completions.create(
                                messages=[
                                    {
                                        "role": "user",
                                        "content": [
                                            {"type": "text", "text": vision_prompt},
                                            {
                                                "type": "image_url",
                                                "image_url": {
                                                    "url": f"data:image/png;base64,{encoded_string}"
                                                }
                                            }
                                        ]
                                    }
                                ],
                                model="llama-3.2-11b-vision-preview"
                            )
                        except Exception:
                            # Fallback model
                            vision_resp = client.chat.completions.create(
                                messages=[
                                    {
                                        "role": "user",
                                        "content": [
                                            {"type": "text", "text": vision_prompt},
                                            {
                                                "type": "image_url",
                                                "image_url": {
                                                    "url": f"data:image/png;base64,{encoded_string}"
                                                }
                                            }
                                        ]
                                    }
                                ],
                                model="llama-3.2-90b-vision-preview"
                            )
                        
                        if vision_resp:
                            reply = vision_resp.choices[0].message.content.strip().replace("\n", " ")
                    except Exception as vision_err:
                        print(f"Vision api error: {vision_err}", file=sys.stderr)
                        reply = text_only_screen_fallback()
                else:
                    reply = text_only_screen_fallback()
                    
        except Exception as e:
            print(f"Chat error: {e}", file=sys.stderr)
            reply = "Focus and consistency are the keys to mastery."
            
    return make_response(jsonify({"response": reply.replace("\n", " ").strip(), "is_angry": is_angry, "action": action, "reason": reason}))

def generate_session_summary():
    context = session_memory.get("historical_context", "We just started.")
    goals = session_memory.get("suggested_goals", [])
    
    prompt = f"""
    The user is wrapping up their session. Here is the context:
    {context}
    And these were the goals:
    {goals}
    
    Give a very simple, 2-sentence summary of what was done and 1 clear improvement for the next time. 
    Keep it friendly, simple, and encouraging. Do not use slang terms.
    No preaching. Just straight talk.
    """
    try:
        completion = client.chat.completions.create(
            messages=[{"role":"user","content":prompt}], 
            model="llama-3.1-8b-instant"
        )
        return completion.choices[0].message.content.strip()
    except:
        return "You did well today. Let's do even better next time."

@app.route("/get_summary", methods=["GET"])
def get_summary():
    update_persistent_memory_on_disk(force=True)
    summary = session_memory.get("historical_context", "You did well today. Let's do even better next time.")
    return jsonify({"summary": summary})

@app.route("/telemetry_v3", methods=["GET"])
def handle_telemetry_v3():
    global state_engine, session_memory, asked_for_name
    
    # Read configuration overrides passed from QML
    caring = request.args.get("caring", "3")
    ai_track = request.args.get("ai_track", "true")
    proactive = request.args.get("proactive", "true")
    timeout = request.args.get("timeout", "60")
    active_monitoring = request.args.get("active_monitoring", "true")
    
    state_engine["config"] = {
        "caring_level": int(caring) if caring.isdigit() else 3,
        "ai_track": ai_track.lower() == "true",
        "proactive": proactive.lower() == "true",
        "timeout": int(timeout) if timeout.isdigit() else 60,
        "active_monitoring": active_monitoring.lower() == "true"
    }
    
    # Check if we should ask the user for their name on first load
    if not get_user_name() and not asked_for_name:
        state_engine["pending_ui_messages"].append({
            "text": "I don't think we've officially met yet. What should I call you?",
            "is_angry": False,
            "is_coaching": False
        })
        asked_for_name = True
    
    window_ctx = get_open_windows_context()
    window = window_ctx["active_window"]
    if is_panel_or_desktop_window(window):
        window = last_non_panel_window
    
    state_engine["sensors"]["screen"] = window if window else "Desktop"
    state_engine["sensors"]["screen_clean"] = get_clean_active_tab_or_file(window)
    
    music = get_linux_media_track()
    state_engine["sensors"]["music"] = music if music else "Muted"
    
    focus_seconds = state_engine["metrics"]["focus_seconds"]
    state_engine["sensors"]["focus_time"] = format_seconds_to_string(focus_seconds)
    
    distract_seconds = state_engine["metrics"]["distract_seconds"]
    state_engine["sensors"]["distract_time"] = format_seconds_to_string(distract_seconds)
    
    # Check if window suggests reading or coding to update insight
    if any(x in window.lower() for x in ["pdf", "okular", "zotero", "epub", "book", "reader", "kindle"]):
        state_engine["insight"] = {
            "label": "Reading Protocol Active",
            "src": "Document Feed",
            "text": f"Reading detected on '{window}'. If you encounter complex concepts or need notes summarized, just ask me to explain them!",
            "tag": "reading"
        }
    elif any(x in window.lower() for x in ["visual studio code", "vscode", "code - oss", "terminal", "console", "kitty", "alacritty", "konsole"]):
        state_engine["insight"] = {
            "label": "Development Stream",
            "src": "IDE Matrix",
            "text": "Active coding session. Remember to follow clean code guidelines. Ask me for optimization reviews or documentation templates if needed.",
            "tag": "focus"
        }
    elif "discord" in window.lower():
        state_engine["insight"] = {
            "label": "Communication Vector",
            "src": "Discord",
            "text": "Discord window is active. Chatting is whitelisted, but keep it brief to stay on track. Ask me if your friends say anything questionable!",
            "tag": "pattern"
        }
    elif state_engine["metrics"]["current_status"] == "Taking a break":
        state_engine["insight"] = {
            "label": "Cognitive Drift Alert",
            "src": "Telemetry",
            "text": f"You have drifted to '{window}'. Explain to me why this is necessary to clear the distraction warning.",
            "tag": "distract"
        }
    else:
        state_engine["insight"] = {
            "label": "Workspace Observation",
            "src": "Live Analytics",
            "text": f"Observing '{window}'... Stay focused.",
            "tag": "focus"
        }
        
    response_data = state_engine.copy()
    response_data["session_summary"] = session_memory.get("historical_context", "Resuming cognitive timeline parameters...")
    response_data["session_goals"] = session_memory.get("suggested_goals", ["Calibrating focus vectors", "Loading milestones"])
    
    return jsonify(response_data)

@app.route("/update_delays", methods=["POST"])
def update_delays():
    global state_engine
    data = request.json or {}
    for k, v in data.items():
        if k in state_engine["delays"]:
            try:
                state_engine["delays"][k] = float(v)
            except ValueError:
                pass
    return jsonify({"status": "updated", "delays": state_engine["delays"]})

@app.route("/flush_proactive_msg", methods=["POST"])
def flush_proactive_msg():
    global state_engine
    state_engine["pending_ui_messages"] = []
    return jsonify({"status": "flushed"})

@app.route("/override", methods=["POST"])
def handle_override():
    global state_engine
    data = request.json or {}
    reason = data.get("reason", "")
    
    state_engine["metrics"]["distract_seconds"] = 0
    state_engine["metrics"]["current_status"] = "Working (Override Approved)"
    
    state_engine["pending_ui_messages"].append({
        "text": f"Override request approved for reason: '{reason}'. Re-focusing workspace metrics now.",
        "is_angry": False,
        "is_coaching": False
    })
    
    return jsonify({"approved": True})

# --- Dashboard API & Serving Routes ---

@app.route("/dashboard", methods=["GET"])
def serve_dashboard():
    dashboard_path = os.path.expanduser("~/.local/share/plasma/plasmoids/raphael/contents/ui/daemon/dashboard.html")
    if os.path.exists(dashboard_path):
        with open(dashboard_path, 'r') as f:
            content = f.read()
        return make_response(content)
    else:
        return "Dashboard HTML template not found. Please verify placement.", 404

@app.route("/api/session_data", methods=["GET"])
def get_session_data():
    global history_store, current_session, session_memory, state_engine
    return jsonify({
        "current_session": current_session,
        "past_sessions": history_store.get("past_sessions", []),
        "custom_rules": session_memory.get("custom_rules", []),
        "suggested_goals": session_memory.get("suggested_goals", []),
        "user_name": get_user_name(),
        "challengeCount": state_engine.get("excuse_challenge_count", 0)
    })

@app.route("/api/complete_goal", methods=["POST"])
def complete_goal():
    global session_memory
    data = request.json or {}
    goal = data.get("goal")
    goals = session_memory.get("suggested_goals", [])
    if goal in goals:
        goals.remove(goal)
        session_memory["suggested_goals"] = goals
        save_historical_memory(session_memory)
        return jsonify({"success": True, "goals": goals})
    return jsonify({"success": False, "error": "Goal not found"}), 404

@app.route("/api/add_goal", methods=["POST"])
def add_goal():
    global session_memory
    data = request.json or {}
    goal = data.get("goal")
    if goal:
        goals = session_memory.setdefault("suggested_goals", [])
        if goal not in goals:
            goals.append(goal)
            save_historical_memory(session_memory)
        return jsonify({"success": True, "goals": goals})
    return jsonify({"success": False, "error": "Invalid goal"}), 400

@app.route("/api/generate_dashboard_insight", methods=["GET"])
def generate_dashboard_insight():
    global current_session, session_memory, client
    if not client:
        return jsonify({"insight": "No AI client key detected. Please configure GROQ_API_KEY in your system environment."})
    
    # Generate insight based on session telemetry
    total_focus = current_session.get("focus_seconds", 0)
    total_distract = current_session.get("distract_seconds", 0)
    
    prompt = f"""
    You are Raphael, an elite caring cognitive advisor. The user is looking at their ADHD Focus Dashboard.
    Analyze their workspace session telemetry:
    - User Name: {get_user_name() or "User"}
    - Total Focus Time: {total_focus} seconds
    - Total Distraction Time: {total_distract} seconds
    - Open Windows and durations: {json.dumps(current_session.get("window_durations", {}))}
    - Custom Rules: {json.dumps(session_memory.get("custom_rules", []))}
    
    Provide 3 bullet points:
    1. "OBSERVATION": An analytical observation of their focus patterns during this session.
    2. "IMPROVEMENT": A direct suggestion on how they can improve their focus or minimize distractions.
    3. "NEXT GOAL": A recommended milestone or goal they should pursue right now.
    
    Be encouraging, warm, highly analytical, and sardonically witty if they have been distracted, but overall supportive. Keep the text concise and professional.
    """
    try:
        completion = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.1-8b-instant"
        )
        insight = completion.choices[0].message.content.strip()
        # Cache the latest insight in the session data
        current_session.setdefault("ai_insights", []).append({
            "timestamp": time.time(),
            "text": insight
        })
        save_session_history(history_store)
        return jsonify({"insight": insight})
    except Exception as e:
        return jsonify({"insight": f"Unable to generate cognitive insights at this time: {str(e)}"}), 500


def periodic_memory_saver():
    while True:
        time.sleep(300)
        try:
            update_persistent_memory_on_disk()
        except: pass

if __name__ == "__main__":
    threading.Thread(target=timeline_seconds_evaluator, daemon=True).start()
    threading.Thread(target=proactive_coaching_interrupter, daemon=True).start()
    threading.Thread(target=production_ai_loop, daemon=True).start()
    threading.Thread(target=periodic_memory_saver, daemon=True).start()
    app.run(port=5757, host="127.0.0.1", debug=False)
