-- ============================================================================
-- Script Name : 02_create_tables.sql
-- Project     : Healthcare Commercial Analytics
-- Database    : healthcare_commercial_analytics
-- Purpose     : Core relational schema for the Healthcare Commercial
--               Analytics portfolio project.
-- DBMS        : MySQL 8.0+
-- ============================================================================
-- Design Notes:
--   1. hcp_demographics  -> Dimension table: one row per Healthcare Provider,
--                           keyed by NPI.
--   2. drug_reference    -> Dimension table: one row per drug, keyed by a
--                           surrogate Drug_ID.
--   3. prescription_data -> Fact table: prescribing activity per HCP/drug.
--   4. crm_interactions  -> Fact table: rep visits/calls per HCP.
--
--   Foreign keys link both fact tables back to hcp_demographics, and
--   prescription_data to drug_reference. InnoDB is used to support FK
--   constraints.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table 1: hcp_demographics
-- Dimension table holding demographic details for each Healthcare Provider.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hcp_demographics (
    Prscrbr_NPI            VARCHAR(20)  NOT NULL COMMENT 'National Provider Identifier (Primary Key)',
    Prscrbr_First_Name     VARCHAR(100)          COMMENT 'Prescriber first name',
    Prscrbr_Last_Org_Name  VARCHAR(100)          COMMENT 'Prescriber last name or organization name',
    Prscrbr_City           VARCHAR(100)          COMMENT 'Prescriber city',
    Prscrbr_State_Abrvtn   CHAR(2)               COMMENT 'Prescriber state (2-letter abbreviation)',
    Prscrbr_Type           VARCHAR(100)          COMMENT 'Prescriber specialty / provider type',
    PRIMARY KEY (Prscrbr_NPI)
);

-- ----------------------------------------------------------------------------
-- Table 2: drug_reference
-- Dimension table mapping Drug_ID to brand and generic drug names.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drug_reference (
    Drug_ID     INT          NOT NULL COMMENT 'Surrogate primary key for the drug',
    Brnd_Name   VARCHAR(255)          COMMENT 'Brand (trade) name of the drug',
    Gnrc_Name   VARCHAR(255)          COMMENT 'Generic name of the drug',
    PRIMARY KEY (Drug_ID)
);

-- ----------------------------------------------------------------------------
-- Table 3: prescription_data
-- Fact table capturing claims, cost, and beneficiaries per HCP/drug pairing.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS prescription_data (
    Prescription_ID  INT             NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
    Prscrbr_NPI      VARCHAR(20)     NOT NULL                COMMENT 'FK to hcp_demographics.Prscrbr_NPI',
    Drug_ID          INT             NOT NULL                COMMENT 'FK to drug_reference.Drug_ID',
    Tot_Clms         INT                                     COMMENT 'Total number of claims',
    Tot_Drug_Cst     DECIMAL(14,2)                           COMMENT 'Total drug cost',
    Tot_Benes        INT                                     COMMENT 'Total number of unique beneficiaries',
    PRIMARY KEY (Prescription_ID),
    KEY idx_prescription_npi (Prscrbr_NPI),
    KEY idx_prescription_drug (Drug_ID),
    CONSTRAINT fk_prescription_hcp
        FOREIGN KEY (Prscrbr_NPI) REFERENCES hcp_demographics (Prscrbr_NPI)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_prescription_drug
        FOREIGN KEY (Drug_ID) REFERENCES drug_reference (Drug_ID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ----------------------------------------------------------------------------
-- Table 4: crm_interactions
-- Fact table capturing rep visits/calls logged against each HCP.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crm_interactions (
    Interaction_ID  INT          NOT NULL AUTO_INCREMENT COMMENT 'Surrogate primary key',
    Rep_ID          VARCHAR(20)                           COMMENT 'Sales/medical rep identifier',
    Prscrbr_NPI     VARCHAR(20)  NOT NULL                 COMMENT 'FK to hcp_demographics.Prscrbr_NPI',
    Visit_Date      DATE                                  COMMENT 'Date of the visit/interaction',
    Calls_Made      INT                                   COMMENT 'Number of calls made during this interaction',
    PRIMARY KEY (Interaction_ID),
    KEY idx_crm_npi (Prscrbr_NPI),
    CONSTRAINT fk_crm_hcp
        FOREIGN KEY (Prscrbr_NPI) REFERENCES hcp_demographics (Prscrbr_NPI)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ;


-- ============================================================================
-- End of Script
-- ============================================================================
