# pip install sqlalchemy pymysql


import pandas as pd
from sqlalchemy import create_engine
import urllib.parse  # <--- ADD THIS

DB_USER = "root"
DB_PASS = "Arpit@2004" 
DB_HOST = "localhost"
DB_NAME = "healthcare_commercial_analytics"

#  THIS LINE to safely encode any special characters in password
safe_password = urllib.parse.quote_plus(DB_PASS) 

print("Connecting to MySQL...")


engine = create_engine(f"mysql+pymysql://{DB_USER}:{safe_password}@{DB_HOST}/{DB_NAME}")

# 2. Defining the files and their matching SQL table names
tables_to_load = {
    
    
    "crm_interactions": r"D:\HCP PROJECT\data\processed\crm_interactions.csv"
}

# 3. Load the data!
for table_name, file_path in tables_to_load.items():
    print(f"\nReading {file_path}...")
    df = pd.read_csv(file_path, low_memory=False)
    
    print(f"Pushing {len(df):,} rows to MySQL table: {table_name}...")
    # if_exists='append' ensures it goes into the tables YOU built, 
    # preserving all your Foreign Keys!
    df.to_sql(name=table_name, con=engine, if_exists='append', index=False)
    print("Success!")

print("\n✅ All data loaded into MySQL instantly!")

