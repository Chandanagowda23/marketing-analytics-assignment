-- ============================================================
-- Senior Marketing Analyst - Technical Assignment
-- Cross-Channel Paid Media Unified Model (Snowflake SQL)
--
-- What this script does:
--   1) Builds a unified fact table across Facebook, Google, TikTok
--   2) Builds a metrics + platform ranking view for dashboarding
--
-- Assumptions:
--   - Raw tables already exist in MARKETING.PUBLIC:
--       RAW_FACEBOOK_CAMPAIGN_PERFORMANCE
--       RAW_GOOGLE_CAMPAIGN_PERFORMANCE
--       RAW_TIKTOK_CAMPAIGN_PERFORMANCE
--   - Column names match the provided CSV schemas.
--
-- Notes on platform-specific fields:
--   - Google has REVENUE (CONVERSION_VALUE). Facebook/TikTok do not -> REVENUE = NULL.
--   - Facebook/TikTok have VIDEO_VIEWS. Google does not -> VIDEO_VIEWS = NULL.
-- ============================================================

USE DATABASE MARKETING;
USE SCHEMA PUBLIC;

-- -------------------------------------------------------
-- 1) Unified fact table: FACT_PAID_MEDIA_PERFORMANCE
-- -------------------------------------------------------
CREATE OR REPLACE TABLE FACT_PAID_MEDIA_PERFORMANCE AS

-- Facebook
SELECT
    DATE,
    'Facebook' AS PLATFORM,
    CAMPAIGN_ID,
    CAMPAIGN_NAME,
    AD_SET_ID   AS AD_GROUP_ID,
    AD_SET_NAME AS AD_GROUP_NAME,
    IMPRESSIONS,
    CLICKS,
    SPEND,
    CONVERSIONS,
    NULL::NUMBER(18,2) AS REVENUE,
    VIDEO_VIEWS
FROM RAW_FACEBOOK_CAMPAIGN_PERFORMANCE

UNION ALL

-- Google
SELECT
    DATE,
    'Google' AS PLATFORM,
    CAMPAIGN_ID,
    CAMPAIGN_NAME,
    AD_GROUP_ID,
    AD_GROUP_NAME,
    IMPRESSIONS,
    CLICKS,
    COST AS SPEND,
    CONVERSIONS,
    CONVERSION_VALUE AS REVENUE,
    NULL::NUMBER(38,0) AS VIDEO_VIEWS
FROM RAW_GOOGLE_CAMPAIGN_PERFORMANCE

UNION ALL

-- TikTok
SELECT
    DATE,
    'TikTok' AS PLATFORM,
    CAMPAIGN_ID,
    CAMPAIGN_NAME,
    ADGROUP_ID   AS AD_GROUP_ID,
    ADGROUP_NAME AS AD_GROUP_NAME,
    IMPRESSIONS,
    CLICKS,
    COST AS SPEND,
    CONVERSIONS,
    NULL::NUMBER(18,2) AS REVENUE,
    VIDEO_VIEWS
FROM RAW_TIKTOK_CAMPAIGN_PERFORMANCE
;

-- -------------------------------------------------------
-- 2) Dashboard view: VW_PAID_MEDIA_METRICS
--    Includes metrics + platform-level ranks.
-- -------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAID_MEDIA_METRICS AS
WITH base AS (
    SELECT
        f.*,
        f.CLICKS / NULLIF(f.IMPRESSIONS, 0) AS CTR,
        f.SPEND  / NULLIF(f.CLICKS, 0)      AS CPC,
        f.SPEND  / NULLIF(f.CONVERSIONS, 0) AS CPA,
        COALESCE(f.REVENUE, 0) - f.SPEND            AS PROFIT,
        COALESCE(f.REVENUE, 0) / NULLIF(f.SPEND, 0) AS ROAS
    FROM FACT_PAID_MEDIA_PERFORMANCE f
),

platform_agg AS (
    SELECT
        PLATFORM,
        SUM(CLICKS) / NULLIF(SUM(IMPRESSIONS), 0) AS PLATFORM_CTR,
        SUM(SPEND)  / NULLIF(SUM(CLICKS), 0)      AS PLATFORM_CPC,
        SUM(SPEND)  / NULLIF(SUM(CONVERSIONS), 0) AS PLATFORM_CPA
    FROM FACT_PAID_MEDIA_PERFORMANCE
    GROUP BY PLATFORM
),

platform_ranks_step1 AS (
    SELECT
        PLATFORM,
        PLATFORM_CTR,
        PLATFORM_CPC,
        PLATFORM_CPA,
        RANK() OVER (ORDER BY PLATFORM_CTR DESC) AS CTR_RANK,
        RANK() OVER (ORDER BY PLATFORM_CPC ASC)  AS CPC_RANK,
        RANK() OVER (ORDER BY PLATFORM_CPA ASC)  AS CPA_RANK
    FROM platform_agg
),

platform_ranks AS (
    SELECT
        *,
        (CTR_RANK + CPC_RANK + CPA_RANK) AS TOTAL_SCORE,
        RANK() OVER (ORDER BY (CTR_RANK + CPC_RANK + CPA_RANK) ASC) AS OVERALL_PLATFORM_RANK
    FROM platform_ranks_step1
)

SELECT
    b.*,
    r.PLATFORM_CTR,
    r.PLATFORM_CPC,
    r.PLATFORM_CPA,
    r.CTR_RANK,
    r.CPC_RANK,
    r.CPA_RANK,
    r.TOTAL_SCORE,
    r.OVERALL_PLATFORM_RANK
FROM base b
JOIN platform_ranks r
  ON b.PLATFORM = r.PLATFORM
;

-- -------------------------------------------------------
-- Optional validation queries (uncomment to run)
-- -------------------------------------------------------
-- SELECT PLATFORM, COUNT(*) AS ROWS
-- FROM FACT_PAID_MEDIA_PERFORMANCE
-- GROUP BY PLATFORM
-- ORDER BY PLATFORM;

-- SELECT PLATFORM,
--        PLATFORM_CTR, PLATFORM_CPC, PLATFORM_CPA,
--        CTR_RANK, CPC_RANK, CPA_RANK,
--        TOTAL_SCORE, OVERALL_PLATFORM_RANK
-- FROM VW_PAID_MEDIA_METRICS
-- GROUP BY 1,2,3,4,5,6,7,8,9
-- ORDER BY OVERALL_PLATFORM_RANK;
