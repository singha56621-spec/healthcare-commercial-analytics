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
import pandas as pd
import numpy as np

# --- 1. SET UP PATHS ---
INPUT_FILE = r"D:\HCP PROJECT\data\processed\filtered_master.csv"
OUTPUT_DIR = r"D:\HCP PROJECT\data\processed"

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- 2. LOAD MASTER DATA ---
print("Loading data...")
df = pd.read_csv(INPUT_FILE, low_memory=False)

# --- 3. BUILD AND SAVE HCP DEMOGRAPHICS ---
print("Building hcp_demographics.csv...")
hcp_cols = [
    "Prscrbr_NPI", "Prscrbr_First_Name", "Prscrbr_Last_Org_Name", 
    "Prscrbr_City", "Prscrbr_State_Abrvtn", "Prscrbr_Type"
]
# Drop duplicates based on NPI and save directly
hcp_df = df[hcp_cols].drop_duplicates(subset=["Prscrbr_NPI"]).reset_index(drop=True)
hcp_df.to_csv(os.path.join(OUTPUT_DIR, "hcp_demographics.csv"), index=False)

# --- 4. BUILD AND SAVE DRUG REFERENCE ---
print("Building drug_reference.csv...")
drug_cols = ["Brnd_Name", "Gnrc_Name"]

# Get unique drugs, reset index, and insert surrogate Drug_ID using NumPy
drug_df = df[drug_cols].drop_duplicates().reset_index(drop=True)
drug_df.insert(0, "Drug_ID", np.arange(1, len(drug_df) + 1))
drug_df.to_csv(os.path.join(OUTPUT_DIR, "drug_reference.csv"), index=False)

# --- 5. BUILD AND SAVE PRESCRIPTION DATA (FACT TABLE) ---
print("Building prescription_data.csv...")
fact_cols = ["Prscrbr_NPI", "Drug_ID", "Tot_Clms", "Tot_Drug_Cst", "Tot_Benes"]

# Merge the Drug_ID back to the main dataframe, select columns, cast to Int, and save
prescription_df = df.merge(drug_df, on=drug_cols, how="left")[fact_cols]
prescription_df["Drug_ID"] = prescription_df["Drug_ID"].astype("Int64")
prescription_df.to_csv(os.path.join(OUTPUT_DIR, "prescription_data.csv"), index=False)

print("SUCCESS: All tables created successfully.")
