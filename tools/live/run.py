"""Own a disposable Compose project and helper process for explicit live tests."""

import os
import pathlib
import shlex
import socket
import subprocess
import sys
import time
import uuid

root = pathlib.Path(__file__).resolve().parents[2]
base = int(os.environ.get("DIMSEDASH_PEER_PORT", "4250"))
orthanc = int(os.environ.get("DIMSEDASH_ORTHANC_PORT", "4242"))
ports = [orthanc, *range(base, base + 7)]
if len(set(ports)) != len(ports) or any(not 1024 <= p <= 65535 for p in ports):
    sys.exit("Fixture ports must be distinct and between 1024 and 65535.")
# Never mistake an unrelated process for a fixture or stop a pre-existing service.
for port in ports:
    with socket.socket() as probe:
        probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            probe.bind(("127.0.0.1", port))
        except OSError:
            sys.exit(f"Fixture port {port} is occupied. Choose another port range.")
project = "dimsedash-live-" + uuid.uuid4().hex[:10]
compose = [
    "docker",
    "compose",
    "-p",
    project,
    "-f",
    str(root / "tools/live/compose.yaml"),
]
peer = None
try:
    subprocess.run([*compose, "up", "-d", "--wait"], check=True, cwd=root)
    peer = subprocess.Popen(
        [
            "uv",
            "run",
            "--with",
            "pydicom==3.0.2",
            "--with",
            "pynetdicom==3.0.4",
            "python",
            str(root / "tools/live/peers.py"),
            "--base-port",
            str(base),
        ],
        cwd=root,
        start_new_session=True,
    )
    deadline = time.monotonic() + 60
    for port in ports:
        while True:
            if peer.poll() is not None:
                raise RuntimeError("Fixture helper exited before readiness.")
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.3):
                    break
            except OSError:
                if time.monotonic() >= deadline:
                    raise TimeoutError(f"Fixture port {port} was not ready.")
                time.sleep(0.1)
    flutter = shlex.split(os.environ.get("FLUTTER_COMMAND", "fvm flutter"))
    command = [
        *flutter,
        "test",
        "tests/live",
        "--no-pub",
        f"--dart-define=PEER_PORT={base}",
        f"--dart-define=ORTHANC_PORT={orthanc}",
    ]
    if "--native" in sys.argv:
        device = "macos" if sys.platform == "darwin" else "linux"
        command = [
            *flutter,
            "test",
            "integration_test/echo_flow_test.dart",
            "-d",
            device,
            "--no-pub",
            f"--dart-define=PEER_PORT={base}",
            f"--dart-define=ORTHANC_PORT={orthanc}",
        ]
    if "--release" in sys.argv:
        device = "macos" if sys.platform == "darwin" else "linux"
        command = [
            *flutter,
            "build",
            device,
            "--release",
            "--target=tools/live/release_probe.dart",
            "--no-pub",
            f"--dart-define=ORTHANC_PORT={orthanc}",
        ]
        subprocess.run(command, check=True, cwd=root, timeout=240)
        binary = root / (
            "build/macos/Build/Products/Release/DimseDash.app/Contents/MacOS/DimseDash"
            if device == "macos"
            else "build/linux/x64/release/bundle/dimsedash"
        )
        result = subprocess.run(
            [str(binary)],
            check=False,
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=30,
        )
        print(result.stdout)
        result.check_returncode()
        if "DIMSEDASH_RELEASE_ECHO_PASS" not in result.stdout:
            raise RuntimeError("Release probe did not confirm Echo success.")
    else:
        subprocess.run(command, check=True, cwd=root)

finally:
    if peer is not None and peer.poll() is None:
        import signal

        os.killpg(peer.pid, signal.SIGTERM)
        try:
            peer.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(peer.pid, signal.SIGKILL)
            peer.wait()
    subprocess.run(
        [*compose, "down", "--volumes", "--remove-orphans"], check=True, cwd=root
    )
