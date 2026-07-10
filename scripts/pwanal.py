"""
Bitwarden Vault Analyzer — rbw Edition
---------------------------------------
Requirements:
    pip install pandas
    rbw (https://github.com/doy/rbw), configured and logged in against
    the Bitwarden EU cloud:
        rbw config set email you@example.com
        rbw config set base_url https://api.bitwarden.eu
        rbw config set identity_url https://identity.bitwarden.eu
        rbw register   # personal API key, needed once to avoid bot detection
        rbw login

Pulls the vault straight from rbw (syncing first), no manual export step.
"""

import re
import json
import argparse
import subprocess
from collections import Counter

import pandas as pd


# ---------------------------------------------------------------------------
# Masking
# ---------------------------------------------------------------------------

def mask_string(s):
    """Masks a string to hide sensitive info, leaving only first and last characters."""
    if not isinstance(s, str) or not s:
        return ""
    if len(s) <= 2:
        return "*" * len(s)
    return s[0] + "*" * (len(s) - 2) + s[-1]


# ---------------------------------------------------------------------------
# Password structure classification
# ---------------------------------------------------------------------------

KEYBOARD_WALKS = [
    'qwerty', 'qwert', 'asdfgh', 'asdfg', 'asdf', 'zxcvbn', 'zxcvb',
    '123456', '12345', '23456', '34567', '45678', '56789', '98765', '87654',
]

STRUCTURE_LABELS = {
    "passphrase":        "Passphrase          (e.g. Asd-Basd, AsdBasd, correct-horse)",
    "standard_pattern":  "Standard pattern    (e.g. Password123!, Summer2024)",
    "random":            "Random/high-entropy (e.g. xK9#mP2$!qR7)",
    "numeric_only":      "Numeric only / PIN  (e.g. 1234, 198804)",
    "alphabetic_simple": "Simple word/name    (e.g. password, sunshine)",
    "keyboard_walk":     "Keyboard walk       (e.g. qwerty123, asdf1234)",
    "other":             "Other",
}


def classify_password_structure(password: str) -> str:
    """Classify a password into a structural category."""
    if not password:
        return "other"

    pw_lower = password.lower()

    # 1. Numeric only (PIN / date)
    if password.isdigit():
        return "numeric_only"

    # 2. Keyboard walk pattern
    for walk in KEYBOARD_WALKS:
        if walk in pw_lower:
            return "keyboard_walk"

    # 3. Passphrase — separator-based (Asd-Basd, correct_horse_battery)
    sep_parts = re.split(r'[-_.\s]+', password)
    if len(sep_parts) >= 2:
        word_parts = [p for p in sep_parts if re.match(r'^[a-zA-Z]{3,}$', p)]
        if len(word_parts) >= 2 and len(word_parts) / len(sep_parts) >= 0.6:
            return "passphrase"

    # 4. Passphrase — CamelCase (AsdBasd, BlueHorsePurple)
    camel_words = re.findall(r'[A-Z][a-z]{2,}', password)
    if len(camel_words) >= 2:
        camel_coverage = sum(len(w) for w in camel_words) / len(password)
        if camel_coverage >= 0.7:
            return "passphrase"

    # 5. Standard pattern: [optional_special] Word Numbers [optional_special]
    #    e.g. Password123!, Admin2024, hello99!, Summer@2024
    if re.match(r'^[^a-zA-Z0-9]{0,2}[A-Za-z]{3,15}[0-9]{1,8}[^a-zA-Z0-9]{0,3}$', password):
        return "standard_pattern"
    if re.match(r'^[^a-zA-Z0-9]{0,2}[A-Za-z]{3,15}[^a-zA-Z0-9]{1,3}[0-9]{1,8}[^a-zA-Z0-9]{0,2}$', password):
        return "standard_pattern"

    # 6. Random / high-entropy: multiple char classes + high unique-char ratio
    char_classes = sum([
        bool(re.search(r'[A-Z]', password)),
        bool(re.search(r'[a-z]', password)),
        bool(re.search(r'[0-9]', password)),
        bool(re.search(r'[^a-zA-Z0-9]', password)),
    ])
    unique_ratio = len(set(password)) / len(password)

    if char_classes >= 3 and unique_ratio >= 0.55:
        return "random"
    if char_classes >= 2 and len(password) >= 14 and unique_ratio >= 0.65:
        return "random"

    # 7. Simple word (only letters, no digits or specials)
    if re.match(r'^[a-zA-Z]+$', password):
        return "alphabetic_simple"

    return "other"


# ---------------------------------------------------------------------------
# rbw integration
# ---------------------------------------------------------------------------

def _rbw(*args: str) -> str:
    try:
        result = subprocess.run(
            ["rbw", *args], capture_output=True, text=True, check=False,
        )
    except FileNotFoundError:
        raise RuntimeError("rbw is not installed or not on PATH.")
    if result.returncode != 0:
        raise RuntimeError(f"rbw {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def ensure_unlocked() -> None:
    if subprocess.run(["rbw", "unlocked"], capture_output=True).returncode != 0:
        print("Vault is locked — check for a pinentry prompt to unlock it.")
        _rbw("unlock")


def fetch_vault_dataframe() -> pd.DataFrame:
    """Sync with the Bitwarden EU cloud and pull all login items via rbw."""
    print("Syncing vault...")
    _rbw("sync")

    entries = json.loads(_rbw("list", "--raw"))
    login_ids = [e["id"] for e in entries if e.get("type") == "Login"]

    rows = []
    for item_id in login_ids:
        item = json.loads(_rbw("get", "--raw", item_id))
        data = item.get("data") or {}
        uris = data.get("uris") or []
        rows.append({
            "name":           item.get("name", ""),
            "login_uri":      uris[0] if uris else "",
            "login_username": data.get("username") or "",
            "login_password": data.get("password") or "",
        })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Analysis
# ---------------------------------------------------------------------------

def analyze_bitwarden_vault(obfuscate=False):
    ensure_unlocked()
    df = fetch_vault_dataframe()
    total_logins = len(df)

    # Filter out entries without a login_uri
    df = df[df["login_uri"].notna() & (df["login_uri"].str.strip() != "")]
    total_entries = len(df)
    excluded_no_uri = total_logins - total_entries

    if total_entries == 0:
        print("No entries found with a valid login_uri.")
        return

    df_filled = df.fillna({"login_username": "", "login_password": ""})

    # Blank username/password shouldn't count as a "reused" identity/secret -
    # it just means several unrelated entries happen to have that field empty.
    named  = df_filled[df_filled["login_username"] != ""]
    keyed  = df_filled[df_filled["login_password"] != ""]
    paired = df_filled[(df_filled["login_username"] != "") & (df_filled["login_password"] != "")]

    total_unique_websites  = df["name"].nunique()
    total_unique_usernames = named["login_username"].nunique()
    total_unique_passwords = keyed["login_password"].nunique()

    avg_entries_per_username = len(named) / total_unique_usernames if total_unique_usernames else 0
    avg_entries_per_password = len(keyed) / total_unique_passwords if total_unique_passwords else 0

    unique_pairs_count = len(paired.groupby(["login_username", "login_password"]))
    unique_pairs_ratio = unique_pairs_count / len(paired) if len(paired) else 0

    top_5_usernames = (named["login_username"].value_counts(normalize=True) * 100).head(5)
    top_5_passwords = (keyed["login_password"].value_counts(normalize=True) * 100).head(5)
    combo_counts    = paired.groupby(["login_username", "login_password"]).size().sort_values(ascending=False)
    top_5_combos    = combo_counts.head(5)

    print(f"Total entries (that has a login_uri): {total_entries}")
    print(f"Excluded (no login_uri): {excluded_no_uri} (out of {total_logins} total login items)")
    print(f"Total unique websites based on 'name': {total_unique_websites}")
    print(f"Total number of unique 'login_username' used: {total_unique_usernames}")
    print(f"Total number of unique 'login_password' used: {total_unique_passwords}")
    print(f"Average count of entries per username: {avg_entries_per_username:.2f}")
    print(f"Average count of entries per password: {avg_entries_per_password:.2f}")
    print(f"Total count of unique username-password pairs: {unique_pairs_count}")
    print(f"Total count of unique pairs / total count of pairs: {unique_pairs_ratio:.2%}\n")

    print(f"Top 5 most used usernames with their % of entries that have a username ({len(named)}):")
    for username, percentage in top_5_usernames.items():
        display_user = mask_string(username) if obfuscate else username
        print(f"  - {display_user}: {percentage:.2f}%")

    print(f"\nTop 5 most used passwords with their % of entries that have a password ({len(keyed)}):")
    for password, percentage in top_5_passwords.items():
        display_pass = mask_string(password) if obfuscate else password
        print(f"  - {display_pass}: {percentage:.2f}%")

    print(f"\nTop 5 most used username-password combinations with their % of entries that have both ({len(paired)}):")
    for (username, password), count in top_5_combos.items():
        display_user = mask_string(username) if obfuscate else username
        display_pass = mask_string(password) if obfuscate else password
        percentage   = (count / len(paired)) * 100 if len(paired) else 0
        print(f"  - User: '{display_user}' | Pass: '{display_pass}' -> {percentage:.2f}% ({count} total uses)")

    # Password structure breakdown (counted over unique, non-blank password values)
    unique_passwords = keyed["login_password"].unique()
    structure_counts = Counter(classify_password_structure(pw) for pw in unique_passwords)
    total_unique_pw = len(unique_passwords)

    print("\nPassword structure breakdown (by unique password values):")
    for key, label in STRUCTURE_LABELS.items():
        count = structure_counts.get(key, 0)
        pct = (count / total_unique_pw * 100) if total_unique_pw else 0
        print(f"  {label}: {pct:.1f}% ({count})")

    # Password length (by unique password values)
    SHORT_PW_THRESHOLD = 12
    lengths = [len(pw) for pw in unique_passwords]
    short_count = sum(1 for n in lengths if n < SHORT_PW_THRESHOLD)

    print(f"\nPassword length (by unique password values, {total_unique_pw} total):")
    print(f"  Min: {min(lengths)}  Max: {max(lengths)}  Avg: {sum(lengths) / len(lengths):.1f}")
    print(f"  Shorter than {SHORT_PW_THRESHOLD} chars: {short_count} ({short_count / total_unique_pw * 100:.1f}%)")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Analyze your live Bitwarden vault (via rbw) with optional data masking."
    )
    parser.add_argument(
        "--obfuscate",
        action="store_true",
        help="Obfuscate usernames and passwords in the printed output.",
    )
    args = parser.parse_args()
    analyze_bitwarden_vault(obfuscate=args.obfuscate)
