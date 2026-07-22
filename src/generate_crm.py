"""
generate_crm.py
Healthcare Commercial Analytics - Synthetic CRM Interactions Generator
Input  : D:\HCP PROJECT\data\processed\prescription_data.csv
Output : D:\HCP PROJECT\data\processed\crm_interactions.csv
"""

import pandas as pd
import random
import datetime

start_time = datetime.datetime.now()
random.seed(42)

# 1. Load data and aggregate claims by prescriber
df = pd.read_csv(r"D:\HCP PROJECT\data\processed\prescription_data.csv")
hcp_df = df.groupby("Prscrbr_NPI")["Tot_Clms"].sum().reset_index()
hcp_df.columns = ["Prscrbr_NPI", "Total_Claims"]

# 2. Rank HCPs by Total Claims (highest first)
hcp_df = hcp_df.sort_values("Total_Claims", ascending=False).reset_index(drop=True)
total_hcps = len(hcp_df)

# 3. Assign segment: Top 20% / Middle 60% / Bottom 20%
top_cut = int(total_hcps * 0.2)
bottom_cut = int(total_hcps * 0.8)
segments = []
for i in range(total_hcps):
    if i < top_cut:
        segments.append("Top 20%")
    elif i < bottom_cut:
        segments.append("Middle 60%")
    else:
        segments.append("Bottom 20%")
hcp_df["Segment"] = segments

# 4. Build list of 10 sales reps: REP001 to REP010
reps = []
for i in range(1, 11):
    reps.append("REP" + str(i).zfill(3))

# 5. Generate CRM interaction records
start_2024 = datetime.date(2024, 1, 1)
records = []
interaction_id = 1

for i, row in hcp_df.iterrows():
    if row["Segment"] == "Top 20%":
        calls_made = random.randint(1, 3)      # missed opportunities
    elif row["Segment"] == "Middle 60%":
        calls_made = random.randint(3, 5)
    else:
        calls_made = random.randint(5, 8)       # wasted effort

    for c in range(calls_made):
        visit_date = start_2024 + datetime.timedelta(days=random.randint(0, 365))
        records.append([
            interaction_id,
            random.choice(reps),
            row["Prscrbr_NPI"],
            visit_date,
            calls_made
        ])
        interaction_id += 1

crm_df = pd.DataFrame(records, columns=[
    "Interaction_ID", "Rep_ID", "Prscrbr_NPI", "Visit_Date", "Calls_Made"
])

# 6. Save output
crm_df.to_csv(r"D:\HCP PROJECT\data\processed\crm_interactions.csv", index=False)

# 7. Print summary
print("Number of HCPs:", total_hcps)
print("Number of CRM records:", len(crm_df))
print("Execution time:", datetime.datetime.now() - start_time)
