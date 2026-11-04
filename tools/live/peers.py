"""Loopback synthetic DIMSE failure peers with bounded Query fixtures."""

import argparse
import signal
import socket
import threading
import time
from pynetdicom import AE, evt
from pynetdicom.sop_class import Verification, CTImageStorage, StudyRootQueryRetrieveInformationModelFind
from pydicom.dataset import Dataset

parser = argparse.ArgumentParser()
parser.add_argument("--base-port", type=int, default=4250)
parser.add_argument("--echo-delay", type=float, default=3)
args = parser.parse_args()
servers = []
listeners = []
stop = threading.Event()


def echo(event):
    return 0x0000


def delayed_echo(event):
    time.sleep(args.echo_delay)
    return 0x0000


def abort_echo(event):
    event.assoc.abort()
    return 0x0000


def find_response(event):
    ds = Dataset()
    ds.QueryRetrieveLevel = event.identifier.QueryRetrieveLevel
    ds.StudyInstanceUID = "2.25.8000.1"
    ds.PatientID = "SYNTH-1"
    ds.PatientName = "SYNTHETIC^1"
    yield 0xFF01, ds
    yield 0x0000, None


def find_failure(event):
    yield next(find_response(event))
    yield 0xA700, None


def find_delayed(event):
    yield next(find_response(event))
    for _ in range(50):
        if event.is_cancelled:
            yield 0xFE00, None
            return
        time.sleep(0.02)
    yield 0x0000, None


def find_abort(event):
    yield next(find_response(event))
    event.assoc.abort()


def find_oversize(event):
    ds = Dataset()
    ds.StudyInstanceUID = "2.25.8000.1"
    ds.add_new(0x0040A160, "UT", "X" * (1024 * 1024 + 1))
    yield 0xFF00, ds


def find_charset(event):
    ds = Dataset()
    ds.SpecificCharacterSet = "ISO 2022 IR 87"
    ds.StudyInstanceUID = "2.25.8000.1"
    ds.PatientName = "SYNTHETIC"
    yield 0xFF00, ds


def find_missing(event):
    ds = Dataset()
    ds.PatientName = "SYNTHETIC^NO_UID"
    yield 0xFF00, ds


def find_ignored(event):
    yield next(find_response(event))
    time.sleep(3)
    yield 0x0000, None


def serve(offset, handler=echo, context=Verification, strict=False, find_handler=find_response):
    ae = AE(ae_title="PACS_AET")
    ae.add_supported_context(context)
    if context == Verification:
        ae.add_supported_context(StudyRootQueryRetrieveInformationModelFind)
    ae.require_called_aet = strict
    servers.append(
        ae.start_server(
            ("127.0.0.1", args.base_port + offset),
            block=False,
            evt_handlers=[(evt.EVT_C_ECHO, handler), (evt.EVT_C_FIND, find_handler)],
        )
    )


serve(0, strict=True)
serve(1, context=CTImageStorage)
serve(3, handler=delayed_echo)
serve(4, handler=abort_echo)
serve(6)  # Backend for release-failure proxy.
serve(7)
serve(8, find_handler=find_failure)
serve(9, find_handler=find_delayed)
serve(10, find_handler=find_abort)
serve(11, find_handler=find_oversize)
serve(12, find_handler=find_charset)
serve(13, find_handler=find_missing)
serve(14, find_handler=find_ignored)


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
