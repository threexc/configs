#!/usr/bin/env python3
"""One-time + idempotent setup for lei/notmuch/aerc mail stack.
Config: ~/.config/lei-setup/config.toml (override via LEI_SETUP_CONFIG env var).
"""
import argparse
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:
    print("tomllib unavailable — Python 3.11+ required, or `pip install tomli --break-system-packages`"
          " and swap the import to `import tomli as tomllib`.", file=sys.stderr)
    sys.exit(1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-lei",
        action="store_true",
        help="Skip lei init/backfill and notmuch indexing. "
             "Use when you only want to (re)apply the aerc/pass/git/systemd config steps.",
    )
    return parser.parse_args()


def run(cmd: list[str], retries: int = 3, backoff: float = 5.0, **kwargs) -> subprocess.CompletedProcess:
    print(f"+ {' '.join(shlex.quote(c) for c in cmd)}")
    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            return subprocess.run(cmd, check=True, **kwargs)
        except subprocess.CalledProcessError as e:
            last_exc = e
            if attempt < retries:
                print(f"  retry {attempt}/{retries} after failure (exit {e.returncode}), "
                      f"sleeping {backoff}s...")
                time.sleep(backoff)
    raise last_exc


def load_config() -> dict:
    config_path = Path(os.environ.get(
        "LEI_SETUP_CONFIG", Path.home() / ".config/lei-setup/config.toml"
    ))
    if not config_path.is_file():
        sys.exit(f"Config not found at {config_path}. Copy the template there "
                  f"(or set LEI_SETUP_CONFIG) and edit it first.")
    with config_path.open("rb") as f:
        cfg = tomllib.load(f)

    required = {
        ("gpg", "key_id"), ("gpg", "cache_ttl_seconds"),
        ("gmail", "work_address"),
        ("lei", "start_date"), ("lei", "mail_root"), ("lei", "lists"),
    }
    for section, key in required:
        if key not in cfg.get(section, {}):
            sys.exit(f"Missing [{section}] {key} in {config_path}")
    if not cfg["lei"]["lists"]:
        sys.exit(f"[lei] lists is empty in {config_path}")

    cfg["lei"]["mail_root"] = str(Path(cfg["lei"]["mail_root"]).expanduser())
    return cfg


def step_lei(cfg: dict, mail_root: Path) -> list[str]:
    lists_dir = mail_root / "lists"
    lists_dir.mkdir(parents=True, exist_ok=True)

    run(["lei", "init", str(mail_root / "lei")])

    failed = []
    for name in cfg["lei"]["lists"]:
        print(f"=== lei backfill: {name} ===")
        try:
            run([
                "lei", "q",
                f"--only=https://lore.kernel.org/{name}/",
                f"--output={lists_dir / name}",
                "--dedupe=mid",
                "--threads",
                "--augment",
                f"rt:{cfg['lei']['start_date']}..",
            ])
        except subprocess.CalledProcessError as e:
            print(f"  !! {name} failed after retries (exit {e.returncode}), continuing")
            failed.append(name)

    return failed


def step_notmuch(cfg: dict, mail_root: Path) -> None:
    notmuch_dir = Path.home() / ".config/notmuch/default"
    notmuch_dir.mkdir(parents=True, exist_ok=True)
    config_path = notmuch_dir / "config"

    if not config_path.exists():
        config_path.write_text(f"""[database]
path={mail_root}

[user]
name={cfg['user']['name']}
primary_email={cfg['gmail']['work_address']}

[new]
tags=unread;
ignore=

[search]
exclude_tags=deleted;spam;

[crypto]
gpg_path=gpg
""")

    run(["notmuch", "new"])


def step_systemd_timer(cfg: dict, mail_root: Path) -> None:
    lists_dir = mail_root / "lists"
    unit_dir = Path.home() / ".config/systemd/user"
    unit_dir.mkdir(parents=True, exist_ok=True)

    lei_up_chain = " && ".join(
        f"lei up {shlex.quote(str(lists_dir / name))}" for name in cfg["lei"]["lists"]
    )
    exec_start = f"/bin/bash -c '{lei_up_chain} && notmuch new'"

    (unit_dir / "lei-up.service").write_text(f"""[Unit]
Description=Refresh lei mailing list pulls

[Service]
Type=oneshot
ExecStart={exec_start}
""")

    (unit_dir / "lei-up.timer").write_text("""[Unit]
Description=Run lei-up hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
""")

    run(["systemctl", "--user", "daemon-reload"])
    run(["systemctl", "--user", "enable", "--now", "lei-up.timer"])


def step_gpg_agent(cfg: dict) -> None:
    gnupg_dir = Path.home() / ".gnupg"
    gnupg_dir.mkdir(parents=True, exist_ok=True)
    conf_path = gnupg_dir / "gpg-agent.conf"
    ttl = cfg["gpg"]["cache_ttl_seconds"]

    existing = conf_path.read_text() if conf_path.exists() else ""
    lines_to_add = []
    if "default-cache-ttl" not in existing:
        lines_to_add.append(f"default-cache-ttl {ttl}")
    if "max-cache-ttl" not in existing:
        lines_to_add.append(f"max-cache-ttl {ttl}")
    if lines_to_add:
        with conf_path.open("a") as f:
            f.write("\n".join(lines_to_add) + "\n")

    run(["gpgconf", "--kill", "gpg-agent"])


def step_pass(cfg: dict) -> None:
    store_dir = Path.home() / ".password-store"
    if not store_dir.is_dir():
        run(["pass", "init", cfg["gpg"]["key_id"]])

    check = subprocess.run(
        ["pass", "show", "email/gmail-work-app-password"],
        capture_output=True,
    )
    if check.returncode != 0:
        print(">>> Enter the Gmail app password when prompted:")
        run(["pass", "insert", "email/gmail-work-app-password"])


def step_pass_git_helper(cfg: dict) -> None:
    helper_dir = Path.home() / ".config/pass-git-helper"
    helper_dir.mkdir(parents=True, exist_ok=True)
    (helper_dir / "git-pass-mapping.ini").write_text(
        "[smtp.gmail.com]\ntarget = email/gmail-work-app-password\n"
    )

    run(["git", "config", "--global", "credential.helper", "!pass-git-helper $@"])
    run(["git", "config", "--global", "sendemail.smtpServer", "smtp.gmail.com"])
    run(["git", "config", "--global", "sendemail.smtpServerPort", "587"])
    run(["git", "config", "--global", "sendemail.smtpEncryption", "tls"])
    run(["git", "config", "--global", "sendemail.smtpUser", cfg["gmail"]["work_address"]])


def step_aerc(cfg: dict, mail_root: Path) -> None:
    aerc_dir = Path.home() / ".config/aerc"
    aerc_dir.mkdir(parents=True, exist_ok=True)
    addr = cfg["gmail"]["work_address"]

    (aerc_dir / "accounts.conf").write_text(f"""[lists]
source                = notmuch://{mail_root}
maildir-store         = {mail_root}
maildir-account-path  = lists
outgoing              = smtps://{addr}@smtp.gmail.com
outgoing-cred-cmd     = pass show email/gmail-work-app-password
from                  = {addr}
""")


def main() -> None:
    args = parse_args()
    cfg = load_config()
    mail_root = Path(cfg["lei"]["mail_root"])

    failed: list[str] = []
    if args.skip_lei:
        print(">>> --skip-lei set: skipping lei init/backfill")
    else:
        failed = step_lei(cfg, mail_root)

    step_notmuch(cfg, mail_root)
    step_systemd_timer(cfg, mail_root)
    step_gpg_agent(cfg)
    step_pass(cfg)
    step_pass_git_helper(cfg)
    step_aerc(cfg, mail_root)

    print("\nDone. Remaining manual steps:")
    print("  - verify Gmail's Sent folder path matches 'copy-to' in accounts.conf")
    print("  - confirm the timer fired: systemctl --user list-timers")
    print("  - test an aerc send and a git send-email once")
    if failed:
        print(f"\n!! {len(failed)} list(s) failed after retries and need a manual rerun: "
              f"{', '.join(failed)}")


if __name__ == "__main__":
    main()
