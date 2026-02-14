# Cross-Channel Paid Media Performance Dashboard

## 📌 Overview

This project unifies advertising performance data from Facebook, Google, and TikTok into a standardized data model to enable cross-channel performance analysis and executive reporting.

The objective was to transform raw multi-platform campaign data into a single, integrated structure and deliver actionable insights through a one-page dashboard.

---

## 🗂 Data Sources

- Facebook Ads
- Google Ads
- TikTok Ads

Each platform dataset contained campaign-level metrics including impressions, clicks, spend, and conversions. Google additionally included revenue (conversion value), which was incorporated into efficiency calculations.

---

## 🏗 Data Modeling Approach

### 1️⃣ Unified Fact Table
Created:

`FACT_PAID_MEDIA_PERFORMANCE`

- Standardized column structure across platforms
- Normalized naming conventions (ad_set / adgroup → ad_group)
- Handled platform-specific fields using NULL where applicable

### 2️⃣ Derived Metrics View
Created:

`VW_PAID_MEDIA_METRICS`

Calculated performance metrics:

- CTR = Clicks / Impressions  
- CPC = Spend / Clicks  
- CPA = Spend / Conversions  
- ROAS = Revenue / Spend  
- Profit = Revenue - Spend  

Additionally implemented platform-level performance ranking using window functions.

---

## 📊 Dashboard Overview

The dashboard provides:

- Executive KPI summary (Spend, Impressions, Clicks, Conversions, CPA)
- Platform comparison analysis
- Platform Efficiency Matrix (CTR vs CPA)
- Campaign-level performance breakdown
- Interactive filters (Date & Platform)

---

## 🧠 Key Insights

- Google demonstrates strong acquisition efficiency with competitive CPA and measurable ROAS.
- TikTok drives the highest volume of impressions and conversions, though at comparatively higher CPA.
- Facebook maintains consistent engagement performance with stable CTR across campaigns.

---

## 🔗 Live Dashboard

https://lookerstudio.google.com/reporting/6c187748-d72c-42bc-8a84-cee3cc48b62a



