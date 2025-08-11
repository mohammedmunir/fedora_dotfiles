
#!/bin/bash
set -e

# One-shot project setup for KivyMD To-Do + Pomodoro app
PROJECT_DIR="${PWD}/my_todo_app"
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

echo "Creating project in: ${PROJECT_DIR}"

# ---------------------------
# 1) main.py (KivyMD app)
# ---------------------------
cat > main.py <<'PY'
"""
main.py - KivyMD To-Do + Pomodoro App
Features:
- Add / remove / move up & down / skip to tomorrow / history / show hidden
- Toggleable Pomodoro timer
- Saves to data.json
- Simple debug logging (DEBUG = True)
"""
from kivy.lang import Builder
from kivy.clock import Clock
from kivy.metrics import dp
from kivy.core.window import Window
from kivy.properties import StringProperty
from kivymd.app import MDApp
from kivymd.uix.snackbar import Snackbar
import json, os, time
from datetime import datetime

DEBUG = True
DATA_FILE = "data.json"
KV_FILE = "todo.kv"

def dbg(msg):
    if DEBUG:
        print(f"[DEBUG] {msg}")

def today_str():
    return datetime.now().strftime("%Y-%m-%d")

def ensure_data():
    if not os.path.exists(DATA_FILE):
        default = {"date": today_str(), "tasks": [], "tomorrow": [], "history": []}
        with open(DATA_FILE, "w") as f:
            json.dump(default, f, indent=2)
        dbg("Created default data.json")

def load_data():
    with open(DATA_FILE, "r") as f:
        d = json.load(f)
    dbg(f"Loaded data: {d.get('date')} tasks={len(d.get('tasks',[]))} tom={len(d.get('tomorrow',[]))}")
    return d

def save_data(data):
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)
    dbg("Saved data.json")

class TodoApp(MDApp):
    status_text = StringProperty("")

    def build(self):
        # load KV layout
        Builder.load_file(KV_FILE)
        ensure_data()
        self.data = load_data()
        self.rotate_if_needed()
        # keep window small on desktop: center horizontally, near bottom
        try:
            Window.size = (420, 640)
            screen_w, screen_h = Window.system_size
            Window.left = int((screen_w - Window.width) / 2)
            Window.top = int(screen_h - Window.height - 50)
        except Exception as e:
            dbg(f"Window positioning not applied: {e}")
        return Builder.get_root()

    def on_start(self):
        self.root.ids.entry.text = ""
        self.refresh_tasks()
        Clock.schedule_interval(self.check_date_rotation, 30)  # every 30s

    # -------------------
    # Data helpers
    # -------------------
    def rotate_if_needed(self):
        if self.data.get("date") != today_str():
            dbg("Rotating 'tomorrow' into today")
            self.data["date"] = today_str()
            tom = self.data.get("tomorrow", [])
            if tom:
                self.data.setdefault("tasks", []).extend(tom)
                self.data["tomorrow"] = []
            for t in self.data.get("tasks", []):
                t["done"] = False
            save_data(self.data)

    def check_date_rotation(self, dt):
        old_date = self.data.get("date")
        if old_date != today_str():
            self.rotate_if_needed()
            self.refresh_tasks()

    # -------------------
    # Task operations
    # -------------------
    def add_task(self, text=None):
        if text is None:
            text = self.root.ids.entry.text.strip()
        if not text:
            Snackbar(text="Task cannot be empty").open()
            return
        tid = max([t.get("id",0) for t in self.data.get("tasks",[])+self.data.get("tomorrow",[])] + [0]) + 1
        task = {"id": tid, "text": text, "done": False, "hidden": False}
        self.data.setdefault("tasks", []).append(task)
        # add to history
        if text not in self.data.setdefault("history", []):
            self.data["history"].append(text)
        save_data(self.data)
        self.root.ids.entry.text = ""
        self.refresh_tasks()
        dbg(f"Added task: {text}")

    def add_from_history(self, text):
        if not text:
            return
        self.add_task(text)

    def toggle_done(self, tid):
        for t in self.data.get("tasks", []):
            if t["id"] == tid:
                t["done"] = not t.get("done", False)
                dbg(f"Toggled done {tid} -> {t['done']}")
                break
        save_data(self.data)
        self.refresh_tasks()

    def delete_task(self, tid):
        self.data["tasks"] = [t for t in self.data.get("tasks", []) if t["id"] != tid]
        save_data(self.data)
        self.refresh_tasks()
        dbg(f"Deleted {tid}")

    def hide_task(self, tid):
        for t in self.data.get("tasks", []):
            if t["id"] == tid:
                t["hidden"] = True
                break
        save_data(self.data)
        self.refresh_tasks()

    def unhide_task(self, tid):
        for t in self.data.get("tasks", []):
            if t["id"] == tid:
                t["hidden"] = False
                break
        save_data(self.data)
        self.refresh_tasks()

    def skip_to_tomorrow(self, tid):
        for i, t in enumerate(self.data.get("tasks", [])):
            if t["id"] == tid:
                item = self.data["tasks"].pop(i)
                item["done"] = False
                item["hidden"] = False
                self.data.setdefault("tomorrow", []).append(item)
                save_data(self.data)
                self.refresh_tasks()
                dbg(f"Skipped {tid} to tomorrow")
                return

    def move_task(self, tid, direction):
        tasks = self.data.get("tasks", [])
        for i, t in enumerate(tasks):
            if t["id"] == tid:
                j = i + direction
                if 0 <= j < len(tasks):
                    tasks[i], tasks[j] = tasks[j], tasks[i]
                    save_data(self.data)
                    self.refresh_tasks()
                    dbg(f"Moved {tid} {'up' if direction<0 else 'down'}")
                return

    # -------------------
    # UI refresh
    # -------------------
    def refresh_tasks(self):
        md_list = self.root.ids.task_list
        md_list.clear_widgets()
        visible = [t for t in self.data.get("tasks", []) if not t.get("hidden", False)]
        # highlight first incomplete
        next_found = False
        done_count = 0
        for t in visible:
            item = self._build_task_item(t, highlight= (not t.get("done") and not next_found))
            md_list.add_widget(item)
            if not next_found and not t.get("done"):
                next_found = True
            if t.get("done"):
                done_count += 1
        total = len(visible)
        percent = int((done_count/total)*100) if total else 0
        self.root.ids.progress.value = percent
        self.root.ids.progress_label.text = f"{done_count}/{total} done ({percent}%)"

    def _build_task_item(self, t, highlight=False):
        from kivymd.uix.list import OneLineAvatarIconListItem
        from kivymd.uix.selectioncontrol import MDCheckbox
        from kivymd.uix.boxlayout import MDBoxLayout
        from kivymd.uix.button import MDIconButton

        li = OneLineAvatarIconListItem(text=t["text"], on_release=lambda x=None: self.toggle_done(t["id"]))
        # left checkbox
        chk = MDCheckbox(size_hint=(None,None), size=(dp(24), dp(24)))
        chk.active = t.get("done", False)
        chk.bind(active=lambda inst, val: self.toggle_done(t["id"]))
        li.add_widget(chk)
        # right controls
        box = MDBoxLayout(size_hint=(None,None), width=dp(180))
        up = MDIconButton(icon="arrow-up", on_release=lambda x: self.move_task(t["id"], -1))
        down = MDIconButton(icon="arrow-down", on_release=lambda x: self.move_task(t["id"], 1))
        skip = MDIconButton(icon="skip-next", on_release=lambda x: self.skip_to_tomorrow(t["id"]))
        hide = MDIconButton(icon="eye-off" if not t.get("hidden") else "eye", on_release=lambda x: self.hide_task(t["id"]) if not t.get("hidden") else self.unhide_task(t["id"]))
        delete = MDIconButton(icon="delete", on_release=lambda x: self.delete_task(t["id"]))
        box.add_widget(up); box.add_widget(down); box.add_widget(skip); box.add_widget(hide); box.add_widget(delete)
        li.add_widget(box)
        if t.get("done"):
            li.md_bg_color = (0.82, 0.95, 0.85, 1)  # light green
        else:
            if highlight:
                li.md_bg_color = (1, 0.97, 0.85, 1)  # light yellow
            else:
                li.md_bg_color = (1,1,1,1)
        return li

    # -------------------
    # History dialog
    # -------------------
    def open_history(self):
        items = self.data.get("history", [])
        if not items:
            Snackbar(text="History is empty").open()
            return
        from kivymd.uix.dialog import MDDialog
        from kivymd.uix.button import MDRaisedButton
        btns = [MDRaisedButton(text=i, on_release=lambda inst, t=i: self._history_pick(t)) for i in items]
        dlg = MDDialog(title="History", size_hint=(0.8, None), items=btns)
        dlg.open()

    def _history_pick(self, text):
        self.add_task(text)

    # -------------------
    # Pomodoro
    # -------------------
    def toggle_timer_ui(self):
        area = self.root.ids.timer_area
        if area.height == 0:
            area.height = dp(48)
        else:
            area.height = 0

    def start_pomodoro(self):
        if getattr(self, "pomodoro_running", False):
            return
        self.pomodoro_running = True
        self.pomodoro_seconds = 25*60
        self.update_timer()
        dbg("Pomodoro started")

    def stop_pomodoro(self):
        self.pomodoro_running = False
        if getattr(self, "pomodoro_event", None):
            self.pomodoro_event.cancel()
            self.pomodoro_event = None
        self.root.ids.timer_label.text = "25:00"
        dbg("Pomodoro stopped")

    def update_timer(self, *args):
        if not getattr(self, "pomodoro_running", False):
            return
        mins = self.pomodoro_seconds // 60
        secs = self.pomodoro_seconds % 60
        self.root.ids.timer_label.text = f"{mins:02d}:{secs:02d}"
        if self.pomodoro_seconds <= 0:
            self.pomodoro_running = False
            Snackbar(text="Pomodoro complete - take a break").open()
            dbg("Pomodoro complete")
            return
        self.pomodoro_seconds -= 1
        self.pomodoro_event = Clock.schedule_once(self.update_timer, 1)

if __name__ == "__main__":
    TodoApp().run()
PY

# ---------------------------
# 2) KV file layout
# ---------------------------
cat > todo.kv <<'KV'
#:import dp kivy.metrics.dp
BoxLayout:
    orientation: "vertical"
    padding: dp(8)
    spacing: dp(6)

    MDToolbar:
        title: "Daily To-Do"
        elevation: 10
        left_action_items: [["menu", lambda x: None]]
        right_action_items: [["history", lambda x: app.open_history()], ["timer", lambda x: app.toggle_timer_ui()]]

    MDProgressBar:
        id: progress
        value: 0
        type: 'determinate'

    ScrollView:
        MDList:
            id: task_list

    MDBoxLayout:
        adaptive_height: True
        spacing: dp(6)
        MDTextField:
            id: entry
            hint_text: "Add a task"
            on_text_validate: app.add_task(entry.text)

        MDRaisedButton:
            text: "Add"
            on_release: app.add_task(entry.text)

    MDBoxLayout:
        adaptive_height: True
        spacing: dp(6)
        MDFlatButton:
            text: "Clear Completed"
            on_release: app.data["tasks"][:] = [t for t in app.data.get("tasks",[]) if not t.get("done",False)]; app.refresh_tasks(); app.save_data(app.data)
        MDFlatButton:
            text: "Reset Day"
            on_release: app.rotate_if_needed(); app.refresh_tasks(); app.save_data(app.data)

    MDBoxLayout:
        id: timer_area
        size_hint_y: None
        height: 0
        spacing: dp(6)
        padding: dp(6)
        MDLabel:
            id: timer_label
            text: "25:00"
            halign: "center"
        MDRaisedButton:
            text: "Start"
            on_release: app.start_pomodoro()
        MDRaisedButton:
            text: "Stop"
            on_release: app.stop_pomodoro()
KV

# ---------------------------
# 3) data.json default
# ---------------------------
cat > data.json <<'JSON'
{
  "date": "",
  "tasks": [],
  "tomorrow": [],
  "history": []
}
JSON

# ---------------------------
# 4) requirements.txt
# ---------------------------
cat > requirements.txt <<'REQ'
kivy
kivymd
REQ

# ---------------------------
# 5) buildozer.spec (starter)
# ---------------------------
cat > buildozer.spec <<'SPEC'
[app]
title = DailyToDo
package.name = dailytodo
package.domain = org.example
source.dir = .
source.include_exts = py,kv,png,jpg,ttf,atlas
version = 0.1
requirements = python3,kivy,kivymd
orientation = portrait
fullscreen = 0

[buildozer]
log_level = 2
warn_on_root = 0
SPEC

# ---------------------------
# 6) Dockerfile.dev (run GUI on Linux desktop via X11)
# ---------------------------
cat > Dockerfile.dev <<'DOCKDEV'
FROM python:3.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libgstreamer1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    x11-apps \
    libxcursor1 libxrandr2 libxinerama1 libxi6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app
CMD ["python", "main.py"]
DOCKDEV

# ---------------------------
# 7) Dockerfile.apk (buildozer)
# ---------------------------
cat > Dockerfile.apk <<'DOCKAPK'
FROM python:3.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-17-jdk unzip git zip wget curl \
    build-essential libffi-dev libssl-dev libsqlite3-dev zlib1g-dev \
    libncurses5-dev libgdbm-dev libbz2-dev libreadline-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir buildozer cython virtualenv

WORKDIR /app
COPY . /app
CMD ["bash"]
DOCKAPK

# ---------------------------
# 8) run_dev.sh (X11 forwarding)
# ---------------------------
cat > run_dev.sh <<'RUNDEV'
#!/bin/bash
set -e
IMAGE_NAME="kivy-dev-image"
docker build -t $IMAGE_NAME -f Dockerfile.dev .
# Allow container to use the host X server
xhost +local:docker
docker run --rm -it \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)":/app \
  $IMAGE_NAME
# revoke access
xhost -local:docker
RUNDEV
chmod +x run_dev.sh

# ---------------------------
# 9) build_android.sh (build apk)
# ---------------------------
cat > build_android.sh <<'BUILDBASH'
#!/bin/bash
set -e
IMAGE_NAME="kivy-apk-builder"
docker build -t $IMAGE_NAME -f Dockerfile.apk .
# mount project and run buildozer commands inside container
docker run --rm -it -v "$(pwd)":/app $IMAGE_NAME bash -c "
  cd /app
  if [ ! -f buildozer.spec ]; then
    buildozer init
    echo 'Please check buildozer.spec and re-run build_android.sh'
    exit 0
  fi
  buildozer -v android debug
"
echo "APK output (if successful) will be in ./bin/"
BUILDBASH
chmod +x build_android.sh

# ---------------------------
# 10) README summary
# ---------------------------
cat > README.txt <<'README'
Project: my_todo_app

Run GUI locally (Linux) using Docker with X11:
  ./run_dev.sh

Build Android APK using Docker (Buildozer):
  ./build_android.sh
  APK will be in ./bin/

To run natively on Windows or Linux without Docker:
  pip install -r requirements.txt
  python main.py

Edit buildozer.spec for package name/title before building APK.
README

echo "Setup finished. Project created at: ${PROJECT_DIR}"
echo ""
echo "Next steps:"
echo "  cd ${PROJECT_DIR}"
echo "  ./run_dev.sh          # test GUI on Linux (needs X11)"
echo "  ./build_android.sh    # builds APK (first-run buildozer may download SDK/NDK)"
echo ""
echo "Tip: edit buildozer.spec to change package id/title before building an APK."
