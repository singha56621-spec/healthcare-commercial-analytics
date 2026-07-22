"""
split_tables.py
----------------------------------------------------------------------
Healthcare Commercial Analytics Portfolio Project
----------------------------------------------------------------------
Purpose:
    Normalize the flat "filtered_master.csv" dataset into three
    relational tables suitable for loading into a SQL database:

        1. hcp_demographics.csv   -> one row per prescriber (HCP)
        2. drug_reference.csv     -> one row per unique drug, with a
                                      surrogate primary key (Drug_ID)
        3. prescription_data.csv  -> fact table linking prescribers to
                                      drugs via Drug_ID (foreign key)

Allowed libraries only: pandas, os, time
----------------------------------------------------------------------
"""

import os
import time
import pandas as pd

# ----------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------
# Centralizing paths and column names as constants makes the script
# easier to maintain and reduces the risk of typos scattered through
# the code.

INPUT_DIR = r"D:\HCP PROJECT\data\processed"
OUTPUT_DIR = r"D:\HCP PROJECT\data\processed"

INPUT_FILE = os.path.join(INPUT_DIR, "filtered_master.csv")

HCP_DEMOGRAPHICS_FILE = os.path.join(OUTPUT_DIR, "hcp_demographics.csv")
DRUG_REFERENCE_FILE = os.path.join(OUTPUT_DIR, "drug_reference.csv")
PRESCRIPTION_DATA_FILE = os.path.join(OUTPUT_DIR, "prescription_data.csv")

# Columns that make up the HCP (provider) demographics table
HCP_COLUMNS = [
    "Prscrbr_NPI",
    "Prscrbr_First_Name",
    "Prscrbr_Last_Org_Name",
    "Prscrbr_City",
    "Prscrbr_State_Abrvtn",
    "Prscrbr_Type",
]

# Columns that make up the drug reference table (before surrogate key)
DRUG_COLUMNS = [
    "Brnd_Name",
    "Gnrc_Name",
]

# Columns that make up the prescription fact table
PRESCRIPTION_MEASURE_COLUMNS = [
    "Tot_Clms",
    "Tot_Drug_Cst",
    "Tot_Benes",
]

# Columns required in the source file for this script to run correctly
REQUIRED_SOURCE_COLUMNS = list(
    dict.fromkeys(HCP_COLUMNS + DRUG_COLUMNS + PRESCRIPTION_MEASURE_COLUMNS)
)


# ----------------------------------------------------------------------
# FUNCTION: load_master_data
# ----------------------------------------------------------------------
def load_master_data(file_path):
    """
    Load the filtered master CSV into a pandas DataFrame.
    Validates that the file exists and that all required columns
    are present before proceeding.
    """
    print(f"[STEP 1] Loading master dataset from: {file_path}")

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Input file not found: {file_path}")

    try:
        df = pd.read_csv(file_path, low_memory=False)
    except Exception as error:
        raise RuntimeError(f"Failed to read CSV file: {error}")

    # Validate required columns exist in the source data
    missing_columns = [col for col in REQUIRED_SOURCE_COLUMNS if col not in df.columns]
    if missing_columns:
        raise ValueError(
            f"The following required columns are missing from the source "
            f"file: {missing_columns}"
        )

    print(f"    -> Loaded {len(df):,} records with {len(df.columns)} columns.")
    return df


# ----------------------------------------------------------------------
# FUNCTION: build_hcp_demographics
# ----------------------------------------------------------------------
def build_hcp_demographics(df):
    """
    Build the HCP demographics table.
    One row per unique provider (Prscrbr_NPI), duplicates removed.
    """
    print("[STEP 2] Building hcp_demographics table...")

    hcp_df = df[HCP_COLUMNS].copy()

    # Drop duplicate providers so each NPI appears exactly once.
    # A provider may appear multiple times in the master file because
    # they prescribe multiple drugs; demographics don't need repeating.
    hcp_df = hcp_df.drop_duplicates(subset=["Prscrbr_NPI"], keep="first")

    # Reset index for a clean, sequential row order
    hcp_df = hcp_df.reset_index(drop=True)

    print(f"    -> {len(hcp_df):,} unique providers identified.")
    return hcp_df


# ----------------------------------------------------------------------
# FUNCTION: build_drug_reference
# ----------------------------------------------------------------------
def build_drug_reference(df):
    """
    Build the drug reference table with a surrogate key (Drug_ID).
    One row per unique (Brnd_Name, Gnrc_Name) combination.
    """
    print("[STEP 3] Building drug_reference table...")

    drug_df = df[DRUG_COLUMNS].copy()

    # Remove duplicate drug entries so each unique drug appears once
    drug_df = drug_df.drop_duplicates(subset=DRUG_COLUMNS, keep="first")

    # Reset index before assigning surrogate keys so Drug_ID is sequential
    drug_df = drug_df.reset_index(drop=True)

    # Create the surrogate primary key starting from 1
    drug_df.insert(0, "Drug_ID", range(1, len(drug_df) + 1))

    print(f"    -> {len(drug_df):,} unique drugs identified.")
    return drug_df


# ----------------------------------------------------------------------
# FUNCTION: build_prescription_data
# ----------------------------------------------------------------------
def build_prescription_data(df, drug_df):
    """
    Build the prescription fact table.
    Joins Drug_ID from drug_reference back onto the master data so that
    prescriptions reference Drug_ID instead of the raw brand/generic
    name text (this is standard fact-table normalization).
    """
    print("[STEP 4] Building prescription_data table...")

    # Merge the master dataframe with the drug reference table on the
    # descriptive drug columns to attach the surrogate Drug_ID.
    merged_df = df.merge(
        drug_df,
        on=DRUG_COLUMNS,
        how="left",
        validate="many_to_one",
    )

    # Check for any prescriptions that failed to match a Drug_ID.
    # This should not happen since drug_reference was derived from the
    # same source data, but we validate defensively.
    unmatched = merged_df["Drug_ID"].isna().sum()
    if unmatched > 0:
        print(f"    -> WARNING: {unmatched:,} rows could not be matched to a Drug_ID.")

    # Select only the fact-table columns: foreign keys + measures
    fact_columns = ["Prscrbr_NPI", "Drug_ID"] + PRESCRIPTION_MEASURE_COLUMNS
    prescription_df = merged_df[fact_columns].copy()

    # Drug_ID should be an integer type (may be float after merge if NaNs existed)
    prescription_df["Drug_ID"] = prescription_df["Drug_ID"].astype("Int64")

    prescription_df = prescription_df.reset_index(drop=True)

    print(f"    -> {len(prescription_df):,} prescription records prepared.")
    return prescription_df


# ----------------------------------------------------------------------
# FUNCTION: save_dataframe
# ----------------------------------------------------------------------
def save_dataframe(df, file_path, table_name):
    """
    Save a DataFrame to CSV, printing the number of records written.
    Wrapped in error handling in case of disk/permission issues.
    """
    try:
        df.to_csv(file_path, index=False)
    except Exception as error:
        raise RuntimeError(f"Failed to write {table_name} to {file_path}: {error}")

    print(f"    -> Saved {table_name}: {len(df):,} records -> {file_path}")


# ----------------------------------------------------------------------
# FUNCTION: main
# ----------------------------------------------------------------------
def main():
    """
    Orchestrates the full normalization pipeline:
    load -> build tables -> save tables -> report timing.
    """
    start_time = time.time()
    print("=" * 70)
    print("HCP PROJECT - split_tables.py")
    print("Normalizing filtered_master.csv into relational tables")
    print("=" * 70)

    try:
        # Ensure the output directory exists before writing any files
        if not os.path.exists(OUTPUT_DIR):
            os.makedirs(OUTPUT_DIR)
            print(f"[INFO] Created output directory: {OUTPUT_DIR}")

        # Step 1: Load source data
        master_df = load_master_data(INPUT_FILE)

        # Step 2: Build the HCP demographics dimension table
        hcp_df = build_hcp_demographics(master_df)

        # Step 3: Build the drug reference dimension table
        drug_df = build_drug_reference(master_df)

        # Step 4: Build the prescription fact table (references Drug_ID)
        prescription_df = build_prescription_data(master_df, drug_df)

        # Step 5: Save all three tables to disk
        print("[STEP 5] Writing output tables to disk...")
        save_dataframe(hcp_df, HCP_DEMOGRAPHICS_FILE, "hcp_demographics.csv")
        save_dataframe(drug_df, DRUG_REFERENCE_FILE, "drug_reference.csv")
        save_dataframe(prescription_df, PRESCRIPTION_DATA_FILE, "prescription_data.csv")

        # Final summary
        elapsed = time.time() - start_time
        print("=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"hcp_demographics.csv   : {len(hcp_df):,} records")
        print(f"drug_reference.csv     : {len(drug_df):,} records")
        print(f"prescription_data.csv  : {len(prescription_df):,} records")
        print(f"Total execution time   : {elapsed:.2f} seconds")
        print("=" * 70)
        print("SUCCESS: All tables created successfully.")

    except Exception as error:
        # Catch-all error handler so the script fails gracefully with a
        # clear message instead of an unhandled traceback.
        elapsed = time.time() - start_time
        print("=" * 70)
        print(f"ERROR: Script failed after {elapsed:.2f} seconds.")
        print(f"Details: {error}")
        print("=" * 70)
        raise


# ----------------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------------
if __name__ == "__main__":
    main()
