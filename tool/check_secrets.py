"""Scan tracked and non-ignored new files without staging or scanning caches."""

import pathlib
import shutil
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
paths = (
    subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=root,
    )
    .decode()
    .split("\0")
)
with tempfile.TemporaryDirectory(prefix="dimsedash-secrets-") as temporary:
    target_root = pathlib.Path(temporary)
    for relative in set(paths) - {""}:
        source = root / relative
        if source.is_file() and not source.is_symlink():
            target = target_root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
    subprocess.run(
        ["gitleaks", "dir", "--redact", "--no-banner", str(target_root)], check=True
    )
