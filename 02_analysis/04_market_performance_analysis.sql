-- =====================================================================
-- File:        04_market_performance_analysis.sql
-- Project:     Healthcare Commercial Analytics: Sales Force Effectiveness
--              & HCP Targeting
-- Database:    healthcare_commercial_analytics
-- Purpose:     Market performance analysis by physician specialty and
--              geographic region, for Power BI dashboard consumption.
-- =====================================================================

USE healthcare_commercial_analytics;

-- =====================================================================
-- SECTION 1: Overall Specialty Performance
-- Total Claims, Total Drug Cost, and Total Beneficiaries by specialty
-- =====================================================================
SELECT
    hd.Prscrbr_Type                       AS Specialty,
    COUNT(DISTINCT hd.Prscrbr_NPI)         AS HCP_Count,
    SUM(pd.Tot_Clms)                       AS Total_Claims,
    SUM(pd.Tot_Drug_Cst)                   AS Total_Drug_Cost,
    SUM(pd.Tot_Benes)                      AS Total_Beneficiaries
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_Type
ORDER BY Total_Claims DESC;


-- =====================================================================
-- SECTION 2: Top 10 Specialties by Total Claims
-- =====================================================================
SELECT
    hd.Prscrbr_Type                       AS Specialty,
    SUM(pd.Tot_Clms)                       AS Total_Claims
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_Type
ORDER BY Total_Claims DESC
LIMIT 10;


-- =====================================================================
-- SECTION 3: Top 10 Specialties by Total Drug Cost
-- =====================================================================
SELECT
    hd.Prscrbr_Type                       AS Specialty,
    SUM(pd.Tot_Drug_Cst)                   AS Total_Drug_Cost
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_Type
ORDER BY Total_Drug_Cost DESC
LIMIT 10;


-- =====================================================================
-- SECTION 4: Average Claims and Drug Cost per HCP by Specialty
-- Normalizes performance by HCP count for fair specialty comparison
-- =====================================================================
SELECT
    hd.Prscrbr_Type                                            AS Specialty,
    COUNT(DISTINCT hd.Prscrbr_NPI)                              AS HCP_Count,
    SUM(pd.Tot_Clms) / COUNT(DISTINCT hd.Prscrbr_NPI)           AS Avg_Claims_Per_HCP,
    SUM(pd.Tot_Drug_Cst) / COUNT(DISTINCT hd.Prscrbr_NPI)       AS Avg_Drug_Cost_Per_HCP
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_Type
ORDER BY Avg_Drug_Cost_Per_HCP DESC;


-- =====================================================================
-- SECTION 5: Overall State Performance
-- Total Claims, Total Drug Cost, and Total Beneficiaries by state
-- =====================================================================
SELECT
    hd.Prscrbr_State_Abrvtn               AS State,
    COUNT(DISTINCT hd.Prscrbr_NPI)         AS HCP_Count,
    SUM(pd.Tot_Clms)                       AS Total_Claims,
    SUM(pd.Tot_Drug_Cst)                   AS Total_Drug_Cost,
    SUM(pd.Tot_Benes)                      AS Total_Beneficiaries
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_State_Abrvtn
ORDER BY Total_Claims DESC;


-- =====================================================================
-- SECTION 6: Top 10 States by Total Claims
-- =====================================================================
SELECT
    hd.Prscrbr_State_Abrvtn               AS State,
    SUM(pd.Tot_Clms)                       AS Total_Claims
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_State_Abrvtn
ORDER BY Total_Claims DESC
LIMIT 10;


-- =====================================================================
-- SECTION 7: Top 10 States by Total Drug Cost
-- =====================================================================
SELECT
    hd.Prscrbr_State_Abrvtn               AS State,
    SUM(pd.Tot_Drug_Cst)                   AS Total_Drug_Cost
FROM prescription_data pd
INNER JOIN hcp_demographics hd
    ON pd.Prscrbr_NPI = hd.Prscrbr_NPI
GROUP BY hd.Prscrbr_State_Abrvtn
ORDER BY Total_Drug_Cost DESC
LIMIT 10;


-- =====================================================================
-- SECTION 8: HCP Count and Sales Calls by State
-- Combines prescriber footprint with sales rep call activity per state
-- =====================================================================
WITH hcp_counts AS (
    SELECT
        Prscrbr_State_Abrvtn,
        COUNT(DISTINCT Prscrbr_NPI) AS HCP_Count
    FROM hcp_demographics
    GROUP BY Prscrbr_State_Abrvtn
),
call_activity AS (
    SELECT
        hd.Prscrbr_State_Abrvtn,
        SUM(ci.Calls_Made)         AS Total_Calls_Made
    FROM crm_interactions ci
    INNER JOIN hcp_demographics hd
        ON ci.Prscrbr_NPI = hd.Prscrbr_NPI
    GROUP BY hd.Prscrbr_State_Abrvtn
)
SELECT
    hc.Prscrbr_State_Abrvtn        AS State,
    hc.HCP_Count,
    COALESCE(ca.Total_Calls_Made, 0) AS Total_Calls_Made
FROM hcp_counts hc
INNER JOIN call_activity ca
    ON hc.Prscrbr_State_Abrvtn = ca.Prscrbr_State_Abrvtn
ORDER BY Total_Calls_Made DESC;
