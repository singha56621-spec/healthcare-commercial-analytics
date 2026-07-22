"""
filter_dataset.py

Purpose
-------
Reads a large (~4GB) CMS Medicare Provider Utilization and Payment Data CSV
in chunks, filters it down to a smaller "master" dataset scoped to specific
states and provider specialties, cleans it, and writes a single filtered
CSV that will later be used to build SQL tables and Power BI dashboards.

Author: Data Engineering (Healthcare Commercial Analytics portfolio project)
"""

import os
import time
import pandas as pd

# --------------------------------------------------------------------------
# CONSTANTS
# --------------------------------------------------------------------------

# Input / output file paths
INPUT_FILE = r"D:\HCP PROJECT\data\raw\MUP_DPR_RY26_P04_V10_DY24_NPIBN.csv"
OUTPUT_DIR = r"D:\HCP PROJECT\data\processed"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "filtered_master.csv")

# Chunk size for reading the large CSV in pieces (never load full file at once)
CHUNK_SIZE = 100_000

# Column names in the CMS Medicare Part D Prescribers dataset
# NOTE: The dataset stores the prescriber's state in "Prscrbr_State_Abrvtn"
#       and the prescriber's specialty/type in "Prscrbr_Type" (as specified).
STATE_COLUMN = "Prscrbr_State_Abrvtn"
SPECIALTY_COLUMN = "Prscrbr_Type"

# Values to keep
TARGET_STATES = ["NY", "NJ", "PA"]
TARGET_SPECIALTIES = ["Cardiology", "Internal Medicine", "Family Practice"]

# Columns that must not be missing (rows with nulls here are dropped)
REQUIRED_NON_NULL_COLUMNS = ["Prscrbr_NPI", "Brnd_Name", "Tot_Clms", "Tot_Drug_Cst"]


# --------------------------------------------------------------------------
# FUNCTIONS
# --------------------------------------------------------------------------

def ensure_output_directory_exists(directory_path):
    """
    Create the output directory if it does not already exist.
    Prevents a FileNotFoundError when writing the final CSV.
    """
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        print(f"Created output directory: {directory_path}")


def filter_chunk(chunk):
    """
    Apply all filtering and data quality rules to a single chunk.

    Steps:
    1. Keep only rows where the state is one of TARGET_STATES.
    2. Keep only rows where the specialty is one of TARGET_SPECIALTIES.
    3. Drop rows missing any of the REQUIRED_NON_NULL_COLUMNS.
    4. Drop duplicate rows within the chunk.

    Returns the cleaned/filtered chunk as a DataFrame.
    """
    # Step 1: Filter by state (exact match against the target list)
    chunk = chunk[chunk[STATE_COLUMN].isin(TARGET_STATES)]

    # Step 2: Filter by specialty (exact match against the target list)
    chunk = chunk[chunk[SPECIALTY_COLUMN].isin(TARGET_SPECIALTIES)]

    # Step 3: Drop rows where any required column is missing
    chunk = chunk.dropna(subset=REQUIRED_NON_NULL_COLUMNS)

    # Step 4: Drop duplicate rows within this chunk
    chunk = chunk.drop_duplicates()

    return chunk


def process_csv_in_chunks(input_path, chunk_size):
    """
    Read the large CSV file in chunks, filter each chunk, and collect the
    filtered results. Prints progress after every chunk.

    Returns:
        filtered_chunks (list of DataFrames)
        total_rows_read (int) - total original rows processed
    """
    filtered_chunks = []
    total_rows_read = 0
    chunk_number = 0

    # low_memory=False avoids dtype-guessing warnings on mixed-type columns,
    # which are common in large government datasets like this one.
    csv_reader = pd.read_csv(input_path, chunksize=chunk_size, low_memory=False)

    for chunk in csv_reader:
        chunk_number += 1
        total_rows_read += len(chunk)

        # Filter and clean this chunk
        cleaned_chunk = filter_chunk(chunk)

        # Only keep chunks that actually have surviving rows
        if not cleaned_chunk.empty:
            filtered_chunks.append(cleaned_chunk)

        # Progress reporting after every chunk
        print(f"Processed chunk {chunk_number}")
        print(f"Rows kept: {len(cleaned_chunk)}")

    return filtered_chunks, total_rows_read


def combine_and_deduplicate(filtered_chunks):
    """
    Combine all filtered chunks into a single DataFrame and perform a final
    duplicate check across the entire combined dataset (in case identical
    rows appeared in different chunks).
    """
    if not filtered_chunks:
        # Return an empty DataFrame if nothing survived the filters
        return pd.DataFrame()

    combined_df = pd.concat(filtered_chunks, ignore_index=True)
    combined_df = combined_df.drop_duplicates()
    return combined_df


def save_filtered_dataset(df, output_path):
    """
    Save the final filtered DataFrame to a single CSV file.
    """
    df.to_csv(output_path, index=False)
    print(f"\nFiltered master dataset saved to: {output_path}")


def print_summary(original_rows, filtered_rows, start_time, end_time):
    """
    Print the final summary statistics for the run.
    """
    retention_pct = (filtered_rows / original_rows * 100) if original_rows > 0 else 0
    execution_time = end_time - start_time

    print("\n----------------------------------------")
    print("SUMMARY")
    print("----------------------------------------")
    print(f"Original rows processed : {original_rows}")
    print(f"Filtered rows           : {filtered_rows}")
    print(f"Retention percentage    : {retention_pct:.2f}%")
    print(f"Execution time          : {execution_time:.2f} seconds")
    print("----------------------------------------")


# --------------------------------------------------------------------------
# MAIN EXECUTION
# --------------------------------------------------------------------------

def main():
    start_time = time.time()

    print("Starting filtering process for CMS Medicare Provider dataset...")
    print(f"Input file  : {INPUT_FILE}")
    print(f"Output file : {OUTPUT_FILE}")
    print(f"Chunk size  : {CHUNK_SIZE}\n")

    try:
        # Basic pre-checks before starting the expensive read operation
        if not os.path.exists(INPUT_FILE):
            raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

        ensure_output_directory_exists(OUTPUT_DIR)

        # Step 1: Read and filter the CSV in chunks
        filtered_chunks, total_rows_read = process_csv_in_chunks(INPUT_FILE, CHUNK_SIZE)

        # Step 2: Combine all filtered chunks and remove any cross-chunk duplicates
        final_df = combine_and_deduplicate(filtered_chunks)

        if final_df.empty:
            print("\nWarning: No rows survived the filtering process. "
                  "Please verify column names and filter values.")
        else:
            # Step 3: Save the final filtered dataset
            save_filtered_dataset(final_df, OUTPUT_FILE)

        # Step 4: Print final summary
        end_time = time.time()
        print_summary(total_rows_read, len(final_df), start_time, end_time)

    except FileNotFoundError as fnf_error:
        print(f"\nERROR: {fnf_error}")

    except KeyError as key_error:
        print(f"\nERROR: A required column was not found in the dataset: {key_error}")
        print("Please check the actual column names in the CSV (e.g. using "
              "pd.read_csv(INPUT_FILE, nrows=5).columns) and update the "
              "STATE_COLUMN / SPECIALTY_COLUMN constants accordingly.")

    except MemoryError:
        print("\nERROR: Ran out of memory. Try reducing CHUNK_SIZE and re-running.")

    except Exception as generic_error:
        print(f"\nUNEXPECTED ERROR: {generic_error}")


if __name__ == "__main__":
    main()
