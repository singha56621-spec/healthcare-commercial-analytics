# Healthcare Commercial Analytics: Sales Force Effectiveness, HCP Segmentation & Market Insights

<p align="center">

![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![MySQL](https://img.shields.io/badge/MySQL-Database-orange?logo=mysql)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Analysis-150458?logo=pandas)



</p>

An end-to-end healthcare commercial analytics solution that analyzes physician prescribing behavior, evaluates sales force effectiveness, segments Healthcare Providers (HCPs) based on commercial potential, and uncovers regional market opportunities to support data-driven decision-making for pharmaceutical organizations.

---

## Dashboard Preview

<p align="center">
<img width="922" height="530" alt="dashboard_page1" src="https://github.com/user-attachments/assets/965ae3f9-e902-4cd7-9b2e-82eedf67e79c" />




---

# 📑 Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Business Objectives](#business-objectives)
- [Dataset](#dataset)
- [Technology Stack](#technology-stack)
- [Project Workflow](#project-workflow)
- [Python Analysis](#python-analysis)
- [SQL Business Analysis](#sql-business-analysis)
- [Power BI Dashboard](#power-bi-dashboard)
- [Key Business Insights and Business Recommendations](#key-business-insights-and-Business-Recommendations)



# Project Overview

Pharmaceutical organizations rely on field sales teams to engage Healthcare Providers (HCPs), promote products, and improve market adoption. However, commercial success depends not only on the number of sales interactions but also on identifying the right physicians, understanding prescribing behavior, and allocating commercial resources effectively.

This project demonstrates an end-to-end Healthcare Commercial Analytics solution built using Python, MySQL, Power BI, and statistical analysis. Starting from raw CMS Medicare prescription data, the project simulates a real-world pharmaceutical commercial analytics workflow by integrating physician prescribing behavior with sales force interactions to generate actionable business insights.

The solution evaluates physician performance, measures sales force effectiveness, segments Healthcare Providers into commercial tiers, and identifies regional market opportunities through an interactive Power BI dashboard. The objective is to transform healthcare data into business intelligence that supports evidence-based commercial decision-making.

Unlike a traditional reporting dashboard, this project focuses on solving business problems by combining data engineering, SQL analytics, statistical analysis, and business visualization into a single analytical workflow.

# Business Problem

Pharmaceutical companies invest substantial resources in engaging Healthcare Providers (HCPs) through field sales representatives. However, commercial success depends not only on increasing sales activity but also on ensuring that sales efforts are directed toward physicians with the highest commercial potential.

Without a data-driven approach, organizations face several challenges:

- High-value physicians may receive insufficient commercial engagement.
- Low-value physicians may consume excessive sales resources.
- Regional prescribing trends may remain unidentified.
- Commercial decisions may rely on intuition rather than data.
- Sales teams may struggle to prioritize physicians based on business impact.

These challenges can lead to inefficient resource allocation, missed market opportunities, and reduced commercial effectiveness.

This project addresses these challenges by integrating physician prescribing behavior, commercial sales interactions, and market performance into a unified analytics solution that supports evidence-based decision-making.

# Business Objectives

The primary objective of this project is to develop an end-to-end healthcare commercial analytics solution that enables pharmaceutical organizations to make data-driven commercial decisions by analyzing physician prescribing behavior and sales force performance.

The project aims to:

- Identify high-value Healthcare Providers (HCPs) based on prescribing activity.
- Evaluate sales force effectiveness by comparing physician engagement with prescription performance.
- Segment physicians into commercial tiers using SQL-based ranking techniques.
- Analyze regional and specialty-level prescribing trends.
- Identify commercial opportunities across products, specialties, and geographic regions.
- Build an interactive Power BI dashboard for executive reporting and business exploration.
- Generate actionable business insights and recommendations to support commercial strategy.

# Project Workflow

The project follows a complete healthcare commercial analytics workflow, starting from raw prescription data and ending with actionable business insights through an interactive Power BI dashboard.

```text
                 CMS Medicare Dataset
                          │
                          ▼
         Python Data Cleaning & Preprocessing
                          │
                          ▼
            Feature Engineering & Data Preparation
                          │
                          ▼
                 MySQL Database Integration
                          │
                          ▼
              SQL Business Analytics & KPI Analysis
                          │
                          ▼
      Statistical Analysis & HCP Segmentation
                          │
                          ▼
         Interactive Power BI Dashboard (4 Pages)
                          │
                          ▼
 Business Insights & Commercial Recommendations
```
# Dataset

This project is built using the **CMS Medicare Provider Utilization and Payment Data**, a publicly available healthcare dataset containing physician-level prescription information.

The dataset includes prescribing activity across multiple healthcare providers, along with drug utilization, prescription claims, beneficiaries, physician specialties, and geographic information.

To simulate a real-world pharmaceutical commercial analytics environment, an additional **synthetic CRM interaction dataset** was generated. This dataset represents sales representative visits to physicians and enables analysis of commercial engagement alongside prescribing behavior.

### Dataset Components

| Dataset | Description |
|---------|-------------|
| **hcp_demographics** | Physician demographic information including specialty and state. |
| **prescription_data** | Prescription claims, beneficiaries, and drug cost for each physician. |
| **drug_reference** | Drug identifiers with brand and generic names. |
| **crm_interactions** *(Synthetic)* | Simulated sales representative interactions with physicians for commercial analytics. |
| **hcp_tier** *(SQL Output)* | Derived table segmenting physicians into Tier 1, 2, or 3 based on prescription volume. |
| **hcp_targeting_status** *(SQL Output)* | Derived table comparing actual CRM visits to target tiers to identify Over/Under-targeted physicians. |

```text
hcp_demographics
       │
       ▼
prescription_data
       ▲
       │
drug_reference

crm_interactions

hcp_tier

hcp_targeting_status
```
> **Note:** CRM interaction data was synthetically generated for educational purposes because real pharmaceutical sales interaction data is not publicly available.

# Technology Stack

| Category | Technologies |
|-----------|--------------|
| **Programming Language** | Python |
| **Database** | MySQL |
| **Data Analysis** | Pandas, NumPy |
| **Business Intelligence** | Power BI |
| **Development Environment** | Jupyter Notebook, VS Code |

## Project Components

| Component | Description |
|-----------|-------------|
| **Python** | Data cleaning, preprocessing, feature engineering, and exploratory data analysis. |
| **MySQL** | Data storage, business analysis, physician segmentation, and KPI generation using advanced SQL. |
| **Statistics** | Descriptive analysis and statistical validation of prescribing behavior. |
| **Power BI** | Interactive dashboard for commercial performance, sales force effectiveness, HCP segmentation, and market insights. |


# Python Analysis

Python was used to clean, preprocess, and prepare the healthcare prescription data before loading it into MySQL for business analysis. It also supported exploratory data analysis (EDA) to better understand prescribing patterns and data quality.

### Key Activities

- Cleaned and preprocessed the raw CMS Medicare prescription dataset.
- Prepared structured datasets for MySQL database integration.
- Generated a synthetic CRM interactions dataset to simulate pharmaceutical sales representative visits.
- Performed Exploratory Data Analysis (EDA) to identify prescribing trends, specialty distribution, regional patterns, and data quality issues.
- Exported processed datasets for SQL analysis and Power BI reporting.

### Python Libraries Used

| Library | Purpose |
|----------|---------|
| **Pandas** | Data cleaning, preprocessing, and transformation |
| **NumPy** | Numerical operations and data manipulation |
| **Matplotlib** | Exploratory data visualization (EDA) |


# SQL Business Analysis

SQL was used to transform the prepared healthcare data into actionable business insights. Using joins, Common Table Expressions (CTEs), window functions, aggregations, and ranking techniques, the project answered key commercial questions related to physician performance, sales force effectiveness, and market opportunities.

### Business Analyses Performed

| Analysis | Business Objective |
|----------|--------------------|
| **Data Quality Validation** | Verified data completeness, uniqueness, and consistency before analysis. |
| **Sales Force Effectiveness** | Evaluated sales representative engagement and identified physicians with high commercial potential based on prescribing activity. |
| **HCP Segmentation** | Segmented physicians into Tier 1, Tier 2, and Tier 3 groups using prescription claims to support commercial prioritization. |
| **Market Performance Analysis** | Compared prescribing trends across specialties, states, and drugs to identify high-performing markets. |

### SQL Concepts Applied

- Joins
- Common Table Expressions (CTEs)
- Window Functions (`NTILE`, `RANK`)
- Aggregate Functions (`SUM`, `AVG`, `COUNT`)
- `GROUP BY` and `HAVING`
- Conditional Logic (`CASE`)


### Project SQL Files

| SQL File | Purpose |
|----------|---------|
| **01_data_quality.sql** | Validated data quality and prepared the dataset for analysis. |
| **02_sales_force_effectiveness.sql** | Analyzed commercial engagement and generated HCP targeting status. |
| **03_hcp_segmentation.sql** | Segmented physicians into Tier 1, Tier 2, and Tier 3 using SQL window functions. |
| **04_market_performance_analysis.sql** | Evaluated physician, specialty, state, and drug performance. |
| **05_create_hcp_tier_table.sql** | Created the final HCP tier table for Power BI reporting. |


# Power BI Dashboard

An interactive Power BI dashboard was developed to transform SQL outputs into business insights that support commercial decision-making. The dashboard enables users to explore physician performance, sales force effectiveness, HCP prioritization, and regional market trends through dynamic filters and KPIs.

The dashboard consists of four interconnected pages designed to answer different business questions.

## Dashboard Pages

| Dashboard | Business Purpose |
|-----------|------------------|
| **Commercial Performance Overview** | Provides a high-level view of physician activity, prescription claims, drug cost, beneficiaries, and regional performance. |
| **Sales Force Effectiveness** | Evaluates sales representative engagement, identifies high-opportunity physicians, and highlights targeting efficiency. |
| **HCP Segmentation & Targeting** | Segments physicians into Tier 1, Tier 2, and Tier 3 based on prescribing activity to support commercial prioritization. |
| **Commercial Opportunity & Market Insights** | Identifies high-performing specialties, states, and drugs to uncover potential growth opportunities. |

## Key Dashboard Features

- Interactive filtering by **State**, **Physician Specialty**, **Drug**, and **HCP Tier**.
- Executive KPIs for prescription claims, drug cost, beneficiaries, physician count, and sales activity.
- Drill-down analysis across specialties, regions, physicians, and products.
- Business-focused visualizations for commercial performance, HCP targeting, and market opportunity analysis.

## Dashboard Preview
| Page | Preview |
|------|---------|
| **Commercial Performance Overview** | <img width="922" height="530" alt="dashboard_page1" src="https://github.com/user-attachments/assets/500159ee-6ed3-44b6-bb76-93f35a20f9b6" /> |
| **Sales Force Effectiveness** | <img width="922" height="527" alt="dashboard_page2" src="https://github.com/user-attachments/assets/e4cdc8bc-b7eb-4f9e-8514-26ab5ec95730" /> |
| **HCP Segmentation & Targeting** | <img width="921" height="535" alt="dashboard_page3" src="https://github.com/user-attachments/assets/252b6b4c-996d-4efb-97b9-f037f89a698e" /> |
| **Commercial Opportunity & Market Insights** | <img width="922" height="467" alt="dashboard_page4" src="https://github.com/user-attachments/assets/cb792e9f-3f3e-4cff-a51a-69e3b14982ec" /> |


# Business Insights and Recommendations

The analysis identified several commercial opportunities that can help pharmaceutical organizations improve physician engagement, optimize sales force efforts, and make data-driven commercial decisions.

| Business Insight | Business Recommendation |
|------------------|-------------------------|
| High-prescribing physicians contribute disproportionately to overall prescription volume, making them priority targets for commercial engagement. | Prioritize **Tier 1 physicians** for targeted sales engagement and relationship-building activities. |
| Physician prescribing behavior varies across specialties and states, indicating that commercial opportunities differ by market. | Tailor commercial strategies based on **specialty** and **geographic region** instead of using a uniform outreach approach. |
| HCP segmentation helps identify physicians with the highest commercial potential based on prescribing activity. | Allocate sales resources using **data-driven HCP tiers** to improve targeting efficiency and resource utilization. |
| Comparing prescribing activity with sales interactions highlights physicians who may be under-engaged despite strong commercial potential. | Regularly review high-potential but under-engaged physicians and adjust sales coverage to maximize commercial impact. |
| Interactive dashboards enable continuous monitoring of physician performance, regional trends, and commercial KPIs. | Use the dashboard for periodic business reviews to support data-driven planning, territory optimization, and performance tracking. |

