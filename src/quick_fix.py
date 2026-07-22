import pandas as pd

# Point to the processed file you ALREADY made
file_path = r"D:\HCP PROJECT\data\processed\prescription_data.csv"

print("Loading data...")
df = pd.read_csv(file_path, low_memory=False)

print("Fixing blank values...")
df["Tot_Benes"] = pd.to_numeric(df["Tot_Benes"], errors="coerce").fillna(0).astype(int)
df["Tot_Clms"] = pd.to_numeric(df["Tot_Clms"], errors="coerce").fillna(0).astype(int)

print("Overwriting the file...")
df.to_csv(file_path, index=False)
print("Done! Safe to import to MySQL.")
