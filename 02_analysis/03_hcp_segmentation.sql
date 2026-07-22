-- ============================================================================
-- File        : 03_hcp_segmentation.sql
-- Project     : Healthcare Commercial Analytics - Sales Force Effectiveness
--               & HCP Targeting
-- Database    : healthcare_commercial_analytics
-- Purpose     : Rank, segment (tier) and profile HCPs (prescribers) based on
--               prescribing volume, cost, beneficiary reach and sales rep
--               engagement, to support territory targeting and Power BI
--               dashboards.
-- Author      : Healthcare Commercial Analytics SQL Developer
-- Notes       : - No procedures, views, temp tables, or dynamic SQL are used.
--               - Every query is self-contained (CTEs are re-declared per
--                 query) so each block can be run independently or dropped
--                 straight into a Power BI "Get Data > SQL" query.
-- ============================================================================

USE healthcare_commercial_analytics;


-- ============================================================================
-- SECTION 1: Rank ALL HCPs by Total Claims (RANK())
-- Business Question: Which prescribers generate the highest overall claim
-- volume, and how do they rank against every other HCP nationally?
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type,
        SUM(p.Tot_Clms)      AS Total_Claims,
        SUM(p.Tot_Drug_Cst)  AS Total_Drug_Cost,
        SUM(p.Tot_Benes)     AS Total_Beneficiaries
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type
)
SELECT
    Prscrbr_NPI,
    Prscrbr_First_Name,
    Prscrbr_Last_Org_Name,
    Prscrbr_City,
    Prscrbr_State_Abrvtn,
    Prscrbr_Type,
    Total_Claims,
    Total_Drug_Cost,
    Total_Beneficiaries,
    RANK() OVER (ORDER BY Total_Claims DESC) AS Claims_Rank
FROM hcp_claims_summary
ORDER BY Claims_Rank ASC;


-- ============================================================================
-- SECTION 2: Segment HCPs into Tier 1 / Tier 2 / Tier 3 (NTILE(3))
-- Business Question: How can we split the HCP universe into three equal-sized
-- priority tiers for targeting, based on prescribing volume?
-- Tier 1 = Highest-volume prescribers, Tier 3 = Lowest-volume prescribers.
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type,
        SUM(p.Tot_Clms)      AS Total_Claims,
        SUM(p.Tot_Drug_Cst)  AS Total_Drug_Cost,
        SUM(p.Tot_Benes)     AS Total_Beneficiaries
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
)
SELECT
    Prscrbr_NPI,
    Prscrbr_First_Name,
    Prscrbr_Last_Org_Name,
    Prscrbr_City,
    Prscrbr_State_Abrvtn,
    Prscrbr_Type,
    Total_Claims,
    Total_Drug_Cost,
    Total_Beneficiaries,
    CONCAT('Tier ', HCP_Tier) AS Tier_Label
FROM hcp_tiered
ORDER BY HCP_Tier ASC, Total_Claims DESC;


-- ============================================================================
-- SECTION 3: Total Claims, Total Drug Cost, Total Beneficiaries per Tier
-- Business Question: What is the overall commercial footprint (volume, spend,
-- patient reach) contributed by each HCP tier?
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        SUM(p.Tot_Clms)      AS Total_Claims,
        SUM(p.Tot_Drug_Cst)  AS Total_Drug_Cost,
        SUM(p.Tot_Benes)     AS Total_Beneficiaries
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY d.Prscrbr_NPI
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
)
SELECT
    CONCAT('Tier ', HCP_Tier)        AS Tier_Label,
    SUM(Total_Claims)                AS Tier_Total_Claims,
    SUM(Total_Drug_Cost)             AS Tier_Total_Drug_Cost,
    SUM(Total_Beneficiaries)         AS Tier_Total_Beneficiaries
FROM hcp_tiered
GROUP BY HCP_Tier
ORDER BY HCP_Tier ASC;


-- ============================================================================
-- SECTION 4: Average Claims, Average Drug Cost, Average Beneficiaries per Tier
-- Business Question: On a per-HCP basis, how does prescribing behavior differ
-- across tiers? Useful for setting call-plan expectations by tier.
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        SUM(p.Tot_Clms)      AS Total_Claims,
        SUM(p.Tot_Drug_Cst)  AS Total_Drug_Cost,
        SUM(p.Tot_Benes)     AS Total_Beneficiaries
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY d.Prscrbr_NPI
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
)
SELECT
    CONCAT('Tier ', HCP_Tier)                 AS Tier_Label,
    ROUND(AVG(Total_Claims), 2)               AS Avg_Claims_Per_HCP,
    ROUND(AVG(Total_Drug_Cost), 2)            AS Avg_Drug_Cost_Per_HCP,
    ROUND(AVG(Total_Beneficiaries), 2)        AS Avg_Beneficiaries_Per_HCP
FROM hcp_tiered
GROUP BY HCP_Tier
ORDER BY HCP_Tier ASC;


-- ============================================================================
-- SECTION 5: Top 10 HCPs WITHIN Each Tier (DENSE_RANK())
-- Business Question: Within each priority tier, who are the specific top
-- HCPs the sales team should focus on first?
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type,
        SUM(p.Tot_Clms)      AS Total_Claims,
        SUM(p.Tot_Drug_Cst)  AS Total_Drug_Cost,
        SUM(p.Tot_Benes)     AS Total_Beneficiaries
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY
        d.Prscrbr_NPI,
        d.Prscrbr_First_Name,
        d.Prscrbr_Last_Org_Name,
        d.Prscrbr_City,
        d.Prscrbr_State_Abrvtn,
        d.Prscrbr_Type
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
),
hcp_ranked_within_tier AS (
    SELECT
        t.*,
        DENSE_RANK() OVER (
            PARTITION BY t.HCP_Tier
            ORDER BY t.Total_Claims DESC
        ) AS Rank_Within_Tier
    FROM hcp_tiered t
)
SELECT
    CONCAT('Tier ', HCP_Tier)  AS Tier_Label,
    Rank_Within_Tier,
    Prscrbr_NPI,
    Prscrbr_First_Name,
    Prscrbr_Last_Org_Name,
    Prscrbr_City,
    Prscrbr_State_Abrvtn,
    Prscrbr_Type,
    Total_Claims,
    Total_Drug_Cost,
    Total_Beneficiaries
FROM hcp_ranked_within_tier
WHERE Rank_Within_Tier <= 10
ORDER BY HCP_Tier ASC, Rank_Within_Tier ASC;


-- ============================================================================
-- SECTION 6: Number of HCPs in Each Tier
-- Business Question: How many prescribers fall into each tier, to validate
-- tier balance and size territory/call-plan resourcing?
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        SUM(p.Tot_Clms) AS Total_Claims
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY d.Prscrbr_NPI
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
)
SELECT
    CONCAT('Tier ', HCP_Tier)   AS Tier_Label,
    COUNT(Prscrbr_NPI)          AS Number_Of_HCPs
FROM hcp_tiered
GROUP BY HCP_Tier
ORDER BY HCP_Tier ASC;


-- ============================================================================
-- SECTION 7: Total Sales Calls Received by Each Tier
-- Business Question: Is current sales-rep call activity actually aligned
-- with HCP priority tier (i.e., are Tier 1 HCPs receiving the most calls)?
-- LEFT JOIN is used so HCPs with zero CRM interactions are still counted
-- (with 0 calls) rather than dropped from the analysis.
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        SUM(p.Tot_Clms) AS Total_Claims
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY d.Prscrbr_NPI
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
),
hcp_calls_summary AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS Total_Calls_Received
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
)
SELECT
    CONCAT('Tier ', t.HCP_Tier)                          AS Tier_Label,
    SUM(COALESCE(c.Total_Calls_Received, 0))             AS Tier_Total_Sales_Calls
FROM hcp_tiered t
LEFT JOIN hcp_calls_summary c
    ON t.Prscrbr_NPI = c.Prscrbr_NPI
GROUP BY t.HCP_Tier
ORDER BY t.HCP_Tier ASC;


-- ============================================================================
-- SECTION 8: Average Sales Calls per HCP for Each Tier
-- Business Question: On average, how many sales calls does an individual
-- HCP in each tier receive? Helps identify under-served high-value HCPs
-- (e.g., low average calls in Tier 1 signals a targeting gap).
-- ============================================================================
WITH hcp_claims_summary AS (
    SELECT
        d.Prscrbr_NPI,
        SUM(p.Tot_Clms) AS Total_Claims
    FROM hcp_demographics d
    INNER JOIN prescription_data p
        ON d.Prscrbr_NPI = p.Prscrbr_NPI
    GROUP BY d.Prscrbr_NPI
),
hcp_tiered AS (
    SELECT
        h.*,
        NTILE(3) OVER (ORDER BY h.Total_Claims DESC) AS HCP_Tier
    FROM hcp_claims_summary h
),
hcp_calls_summary AS (
    SELECT
        Prscrbr_NPI,
        SUM(Calls_Made) AS Total_Calls_Received
    FROM crm_interactions
    GROUP BY Prscrbr_NPI
)
SELECT
    CONCAT('Tier ', t.HCP_Tier)                                   AS Tier_Label,
    COUNT(t.Prscrbr_NPI)                                          AS Number_Of_HCPs,
    SUM(COALESCE(c.Total_Calls_Received, 0))                      AS Tier_Total_Sales_Calls,
    ROUND(
        SUM(COALESCE(c.Total_Calls_Received, 0)) / COUNT(t.Prscrbr_NPI),
        2
    )                                                              AS Avg_Calls_Per_HCP
FROM hcp_tiered t
LEFT JOIN hcp_calls_summary c
    ON t.Prscrbr_NPI = c.Prscrbr_NPI
GROUP BY t.HCP_Tier
ORDER BY t.HCP_Tier ASC;

-- ============================================================================
-- END OF FILE
-- ============================================================================
