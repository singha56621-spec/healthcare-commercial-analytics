-- ============================================================================
-- File        : 02_sales_force_effectiveness.sql
-- Project     : Healthcare Commercial Analytics: Sales Force Effectiveness
--               & HCP Targeting
-- Database    : healthcare_commercial_analytics
-- Purpose     : Business-focused analysis of prescribing behavior, sales
--               call activity, and rep targeting effectiveness.
-- Notes       : Analytical queries only. No procedures, views, temp tables,
--               or dynamic SQL, as per project requirements.
-- ============================================================================

USE healthcare_commercial_analytics;

-- ============================================================================
-- 1. OVERALL PRESCRIBING AND SALES ACTIVITY SUMMARY
-- Purpose: Single-row snapshot of total HCPs, claims, drug cost,
--          beneficiaries, and sales call volume across the business.
-- ============================================================================

SELECT
    (SELECT COUNT(DISTINCT Prscrbr_NPI) FROM hcp_demographics)      AS total_hcps,
    (SELECT COUNT(*)                    FROM prescription_data)     AS total_prescriptions,
    (SELECT SUM(Tot_Clms)               FROM prescription_data)     AS total_claims,
    (SELECT SUM(Tot_Drug_Cst)           FROM prescription_data)     AS total_drug_cost,
    (SELECT SUM(Tot_Benes)             FROM prescription_data)      AS total_beneficiaries,
    (SELECT COUNT(*)                    FROM crm_interactions)      AS total_interactions,
    (SELECT SUM(Calls_Made)            FROM crm_interactions)       AS total_calls_made;

-- ============================================================================
-- 2. TOP 20 HCPs BY TOTAL CLAIMS
-- Purpose: Identify the highest-volume prescribers to prioritize for
--          engagement and retention.
-- ============================================================================

SELECT
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn,
    hd.Prscrbr_Type,
    SUM(pd.Tot_Clms) AS total_claims,
    RANK() OVER (ORDER BY SUM(pd.Tot_Clms) DESC) AS claims_rank
FROM hcp_demographics hd
INNER JOIN prescription_data pd
    ON hd.Prscrbr_NPI = pd.Prscrbr_NPI
GROUP BY
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn,
    hd.Prscrbr_Type
ORDER BY total_claims DESC
LIMIT 20;

-- ============================================================================
-- 3. TOP 20 HCPs BY SALES CALLS
-- Purpose: Identify the HCPs receiving the most sales rep attention,
--          used later to compare call volume against prescribing value.
-- ============================================================================

SELECT
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn,
    SUM(ci.Calls_Made) AS total_calls,
    RANK() OVER (ORDER BY SUM(ci.Calls_Made) DESC) AS calls_rank
FROM hcp_demographics hd
INNER JOIN crm_interactions ci
    ON hd.Prscrbr_NPI = ci.Prscrbr_NPI
GROUP BY
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn
ORDER BY total_calls DESC
LIMIT 20;

-- ============================================================================
-- 4. HIGH-VALUE HCPs RECEIVING FEWER SALES CALLS THAN AVERAGE
--    (MISSED OPPORTUNITIES)
-- Purpose: Flag HCPs whose prescribing volume is above the overall average
--          claims per HCP, but whose call volume is below the overall
--          average calls per HCP. These represent under-served, high-value
--          targets for the sales force.
-- ============================================================================

WITH hcp_claims AS (
    SELECT
        Prscrbr_NPI,
        SUM(Tot_Clms) AS total_claims
    FROM prescription_data
    GROUP BY Prscrbr_NPI
),
hcp_calls AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS total_calls
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
),
overall_averages AS (
    SELECT
        (SELECT AVG(total_claims) FROM hcp_claims) AS avg_claims,
        (SELECT AVG(total_calls)  FROM hcp_calls)  AS avg_calls
)
SELECT
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn,
    hc.total_claims,
    COALESCE(cc.total_calls, 0) AS total_calls,
    oa.avg_claims,
    oa.avg_calls
FROM hcp_claims hc
INNER JOIN hcp_demographics hd
    ON hc.Prscrbr_NPI = hd.Prscrbr_NPI
LEFT JOIN hcp_calls cc
    ON hc.Prscrbr_NPI = cc.Prscrbr_NPI
CROSS JOIN overall_averages oa
WHERE hc.total_claims > oa.avg_claims
  AND COALESCE(cc.total_calls, 0) < oa.avg_calls
ORDER BY hc.total_claims DESC;

-- ============================================================================
-- 5. LOW-VALUE HCPs RECEIVING ABOVE-AVERAGE SALES CALLS
--    (OVER-TARGETED HCPs)
-- Purpose: Flag HCPs whose prescribing volume is below the overall average
--          claims per HCP, but whose call volume is above the overall
--          average calls per HCP. These represent potentially wasted sales
--          effort that could be redirected.
-- ============================================================================

WITH hcp_claims AS (
    SELECT
        Prscrbr_NPI,
        SUM(Tot_Clms) AS total_claims
    FROM prescription_data
    GROUP BY Prscrbr_NPI
),
hcp_calls AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS total_calls
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
),
overall_averages AS (
    SELECT
        (SELECT AVG(total_claims) FROM hcp_claims) AS avg_claims,
        (SELECT AVG(total_calls)  FROM hcp_calls)  AS avg_calls
)
SELECT
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    hd.Prscrbr_State_Abrvtn,
    COALESCE(hc.total_claims, 0) AS total_claims,
    cc.total_calls,
    oa.avg_claims,
    oa.avg_calls
FROM hcp_calls cc
INNER JOIN hcp_demographics hd
    ON cc.Prscrbr_NPI = hd.Prscrbr_NPI
LEFT JOIN hcp_claims hc
    ON cc.Prscrbr_NPI = hc.Prscrbr_NPI
CROSS JOIN overall_averages oa
WHERE cc.total_calls > oa.avg_calls
  AND COALESCE(hc.total_claims, 0) < oa.avg_claims
ORDER BY cc.total_calls DESC;

-- ============================================================================
-- 6. CLAIMS PER SALES CALL FOR EVERY HCP
-- Purpose: Measure prescribing output relative to sales effort for each
--          HCP. A low ratio may indicate over-investment; a high ratio may
--          indicate an efficient or under-called account.
-- ============================================================================

WITH hcp_claims AS (
    SELECT
        Prscrbr_NPI,
        SUM(Tot_Clms) AS total_claims
    FROM prescription_data
    GROUP BY Prscrbr_NPI
),
hcp_calls AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS total_calls
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
)
SELECT
    hd.Prscrbr_NPI,
    hd.Prscrbr_First_Name,
    hd.Prscrbr_Last_Org_Name,
    COALESCE(hc.total_claims, 0) AS total_claims,
    COALESCE(cc.total_calls, 0)  AS total_calls,
    CASE
        WHEN COALESCE(cc.total_calls, 0) = 0 THEN NULL
        ELSE ROUND(COALESCE(hc.total_claims, 0) / cc.total_calls, 2)
    END AS claims_per_call
FROM hcp_demographics hd
LEFT JOIN hcp_claims hc
    ON hd.Prscrbr_NPI = hc.Prscrbr_NPI
LEFT JOIN hcp_calls cc
    ON hd.Prscrbr_NPI = cc.Prscrbr_NPI
ORDER BY claims_per_call DESC;

-- ============================================================================
-- 7. SALES REPRESENTATIVE WORKLOAD
-- Purpose: Summarize each rep's coverage footprint - number of distinct
--          HCPs visited and total calls made - to assess workload balance
--          across the sales team.
-- ============================================================================

SELECT
    ci.Rep_ID,
    COUNT(DISTINCT ci.Prscrbr_NPI) AS hcps_covered,
    SUM(ci.Calls_Made)             AS total_calls_made,
    ROUND(SUM(ci.Calls_Made) / COUNT(DISTINCT ci.Prscrbr_NPI), 2) AS avg_calls_per_hcp
FROM crm_interactions ci
GROUP BY ci.Rep_ID
HAVING COUNT(DISTINCT ci.Prscrbr_NPI) > 0
ORDER BY total_calls_made DESC;

-- ============================================================================
-- 8. SALES FORCE EFFECTIVENESS SUMMARY
-- Purpose: Classify every HCP into a targeting category by comparing their
--          claim volume and call volume against overall averages:
--            - Under Targeted : above-average claims, below-average calls
--            - Over Targeted  : below-average claims, above-average calls
--            - Well Targeted  : everything else (claims and calls broadly
--                                aligned with overall activity levels)
-- ============================================================================

WITH hcp_claims AS (
    SELECT
        Prscrbr_NPI,
        SUM(Tot_Clms) AS total_claims
    FROM prescription_data
    GROUP BY Prscrbr_NPI
),
hcp_calls AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS total_calls
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
),
overall_averages AS (
    SELECT
        (SELECT AVG(total_claims) FROM hcp_claims) AS avg_claims,
        (SELECT AVG(total_calls)  FROM hcp_calls)  AS avg_calls
),
hcp_metrics AS (
    SELECT
        hd.Prscrbr_NPI,
        hd.Prscrbr_First_Name,
        hd.Prscrbr_Last_Org_Name,
        hd.Prscrbr_State_Abrvtn,
        COALESCE(hc.total_claims, 0) AS total_claims,
        COALESCE(cc.total_calls, 0)  AS total_calls,
        oa.avg_claims,
        oa.avg_calls
    FROM hcp_demographics hd
    LEFT JOIN hcp_claims hc
        ON hd.Prscrbr_NPI = hc.Prscrbr_NPI
    LEFT JOIN hcp_calls cc
        ON hd.Prscrbr_NPI = cc.Prscrbr_NPI
    CROSS JOIN overall_averages oa
)
SELECT
    Prscrbr_NPI,
    Prscrbr_First_Name,
    Prscrbr_Last_Org_Name,
    Prscrbr_State_Abrvtn,
    total_claims,
    total_calls,
    ROUND(avg_claims, 2) AS avg_claims_benchmark,
    ROUND(avg_calls, 2)  AS avg_calls_benchmark,
    CASE
        WHEN total_claims > avg_claims AND total_calls < avg_calls THEN 'Under Targeted'
        WHEN total_claims < avg_claims AND total_calls > avg_calls THEN 'Over Targeted'
        ELSE 'Well Targeted'
    END AS targeting_classification
FROM hcp_metrics
ORDER BY total_claims DESC;

-- ============================================================================
-- 9. CREATE TARGETING STATUS LOOKUP TABLE
-- Purpose:
-- Persist the targeting classification so Power BI can use it for
-- dashboard filters, visuals and sales force optimization analysis.
-- ============================================================================



CREATE TABLE hcp_targeting_status (

    Prscrbr_NPI BIGINT PRIMARY KEY,

    Targeting_Status VARCHAR(30)

);

INSERT INTO hcp_targeting_status

WITH hcp_claims AS (

    SELECT
        Prscrbr_NPI,
        SUM(Tot_Clms) AS total_claims
    FROM prescription_data
    GROUP BY Prscrbr_NPI

),

hcp_calls AS (

    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS total_calls
    FROM crm_interactions
    GROUP BY Prscrbr_NPI

),

overall_averages AS (

    SELECT
        (SELECT AVG(total_claims) FROM hcp_claims) AS avg_claims,
        (SELECT AVG(total_calls) FROM hcp_calls) AS avg_calls

),

hcp_metrics AS (

    SELECT

        hd.Prscrbr_NPI,

        COALESCE(hc.total_claims,0) AS total_claims,

        COALESCE(cc.total_calls,0) AS total_calls,

        oa.avg_claims,

        oa.avg_calls

    FROM hcp_demographics hd

    LEFT JOIN hcp_claims hc
        ON hd.Prscrbr_NPI = hc.Prscrbr_NPI

    LEFT JOIN hcp_calls cc
        ON hd.Prscrbr_NPI = cc.Prscrbr_NPI

    CROSS JOIN overall_averages oa

)

SELECT

    Prscrbr_NPI,

    CASE

        WHEN total_claims > avg_claims
             AND total_calls < avg_calls
        THEN 'Under Targeted'

        WHEN total_claims < avg_claims
             AND total_calls > avg_calls
        THEN 'Over Targeted'

        ELSE 'Well Targeted'

    END

FROM hcp_metrics;

SELECT Targeting_Status,
       COUNT(*) AS HCP_Count
FROM hcp_targeting_status
GROUP BY Targeting_Status;