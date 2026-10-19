"""Loopback synthetic failure peers; no image data is accepted or generated."""

import argparse
import signal
import socket
import threading
import time
from pynetdicom import AE, evt
from pynetdicom.sop_class import Verification, CTImageStorage

parser = argparse.ArgumentParser()
parser.add_argument("--base-port", type=int, default=4250)
args = parser.parse_args()
servers = []
listeners = []
stop = threading.Event()


def echo(event):
    return 0x0000


def delayed_echo(event):
    time.sleep(3)
    return 0x0000


def abort_echo(event):
    event.assoc.abort()
    return 0x0000


def serve(offset, handler=echo, context=Verification, strict=False):
    ae = AE(ae_title="PACS_AET")
    ae.add_supported_context(context)
    ae.require_called_aet = strict
    servers.append(
        ae.start_server(
            ("127.0.0.1", args.base_port + offset),
            block=False,
            evt_handlers=[(evt.EVT_C_ECHO, handler)],
        )
    )


serve(0, strict=True)
serve(1, context=CTImageStorage)
serve(3, handler=delayed_echo)
serve(4, handler=abort_echo)
serve(6)  # Backend for release-failure proxy.


def receive_exact(conn, count):
    data = b""
    while len(data) < count:
        chunk = conn.recv(count - len(data))
        if not chunk:
            return None
        data += chunk
    return data


def stalled(conn):
    with conn:
        stop.wait(10)


def release_proxy(conn):
    with conn, socket.create_connection(("127.0.0.1", args.base_port + 6)) as peer:

        def replies():
            try:
                while data := peer.recv(65536):
                    conn.sendall(data)
            except OSError:
                pass

        threading.Thread(target=replies, daemon=True).start()
        try:
            while header := receive_exact(conn, 6):
                payload = receive_exact(conn, int.from_bytes(header[2:6], "big"))
                if payload is None:
                    return
                if header[0] == 5:  # Drop release request after a real Echo response.
                    stop.wait(10)
                    return
                peer.sendall(header + payload)
        except OSError:
            pass


def listen(offset, handler):
    listener = socket.socket()
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", args.base_port + offset))
    listener.listen()
    listeners.append(listener)

    def accept():
        while not stop.is_set():
            try:
                conn, _ = listener.accept()
            except OSError:
                return
            threading.Thread(target=handler, args=(conn,), daemon=True).start()

    threading.Thread(target=accept, daemon=True).start()


listen(2, stalled)
listen(5, release_proxy)
signal.signal(signal.SIGTERM, lambda *_: stop.set())
signal.signal(signal.SIGINT, lambda *_: stop.set())
stop.wait()
for listener in listeners:
    listener.close()
for server in servers:
    server.shutdown()
