"""Kill real Godot processes after durable commands and during repeated writes."""
import os
from pathlib import Path
import random
import select
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ["godot", "--headless", "--path", str(ROOT), "--script", "res://scripts/tests/crash_recovery.gd", "--"]

def kill_writer(mode, env, delay=0):
    process = subprocess.Popen(COMMAND + [mode], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    deadline = time.monotonic() + 15
    try:
        while time.monotonic() < deadline:
            if select.select([process.stdout], [], [], 1)[0]:
                line = process.stdout.readline()
                if line.startswith("SAVED "):
                    if delay:
                        time.sleep(delay)
                    process.kill()  # SIGKILL: no pause/close/save notification.
                    process.wait(timeout=5)
                    assert process.returncode < 0
                    print(f"SIGKILL {mode}: complete")
                    return
                if not line and process.poll() is not None:
                    raise RuntimeError(f"Writer exited early: {process.returncode}")
        raise TimeoutError(mode)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait(timeout=5)

def verify(mode, env):
    result = subprocess.run(COMMAND + [mode], env=env, capture_output=True, text=True, timeout=15)
    print(result.stdout.strip())
    assert result.returncode == 0, result.stderr

with tempfile.TemporaryDirectory(prefix="mutant-garden-crash-") as directory:
    env = os.environ.copy()
    for suffix, variable in [("data", "XDG_DATA_HOME"), ("config", "XDG_CONFIG_HOME"), ("cache", "XDG_CACHE_HOME")]:
        env[variable] = str(Path(directory) / suffix)
    kill_writer("plant", env)
    kill_writer("harvest", env)
    verify("verify", env)
    rng = random.Random(7501)
    for _ in range(6):
        kill_writer("spam", env, rng.uniform(.005, .04))
        verify("invariant", env)
print("CRASH RECOVERY: 8 SIGKILL scenarios, PASS")
