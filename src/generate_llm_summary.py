from google import genai

# 1. Put your FREE Gemini API key here
# REPLACE 'PASTE_YOUR_ACTUAL_API_KEY_HERE' WITH YOUR KEY!
client = genai.Client(api_key="YOUR_GEMINI_API_KEY_HERE")

# 2. YOUR EXACT PROJECT DATA
my_project_data = """
- Total Market Value: 109.2 Million Claims, $12.31 Billion Total Drug Cost.
- Regional Leaders: New York (NY) and Pennsylvania (PA) are the highest performing states.
- Specialty Concentration: Internal Medicine and Family Practice drive the vast majority of volume.
- Sales Force Misalignment: EDA proved a -0.41 negative correlation between Sales Calls and Prescription Claims.
- HCP Targeting Gap: Sales Reps are severely over-targeting Tier 2 and Tier 3 physicians while missing high-opportunity Tier 1 targets (e.g., Jason Torrente, Jai Wadhwani).
"""

# 3. The Prompt for the AI
prompt = f"""
Act as a Senior Pharmaceutical Commercial Director. 
Based on the following data points from our latest SQL/Power BI analytics pipeline, 
write a concise, 3-bullet-point executive summary. 

The goal is to give the Regional Sales Managers 3 actionable business recommendations 
to optimize their sales force targeting and fix the misalignment. 
Do not use technical jargon (no mention of SQL, Python, or EDA). Focus strictly on business strategy.

Here is the data:
{my_project_data}
"""

print("Sending data to Google Gemini AI...")

# 4. Connect to the NEW Gemini model and generate the response
response = client.models.generate_content(
    model='gemini-3.1-flash-lite',    # <---- CHANGED THIS LINE
    contents=prompt
)


# 5. Extract and print the summary
llm_summary = response.text
print("\n--- AI GENERATED SUMMARY ---")
print(llm_summary)

# 6. Save to a text file
output_path = r"D:\HCP PROJECT\data\processed\LLM_Summary.txt"
with open(output_path, "w", encoding="utf-8") as file:
    file.write(llm_summary)

print(f"\nSuccess! Saved to: {output_path}")