#!/usr/bin/env python3
"""
explore_dataset.py

Quickly explore a large CMS Medicare Provider Utilization and Payment Data
CSV file WITHOUT loading the entire file into memory.

Source file: MUP_DPR_RY26_P04_V10_DY24_NPIBN.csv (~4GB)

This script:
    1. Reads only the first 1000 rows of the CSV (via nrows=1000).
    2. Prints summary information (column count, names, dtypes, memory usage).
    3. Prints the first 5 rows.
    4. Saves all column names to a text file.
    5. Saves the first 100 rows to a separate CSV file.

Because `nrows=1000` is passed to `pd.read_csv`, pandas stops reading the
file as soon as 1000 data rows have been parsed -- it never loads the
remaining multi-gigabyte contents into memory.
"""

"""
explore_dataset.py
 
Quickly explore a large CMS Medicare Provider Utilization and Payment Data
CSV file WITHOUT loading the entire file into memory.
"""
 
import os                  # NEW: Imported os to handle folders and file paths
import pandas as pd
 
# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Use the raw string (r"") absolute path to where your 4GB file actually lives
INPUT_FILE = r"D:\HCP PROJECT\data\raw\MUP_DPR_RY26_P04_V10_DY24_NPIBN.csv"
 
NROWS_TO_READ = 1000
SAMPLE_ROWS_TO_SAVE = 100
 
# Add an output folder path so your main folder stays clean
OUTPUT_FOLDER = r"D:\HCP PROJECT\data\processed"
 
def main():
    # -----------------------------------------------------------------------
    # NEW: Automatically create the output folder if it doesn't exist
    # -----------------------------------------------------------------------
    os.makedirs(OUTPUT_FOLDER, exist_ok=True)

    # -----------------------------------------------------------------------
    # NEW: Check if the input file actually exists before trying to read it
    # -----------------------------------------------------------------------
    if not os.path.exists(INPUT_FILE):
        raise FileNotFoundError(f"File not found. Please check this path:\n{INPUT_FILE}")

    # -----------------------------------------------------------------------
    # Step 1: Read only the first 1000 rows of the CSV.
    # -----------------------------------------------------------------------
    print(f"Reading first {NROWS_TO_READ} rows from the massive CSV...")
    df = pd.read_csv(INPUT_FILE, nrows=NROWS_TO_READ, low_memory=False)
 
    # -----------------------------------------------------------------------
    # Step 2 & 3: Print number of columns and Column names.
    # -----------------------------------------------------------------------
    print("=" * 80)
    print(f"Number of columns: {df.shape[1]}")
    print("Column names:")
    for col in df.columns:
        print(f"  - {col}")
 
    # -----------------------------------------------------------------------
    # Step 4 & 5: Data types and Memory usage.
    # -----------------------------------------------------------------------
    print("=" * 80)
    print("Memory usage (in bytes, per column, deep=True):")
    mem_usage = df.memory_usage(deep=True)
    print(f"\nTotal memory usage of this {NROWS_TO_READ}-row sample: "
          f"{mem_usage.sum() / (1024 ** 2):.4f} MB")
 
    # -----------------------------------------------------------------------
    # Step 6: Print the first 5 rows.
    # -----------------------------------------------------------------------
    print("=" * 80)
    print("First 5 rows:")
    print(df.head(5))
    print("=" * 80)
 
    # -----------------------------------------------------------------------
    # Step 7: Save all column names to a text file
    # -----------------------------------------------------------------------
    COLUMN_NAMES_FILE = f"{OUTPUT_FOLDER}\\column_names.txt"
    with open(COLUMN_NAMES_FILE, "w", encoding="utf-8") as f:
        for col in df.columns:
            f.write(f"{col}\n")
    print(f"Saved {len(df.columns)} column names to '{COLUMN_NAMES_FILE}'.")
 
    # -----------------------------------------------------------------------
    # Step 8: Save the first 100 rows to a smaller sample CSV file
    # -----------------------------------------------------------------------
    SAMPLE_DATA_FILE = f"{OUTPUT_FOLDER}\\sample_data.csv"
    sample_df = df.head(SAMPLE_ROWS_TO_SAVE)
    sample_df.to_csv(SAMPLE_DATA_FILE, index=False)
    print(f"Saved first {SAMPLE_ROWS_TO_SAVE} rows to '{SAMPLE_DATA_FILE}'.")

    # -----------------------------------------------------------------------
    # NEW: Print a success message at the very end
    # -----------------------------------------------------------------------
    print("\n✅ Dataset exploration completed successfully!")
 
 
if __name__ == "__main__":
    main()