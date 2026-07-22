-- =====================================================================
-- File:        05_dashboard_kpis.sql
-- Project:     Healthcare Commercial Analytics: Sales Force Effectiveness
--              & HCP Targeting
-- Database:    healthcare_commercial_analytics
-- Purpose:     Summary KPI queries feeding the Power BI dashboard
-- Tables:      hcp_demographics, prescription_data, crm_interactions
--
-- Assumed schema:
--   hcp_demographics(hcp_id, hcp_name, specialty, state, tier)
--   prescription_data(prescription_id, hcp_id, claim_count, drug_cost, beneficiary_count)
--   crm_interactions(interaction_id, hcp_id, rep_id, call_date)
--     -> each row in crm_interactions represents one sales call
-- =====================================================================

USE healthcare_commercial_analytics;


-- =====================================================================
-- 1. OVERALL BUSINESS KPIs
-- Single-row summary card for the dashboard header
-- =====================================================================
WITH hcp_base AS (
    SELECT COUNT(*) AS total_hcps
    FROM hcp_demographics
),
claims_base AS (
    SELECT
        SUM(claim_count)        AS total_claims,
        SUM(drug_cost)          AS total_drug_cost,
        SUM(beneficiary_count)  AS total_beneficiaries
    FROM prescription_data
),
calls_base AS (
    SELECT COUNT(*) AS total_sales_calls
    FROM crm_interactions
)
SELECT
    h.total_hcps,
    c.total_claims,
    c.total_drug_cost,
    c.total_beneficiaries,
    cl.total_sales_calls,
    ROUND(c.total_claims / h.total_hcps, 2)     AS avg_claims_per_hcp,
    ROUND(c.total_drug_cost / h.total_hcps, 2)  AS avg_drug_cost_per_hcp,
    ROUND(cl.total_sales_calls / h.total_hcps, 2) AS avg_calls_per_hcp
FROM hcp_base h
CROSS JOIN claims_base c
CROSS JOIN calls_base cl;


-- =====================================================================
-- 2. TIER DISTRIBUTION
-- HCP count and share of total by tier (Tier 1 / Tier 2 / Tier 3)
-- =====================================================================
SELECT
    tier,
    COUNT(*) AS hcp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hcp_demographics), 2) AS percentage
FROM hcp_demographics
GROUP BY tier
ORDER BY tier;


-- =====================================================================
-- 3. SALES FORCE KPIs
-- Targeting effectiveness: compares each HCP's calls-per-claim ratio
-- against the overall average to flag under/well/over targeted HCPs
-- =====================================================================
WITH hcp_activity AS (
    SELECT
        hd.hcp_id,
        COALESCE(SUM(pd.claim_count), 0) AS total_claims,
        COALESCE(call_counts.total_calls, 0) AS total_calls
    FROM hcp_demographics hd
    LEFT JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
    LEFT JOIN (
        SELECT hcp_id, COUNT(*) AS total_calls
        FROM crm_interactions
        GROUP BY hcp_id
    ) call_counts ON hd.hcp_id = call_counts.hcp_id
    GROUP BY hd.hcp_id, call_counts.total_calls
),
ratios AS (
    SELECT
        hcp_id,
        total_claims,
        total_calls,
        -- calls per claim, guarded against divide-by-zero
        CASE WHEN total_claims = 0 THEN NULL
             ELSE total_calls / total_claims END AS calls_per_claim
    FROM hcp_activity
),
avg_ratio AS (
    SELECT AVG(calls_per_claim) AS overall_avg_ratio
    FROM ratios
    WHERE calls_per_claim IS NOT NULL
),
classified AS (
    SELECT
        r.hcp_id,
        r.total_claims,
        r.total_calls,
        CASE
            WHEN r.calls_per_claim IS NULL THEN 'Well Targeted'
            WHEN r.calls_per_claim < a.overall_avg_ratio * 0.8 THEN 'Under Targeted'
            WHEN r.calls_per_claim > a.overall_avg_ratio * 1.2 THEN 'Over Targeted'
            ELSE 'Well Targeted'
        END AS targeting_status
    FROM ratios r
    CROSS JOIN avg_ratio a
)
SELECT
    targeting_status,
    COUNT(*) AS hcp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hcp_demographics), 2) AS percentage
FROM classified
GROUP BY targeting_status
ORDER BY targeting_status;

-- Claims per Call (overall efficiency metric)
SELECT
    ROUND(SUM(pd.claim_count) / (SELECT COUNT(*) FROM crm_interactions), 2) AS claims_per_call
FROM prescription_data pd;

-- Average Calls per Rep
SELECT
    ROUND(COUNT(*) / COUNT(DISTINCT rep_id), 2) AS avg_calls_per_rep
FROM crm_interactions;


-- =====================================================================
-- 4. MARKET KPIs
-- Top-performing segments by volume and by spend
-- =====================================================================

-- Top Specialty by total claims
SELECT
    hd.specialty,
    SUM(pd.claim_count) AS total_claims
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.specialty
ORDER BY total_claims DESC
LIMIT 1;

-- Top State by total claims
SELECT
    hd.state,
    SUM(pd.claim_count) AS total_claims
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.state
ORDER BY total_claims DESC
LIMIT 1;

-- Highest Drug Cost Specialty
SELECT
    hd.specialty,
    SUM(pd.drug_cost) AS total_drug_cost
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.specialty
ORDER BY total_drug_cost DESC
LIMIT 1;

-- Highest Drug Cost State
SELECT
    hd.state,
    SUM(pd.drug_cost) AS total_drug_cost
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.state
ORDER BY total_drug_cost DESC
LIMIT 1;


-- =====================================================================
-- 5. LEADERBOARDS
-- Ranked lists for dashboard leaderboard visuals
-- =====================================================================

-- Top 10 HCPs by total claims
SELECT
    hd.hcp_id,
    hd.hcp_name,
    hd.specialty,
    hd.state,
    SUM(pd.claim_count) AS total_claims,
    SUM(pd.drug_cost)   AS total_drug_cost
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.hcp_id, hd.hcp_name, hd.specialty, hd.state
ORDER BY total_claims DESC
LIMIT 10;

-- Top 10 States by total claims
SELECT
    hd.state,
    SUM(pd.claim_count) AS total_claims,
    SUM(pd.drug_cost)   AS total_drug_cost
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.state
ORDER BY total_claims DESC
LIMIT 10;

-- Top 10 Specialties by total claims
SELECT
    hd.specialty,
    SUM(pd.claim_count) AS total_claims,
    SUM(pd.drug_cost)   AS total_drug_cost
FROM hcp_demographics hd
JOIN prescription_data pd ON hd.hcp_id = pd.hcp_id
GROUP BY hd.specialty
ORDER BY total_claims DESC
LIMIT 10;
