-- ============================================================================
-- File        : 01_data_quality.sql
-- Project     : Healthcare Commercial Analytics: Sales Force Effectiveness
--               & HCP Targeting
-- Database    : healthcare_commercial_analytics
-- Purpose     : Data quality validation checks across core tables
--               (hcp_demographics, drug_reference, prescription_data,
--               crm_interactions)
-- Notes       : Validation queries only. No procedures, views, or temp
--               tables are used, as per project requirements.
-- ============================================================================

USE healthcare_commercial_analytics;

-- ============================================================================
-- 1. ROW COUNTS FOR EVERY TABLE
-- Purpose: Confirm each table has data loaded and get a baseline volume
--          reference for reconciliation against source files.
-- ============================================================================

SELECT 'hcp_demographics' AS table_name, COUNT(*) AS row_count
FROM hcp_demographics
UNION ALL
SELECT 'drug_reference', COUNT(*)
FROM drug_reference
UNION ALL
SELECT 'prescription_data', COUNT(*)
FROM prescription_data
UNION ALL
SELECT 'crm_interactions', COUNT(*)
FROM crm_interactions;

-- ============================================================================
-- 2. DUPLICATE NPI CHECK (hcp_demographics)
-- Purpose: Prscrbr_NPI should be unique per provider. Duplicates indicate
--          repeated loads or a data entry issue upstream.
-- ============================================================================

SELECT
    Prscrbr_NPI,
    COUNT(*) AS occurrence_count
FROM hcp_demographics
GROUP BY Prscrbr_NPI
HAVING COUNT(*) > 1;

-- ============================================================================
-- 3. DUPLICATE DRUG_ID CHECK (drug_reference)
-- Purpose: Drug_ID should be unique per drug entry. Duplicates would cause
--          incorrect joins/aggregations downstream in prescription analysis.
-- ============================================================================

SELECT
    Drug_ID,
    COUNT(*) AS occurrence_count
FROM drug_reference
GROUP BY Drug_ID
HAVING COUNT(*) > 1;

-- ============================================================================
-- 4. NULL VALUE CHECKS
-- Purpose: Identify missing values in columns critical to joins, reporting,
--          and targeting logic.
-- ============================================================================

-- 4a. hcp_demographics: key identifying and targeting fields
SELECT
    SUM(CASE WHEN Prscrbr_NPI IS NULL THEN 1 ELSE 0 END)        AS null_npi,
    SUM(CASE WHEN Prscrbr_First_Name IS NULL THEN 1 ELSE 0 END) AS null_first_name,
    SUM(CASE WHEN Prscrbr_Last_Org_Name IS NULL THEN 1 ELSE 0 END) AS null_last_org_name,
    SUM(CASE WHEN Prscrbr_City IS NULL THEN 1 ELSE 0 END)       AS null_city,
    SUM(CASE WHEN Prscrbr_State_Abrvtn IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN Prscrbr_Type IS NULL THEN 1 ELSE 0 END)       AS null_prscrbr_type
FROM hcp_demographics;

-- 4b. drug_reference: key identifying fields
SELECT
    SUM(CASE WHEN Drug_ID IS NULL THEN 1 ELSE 0 END)   AS null_drug_id,
    SUM(CASE WHEN Brnd_Name IS NULL THEN 1 ELSE 0 END)  AS null_brnd_name,
    SUM(CASE WHEN Gnrc_Name IS NULL THEN 1 ELSE 0 END)  AS null_gnrc_name
FROM drug_reference;

-- 4c. prescription_data: key identifying and measure fields
SELECT
    SUM(CASE WHEN Prescription_ID IS NULL THEN 1 ELSE 0 END) AS null_prescription_id,
    SUM(CASE WHEN Prscrbr_NPI IS NULL THEN 1 ELSE 0 END)     AS null_npi,
    SUM(CASE WHEN Drug_ID IS NULL THEN 1 ELSE 0 END)         AS null_drug_id,
    SUM(CASE WHEN Tot_Clms IS NULL THEN 1 ELSE 0 END)        AS null_tot_clms,
    SUM(CASE WHEN Tot_Drug_Cst IS NULL THEN 1 ELSE 0 END)    AS null_tot_drug_cst,
    SUM(CASE WHEN Tot_Benes IS NULL THEN 1 ELSE 0 END)       AS null_tot_benes
FROM prescription_data;

-- 4d. crm_interactions: key identifying and measure fields
SELECT
    SUM(CASE WHEN Interaction_ID IS NULL THEN 1 ELSE 0 END) AS null_interaction_id,
    SUM(CASE WHEN Rep_ID IS NULL THEN 1 ELSE 0 END)         AS null_rep_id,
    SUM(CASE WHEN Prscrbr_NPI IS NULL THEN 1 ELSE 0 END)    AS null_npi,
    SUM(CASE WHEN Visit_Date IS NULL THEN 1 ELSE 0 END)     AS null_visit_date,
    SUM(CASE WHEN Calls_Made IS NULL THEN 1 ELSE 0 END)     AS null_calls_made
FROM crm_interactions;

-- ============================================================================
-- 5. INVALID NUMERIC VALUE CHECKS
-- Purpose: Flag negative values (never valid) and zero values where a
--          positive value is expected for meaningful analysis.
-- ============================================================================

-- 5a. prescription_data: negative values (invalid under any circumstance)
SELECT *
FROM prescription_data
WHERE Tot_Clms < 0
   OR Tot_Drug_Cst < 0
   OR Tot_Benes < 0;

-- 5b. prescription_data: zero claims or zero beneficiaries
-- (technically possible in source data, but suspicious for reporting rows
-- and worth reviewing before use in effectiveness metrics)
SELECT *
FROM prescription_data
WHERE Tot_Clms = 0
   OR Tot_Benes = 0;

-- 5c. crm_interactions: negative or zero calls made
-- (a logged interaction should reflect at least one call)
SELECT *
FROM crm_interactions
WHERE Calls_Made < 0
   OR Calls_Made = 0;

-- ============================================================================
-- 6. FOREIGN KEY VALIDATION
-- Purpose: Ensure referential integrity between fact tables and their
--          reference/dimension tables. Any rows returned indicate orphaned
--          records that will break joins in downstream reporting.
-- ============================================================================

-- 6a. prescription_data.Prscrbr_NPI not found in hcp_demographics
SELECT pd.*
FROM prescription_data pd
LEFT JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
WHERE hd.Prscrbr_NPI IS NULL;

-- 6b. prescription_data.Drug_ID not found in drug_reference
SELECT pd.*
FROM prescription_data pd
LEFT JOIN drug_reference dr
    ON pd.Drug_ID = dr.Drug_ID
WHERE dr.Drug_ID IS NULL;

-- 6c. crm_interactions.Prscrbr_NPI not found in hcp_demographics
SELECT ci.*
FROM crm_interactions ci
LEFT JOIN hcp_demographics hd
    ON ci.Prscrbr_NPI = hd.Prscrbr_NPI
WHERE hd.Prscrbr_NPI IS NULL;

-- ============================================================================
-- 7. SAMPLE RECORDS
-- Purpose: Quick visual spot-check of each table's structure and content.
-- ============================================================================

SELECT * FROM hcp_demographics LIMIT 10;

SELECT * FROM drug_reference LIMIT 10;

SELECT * FROM prescription_data LIMIT 10;

SELECT * FROM crm_interactions LIMIT 10;

-- ============================================================================
-- End of 01_data_quality.sql
-- ============================================================================
