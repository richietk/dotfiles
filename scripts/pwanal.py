import os
import glob
import pandas as pd
import argparse

def mask_string(s):
    """Masks a string to hide sensitive info, leaving only first and last characters."""
    if not isinstance(s, str) or not s:
        return ""
    if len(s) <= 2:
        return "*" * len(s)
    return s[0] + "*" * (len(s) - 2) + s[-1]

def analyze_bitwarden_export(obfuscate=False):
    # Define the pattern to find the export files
    file_pattern = '/home/richard/Downloads/bitwarden_export_*.csv'
    
    # Get all files matching the pattern
    files = glob.glob(file_pattern)
    if not files:
        print(f"No files found matching the pattern: {file_pattern}")
        return

    # Find the most recently modified file to handle variable dates
    latest_file = max(files, key=os.path.getmtime)
    print(f"Analyzing file: {latest_file}\n")
    print("-" * 50)

    # Load the CSV
    try:
        df = pd.read_csv(latest_file)
    except Exception as e:
        print(f"Error reading the CSV file: {e}")
        return

    # Filter out entries without a login_uri
    df = df[df['login_uri'].notna() & (df['login_uri'].str.strip() != '')]
    total_entries = len(df)

    if total_entries == 0:
        print("No entries found with a valid login_uri.")
        return

    # Calculate Total unique websites based on "name"
    total_unique_websites = df['name'].nunique()

    # Calculate Total number of unique usernames and passwords
    total_unique_usernames = df['login_username'].nunique()
    total_unique_passwords = df['login_password'].nunique()

    # Calculate Averages
    avg_entries_per_username = total_entries / total_unique_usernames if total_unique_usernames else 0
    avg_entries_per_password = total_entries / total_unique_passwords if total_unique_passwords else 0

    # Fill NaNs with empty strings for accurate grouping of pairs
    df_filled = df.fillna({'login_username': '', 'login_password': ''})
    
    # Calculate Unique Username-Password pairs
    unique_pairs_count = len(df_filled.groupby(['login_username', 'login_password']))
    
    # Ratio of unique pairs to total entries (total pairs)
    unique_pairs_ratio = unique_pairs_count / total_entries

    # Top 5 most used usernames
    top_5_usernames = df['login_username'].value_counts(normalize=True).head(5) * 100

    # Top 5 most used passwords
    top_5_passwords = df['login_password'].value_counts(normalize=True).head(5) * 100

    # Top 5 most used username-password combinations
    combo_counts = df_filled.groupby(['login_username', 'login_password']).size().sort_values(ascending=False)
    top_5_combos = combo_counts.head(5)

    # --- Print Results to Terminal ---
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
        percentage = (count / total_entries) * 100
        print(f"  - User: '{display_user}' | Pass: '{display_pass}' -> {percentage:.2f}% ({count} total uses)")

    print()
    answer = input(f"Delete '{latest_file}'? [y/N] ").strip().lower()
    if answer == 'y':
        os.remove(latest_file)
        print(f"Deleted: {latest_file}")
    else:
        print("File kept.")

if __name__ == "__main__":
    # Setup argparse to handle command-line arguments
    parser = argparse.ArgumentParser(description="Analyze Bitwarden export with optional data masking.")
    
    # Add the --obfuscate argument
    parser.add_argument('--obfuscate', action='store_true', 
                        help="Obfuscate usernames and passwords in the final printed output.")
    
    args = parser.parse_args()
    
    # Pass the argument state into the function
    analyze_bitwarden_export(obfuscate=args.obfuscate)
