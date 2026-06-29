"""
Bitwarden Vault Analyzer — Password-Protected JSON Export Edition
-----------------------------------------------------------------
Requirements:
    pip install cryptography pandas
    pip install argon2-cffi   # only needed if your account uses Argon2id KDF

How to export:
    1. Go to vault.bitwarden.eu → Tools → Export Vault
    2. File Format → .json (Encrypted)
    3. Export type → Password protected   ← NOT "Account restricted"
    4. Enter a password of your choice (remember it; the script will ask for it)
    5. Save to ~/Downloads/  — filename will be bitwarden_encrypted_export_YYYYMMDDHHMMSS.json
"""

import os
import re
import glob
import json
import base64
import getpass
import argparse
from collections import Counter

import pandas as pd

from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.kdf.hkdf import HKDFExpand
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import hmac as crypto_hmac
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.exceptions import InvalidSignature


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
# Bitwarden decryption helpers
# ---------------------------------------------------------------------------

def _derive_keys(password: str, salt_b64: str, kdf_type: int, rounds: int,
                 kdf_memory=None, kdf_parallelism=None):
    """
    Derive AES-256 encryption key and HMAC-SHA256 MAC key from the export password.

    kdf_type 0 = PBKDF2-SHA256 (most accounts)
    kdf_type 1 = Argon2id       (accounts that switched to Argon2id)
    """
    # Bitwarden uses the salt string as-is (UTF-8 encoded), NOT base64-decoded.
    # It treats the salt field the same way it treats email in normal vault decryption.
    salt = salt_b64.encode("utf-8")

    if kdf_type == 0:
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=rounds,
        )
        pre_key = kdf.derive(password.encode("utf-8"))

    elif kdf_type == 1:
        try:
            from argon2.low_level import hash_secret_raw, Type
        except ImportError:
            raise ImportError(
                "Your account uses Argon2id. "
                "Install the extra dependency: pip install argon2-cffi"
            )
        pre_key = hash_secret_raw(
            secret=password.encode("utf-8"),
            salt=salt,
            time_cost=rounds,
            memory_cost=kdf_memory,      # KiB
            parallelism=kdf_parallelism,
            hash_len=32,
            type=Type.ID,
        )
    else:
        raise ValueError(f"Unknown KDF type in export: {kdf_type}")

    # HKDF-Expand: separate enc and mac keys from the single pre-key
    enc_key = HKDFExpand(algorithm=hashes.SHA256(), length=32, info=b"enc").derive(pre_key)
    mac_key = HKDFExpand(algorithm=hashes.SHA256(), length=32, info=b"mac").derive(pre_key)
    return enc_key, mac_key


def _decrypt_cipher_string(cipher_string: str, enc_key: bytes, mac_key: bytes) -> bytes:
    """
    Decrypt a Bitwarden AesCbc256_HmacSha256_B64 cipher string.
    Format: '2.<IV_b64>|<CT_b64>|<MAC_b64>'
    """
    enc_type, rest = cipher_string.split(".", 1)
    if enc_type != "2":
        raise ValueError(f"Unsupported Bitwarden encryption type: {enc_type}")

    iv_b64, ct_b64, mac_b64 = rest.split("|")
    iv  = base64.b64decode(iv_b64)
    ct  = base64.b64decode(ct_b64)
    mac = base64.b64decode(mac_b64)

    # Verify integrity before decrypting
    h = crypto_hmac.HMAC(mac_key, hashes.SHA256())
    h.update(iv + ct)
    h.verify(mac)   # raises InvalidSignature on mismatch

    # AES-256-CBC decrypt
    cipher    = Cipher(algorithms.AES(enc_key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    padded    = decryptor.update(ct) + decryptor.finalize()

    # Strip PKCS7 padding
    unpadder  = padding.PKCS7(128).unpadder()
    return unpadder.update(padded) + unpadder.finalize()


def load_vault_from_encrypted_export(filepath: str) -> dict:
    """
    Open a Bitwarden *password-protected* JSON export, prompt for the
    export password, decrypt, and return the parsed vault dict.
    """
    with open(filepath, "r", encoding="utf-8") as f:
        export = json.load(f)

    if not export.get("encrypted") or not export.get("passwordProtected"):
        raise ValueError(
            "This file is not a password-protected Bitwarden export.\n"
            "Make sure you chose 'Password protected' (not 'Account restricted') when exporting."
        )

    password = getpass.getpass("Enter the Bitwarden export password: ")

    enc_key, mac_key = _derive_keys(
        password,
        export["salt"],
        export.get("kdfType", 0),
        export["kdfIterations"],
        export.get("kdfMemory"),
        export.get("kdfParallelism"),
    )

    # Quick password check — Bitwarden embeds a known-plaintext validation field
    try:
        _decrypt_cipher_string(export["encKeyValidation_DO_NOT_EDIT"], enc_key, mac_key)
    except (InvalidSignature, Exception):
        raise ValueError("Wrong password (or the export file is corrupted).")

    plaintext = _decrypt_cipher_string(export["data"], enc_key, mac_key)
    return json.loads(plaintext.decode("utf-8"))


def vault_to_dataframe(vault: dict) -> pd.DataFrame:
    """
    Convert the decrypted vault JSON into a DataFrame with the same
    column names the old CSV-based script used.
    """
    rows = []
    for item in vault.get("items", []):
        if item.get("type") != 1:   # 1 = Login; skip cards, notes, identities
            continue
        login    = item.get("login") or {}
        uris     = login.get("uris") or []
        uri      = uris[0].get("uri", "") if uris else ""
        rows.append({
            "name":           item.get("name", ""),
            "login_uri":      uri,
            "login_username": login.get("username") or "",
            "login_password": login.get("password") or "",
        })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Analysis (same logic as before, different data source)
# ---------------------------------------------------------------------------

def analyze_bitwarden_export(obfuscate=False):
    file_pattern = "/home/richard/Downloads/bitwarden_encrypted_export_*.json"

    files = glob.glob(file_pattern)
    if not files:
        print(f"No files found matching: {file_pattern}")
        return

    latest_file = max(files, key=os.path.getmtime)
    print(f"Analyzing file: {latest_file}\n")
    print("-" * 50)

    try:
        vault = load_vault_from_encrypted_export(latest_file)
        df    = vault_to_dataframe(vault)
    except ValueError as e:
        print(f"Error: {e}")
        return
    except Exception as e:
        print(f"Unexpected error: {e}")
        return

    # Filter out entries without a login_uri
    df = df[df["login_uri"].notna() & (df["login_uri"].str.strip() != "")]
    total_entries = len(df)

    if total_entries == 0:
        print("No entries found with a valid login_uri.")
        return

    total_unique_websites  = df["name"].nunique()
    total_unique_usernames = df["login_username"].nunique()
    total_unique_passwords = df["login_password"].nunique()

    avg_entries_per_username = total_entries / total_unique_usernames if total_unique_usernames else 0
    avg_entries_per_password = total_entries / total_unique_passwords if total_unique_passwords else 0

    df_filled          = df.fillna({"login_username": "", "login_password": ""})
    unique_pairs_count = len(df_filled.groupby(["login_username", "login_password"]))
    unique_pairs_ratio = unique_pairs_count / total_entries

    top_5_usernames = df["login_username"].value_counts(normalize=True).head(5) * 100
    top_5_passwords = df["login_password"].value_counts(normalize=True).head(5) * 100
    combo_counts    = df_filled.groupby(["login_username", "login_password"]).size().sort_values(ascending=False)
    top_5_combos    = combo_counts.head(5)

    print(f"Total entries (that has a login_uri): {total_entries}")
    print(f"Total unique websites based on 'name': {total_unique_websites}")
    print(f"Total number of unique 'login_username' used: {total_unique_usernames}")
    print(f"Total number of unique 'login_password' used: {total_unique_passwords}")
    print(f"Average count of entries per username: {avg_entries_per_username:.2f}")
    print(f"Average count of entries per password: {avg_entries_per_password:.2f}")
    print(f"Total count of unique username-password pairs: {unique_pairs_count}")
    print(f"Total count of unique pairs / total count of pairs: {unique_pairs_ratio:.2%}\n")

    print("Top 5 most used usernames with their % of the total:")
    for username, percentage in top_5_usernames.items():
        display_user = mask_string(username) if obfuscate else username
        print(f"  - {display_user}: {percentage:.2f}%")

    print("\nTop 5 most used passwords with their % of the total:")
    for password, percentage in top_5_passwords.items():
        display_pass = mask_string(password) if obfuscate else password
        print(f"  - {display_pass}: {percentage:.2f}%")

    print("\nTop 5 most used username-password combinations with their % of total:")
    for (username, password), count in top_5_combos.items():
        display_user = mask_string(username) if obfuscate else username
        display_pass = mask_string(password) if obfuscate else password
        percentage   = (count / total_entries) * 100
        print(f"  - User: '{display_user}' | Pass: '{display_pass}' -> {percentage:.2f}% ({count} total uses)")

    # Password structure breakdown (counted over unique password values)
    unique_passwords = df["login_password"].dropna().unique()
    structure_counts = Counter(classify_password_structure(pw) for pw in unique_passwords)
    total_unique_pw = len(unique_passwords)

    print("\nPassword structure breakdown (by unique password values):")
    for key, label in STRUCTURE_LABELS.items():
        count = structure_counts.get(key, 0)
        pct = (count / total_unique_pw * 100) if total_unique_pw else 0
        print(f"  {label}: {pct:.1f}% ({count})")

    print()
    answer = input(f"Delete '{latest_file}'? [y/N] ").strip().lower()
    if answer == "y":
        os.remove(latest_file)
        print(f"Deleted: {latest_file}")
    else:
        print("File kept.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Analyze a Bitwarden password-protected JSON export with optional data masking."
    )
    parser.add_argument(
        "--obfuscate",
        action="store_true",
        help="Obfuscate usernames and passwords in the printed output.",
    )
    args = parser.parse_args()
    analyze_bitwarden_export(obfuscate=args.obfuscate)
