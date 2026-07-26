# Data Management Plan (DMP)
**Project:** Macroeconomic Sentiment and Inflation Database  
**Author:** Zahra Younes Pour Langaroudi  
**Institution:** University of Trieste — Data Science and Artificial Intelligence  
**Date:** 2026-07-19  
**Version:** 2.0

---

## 1. What Data Are We Collecting?

This project combines two categories of data:

**Macroeconomic Time-Series (Structured)**  
Quantitative indicators fetched via REST APIs from:
- **FRED (Federal Reserve Economic Data):** Consumer Price Index (CPI), Industrial Production Index, Unemployment Rate, and Federal Funds Rate — covering the United States from 2007 to 2023.
- **Eurostat SDMX API:** Equivalent macroeconomic indicators for the European Union over the same period.

**Financial News Text (Unstructured)**  
Raw news headlines and article snippets from:
- **Kaggle — FinSen Financial Sentiment Dataset:** CSV files containing financial news text from 2007–2023.
- **Hugging Face — Financial News Multisource:** A large multi-source news corpus stored in Apache Parquet format.

From the unstructured text, a **FinBERT Sentiment Score** (a float between −1 and +1) is derived per article and aggregated by date and region for joining with macroeconomic indicators.

---

## 2. Where Will It Be Stored?

Data flows through four layers, from ingestion to analysis:

| Layer | Contents | Format | Location |
|---|---|---|---|
| **Raw** | News CSV/Parquet files | CSV, Parquet | `data/raw/` (on disk) |
| **Staging** | Macroeconomic indicators loaded from FRED and Eurostat | PostgreSQL tables | Local PostgreSQL instance |
| **Core** | Normalized indicators and FinBERT news sentiment scores | PostgreSQL tables | Local PostgreSQL instance |
| **Analytics** | Monthly aggregated sentiment joined with indicators; MOM inflation derived metrics | PostgreSQL views | Local PostgreSQL instance |

**Directory structure:**
```
Advanced-Data-Management/
├── data/
│   ├── raw/          ← original, never modified
│   │   ├── fred/
│   │   ├── eurostat/
│   │   └── news/
│   └── processed/    ← derived outputs (re-computable)
├── metadata/
│   └── dataset_metadata.jsonld
├── scripts/
├── DMP.md
└── README.md
```

Raw files are **never overwritten**. All transformations are scripted and reproducible — staging and core tables are populated from raw files, and analytics are defined as PostgreSQL views recomputed on demand.

---

## 3. Who Owns It?

The project is publicly shared via **GitHub**: https://github.com/zahra-ynp/Advanced-Data-Management

All scripts, metadata, and processed outputs are available under **CC BY-NC 4.0**. Raw source data is not redistributed — it is governed by its respective upstream licenses and can be reproduced using the provided ingestion scripts.

| Source | Owner / Provider | License |
|---|---|---|
| FRED Macroeconomic Data | Federal Reserve Bank of St. Louis | Public domain (U.S. Government) — free for educational use |
| Eurostat Data | European Commission | CC BY 4.0 |
| FinSen Kaggle Dataset | Kaggle contributor (`eaglewhl`) | Open educational use (Kaggle terms) |
| HuggingFace Multisource News | `Brianferrell787` via HuggingFace | Open educational use (HuggingFace terms) |
| **Derived dataset (this project)** | Zahra Younes Pour Langaroudi | CC BY-NC 4.0 |

The derived analytical dataset — including sentiment scores, merged features, and SQL views — is the original intellectual contribution of this project and is licensed under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**.

---

## 4. How Will It Be Preserved?

**Documentation:**  
All datasets are described in `metadata/dataset_metadata.jsonld` — a structured JSON-LD file following the schema.org vocabulary, covering title, creator, license, temporal coverage, source URLs, format, and version. This DMP serves as the complementary human-readable documentation.

**Separation of raw and derived data:**  
Raw source files in `data/raw/` are treated as immutable. They are never modified after ingestion. All analytical outputs in `data/processed/` and PostgreSQL are fully re-computable from the raw files using the scripts in `scripts/`.

**Reproducibility:**  
- All data ingestion and transformation steps are scripted (Python/SQL).
- PostgreSQL views (not materialized tables where possible) are used for derived metrics, ensuring they stay consistent with the underlying data without duplication.
- API query parameters (date ranges, series IDs) are documented in `scripts/` comments and this DMP.

**Retention:**  
Raw data and all scripts will be retained for the duration of the academic program and at least 12 months after project submission, consistent with university research data policies.

---

## Appendix: Core API Query Parameters

To ensure full reproducibility of the macroeconomic data extraction, the ingestion scripts utilize the following parameters, endpoints, and credential management standards:

### 1. Authentication & Security
* **Credential Management:** API keys are never stored in source code or metadata. Ingestion scripts load credentials securely from local environment variables (`.env`).
* **Access Requirements:** FRED requires a free user API key (registered via St. Louis Fed). Eurostat API endpoints used in this pipeline are publicly accessible without authentication.

### 2. FRED (US Macroeconomic Data)
* **Global Date Range:** `2007-01-01` to `2023-12-31`
* **Series IDs:** `CPIAUCSL` (CPI Inflation), `UNRATE` (Unemployment Rate), `FEDFUNDS` (Federal Funds Rate), `INDPRO` (Industrial Production Index)
* **Sample API Request:**
  ```text
  https://api.stlouisfed.org/fred/series/observations?series_id=CPIAUCSL&file_type=json&api_key=YOUR_API_KEY
  
**Eurostat (EU) Parameters:**
*   **Dataset Code:** `prc_hicp_midx` (Harmonised Index of Consumer Prices)
*   **Format:** `JSON`
*   **Geography Filter:** `IT` (Italy) and `EA` (Euro Area)
*   **Sample API Request:**
  ```text
  https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/dataflow/ESTAT/prc_hicp_midx/1.0?format=JSON

