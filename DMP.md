# Data Management Plan (DMP)
**Project:** Macroeconomic Sentiment and Inflation Database  
**Author:** Zahra Younes Pour Langaroudi  
**Institution:** University of Trieste — Data Science and Artificial Intelligence  
**Date:** 2026-07-19  
**Version:** 1.0  

---

## 1. What Data Are We Collecting?

This project combines two categories of data:

**Macroeconomic Time-Series (Structured)**  
Quantitative indicators fetched via REST APIs from:
- **FRED (Federal Reserve Economic Data):** Consumer Price Index (CPI), Industrial Production Index, Unemployment Rate, and Federal Funds Rate — covering the United States from 2007 to 2023.
- **Eurostat SDMX API:** Equivalent macroeconomic indicators for the European Union over the same period.

Data is retrieved as JSON and stored in tabular form. Each record includes a timestamp, indicator code, geographic region, and numeric value.

**Financial News Text (Unstructured)**  
Raw news headlines and article snippets from:
- **Kaggle — FinSen Financial Sentiment Dataset:** CSV files containing financial news text from 2007–2023.
- **Hugging Face — Financial News Multisource:** A large multi-source news corpus stored in Apache Parquet format.

From the unstructured text, a **FinBERT Sentiment Score** (a float between −1 and +1) is derived per article and aggregated by date and region for joining with macroeconomic indicators.

---

## 2. Where Will It Be Stored?

Data is managed across two storage layers following an ELT (Extract, Load, Transform) architecture, strictly separating heavy unstructured text from lightweight structured metrics:

| Layer | Contents | Format / Storage | Location |
|---|---|---|---|
| **Raw Text Data Lake** | Original news CSV & Parquet files (heavy unstructured text) | CSV, Parquet files | `data/raw/news/` (on disk) |
| **Raw Staging Store** | Raw macroeconomic time-series ingested from FRED & Eurostat APIs | Relational / JSON staging tables | PostgreSQL (`staging` schema) |
| **Analytical Store** | Cleaned indicators, derived FinBERT sentiment scores, merged features & views | Relational tables & SQL views | PostgreSQL (`core` schema) |

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

Raw files are **never overwritten**. All transformations are performed by scripts in `scripts/` and their outputs are either written to `data/processed/` or loaded into PostgreSQL.

---

## 3. Who Owns It?

| Source | Owner / Provider | License |
|---|---|---|
| FRED Macroeconomic Data | Federal Reserve Bank of St. Louis | Public domain (U.S. Government) — free for educational use |
| Eurostat Data | European Commission | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| FinSen Kaggle Dataset | Kaggle contributor (`eaglewhl`) | Open educational use (Kaggle terms) |
| HuggingFace Multisource News | `Brianferrell787` via HuggingFace | Open educational use (HuggingFace terms) |
| **Derived dataset (this project)** | Zahra Younes Pour Langaroudi | [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) |

The derived analytical dataset — including sentiment scores, merged features, and SQL views — is the original intellectual contribution of this project and is licensed under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**.

---

## 4. How Will It Be Preserved?

**Separation of raw and derived data:**  
Raw source files in `data/raw/` are treated as immutable. They are never modified after ingestion. All analytical outputs in `data/processed/` and PostgreSQL are fully re-computable from the raw files using the scripts in `scripts/`.

**Reproducibility:**  
- All data ingestion and transformation steps are scripted (Python/SQL).
- PostgreSQL views (not materialized tables where possible) are used for derived metrics, ensuring they stay consistent with the underlying data without duplication.
- API query parameters (date ranges, series IDs) are documented in `scripts/` comments and this DMP.

**Versioning:**  
- The full project, including scripts and metadata, is version-controlled via **Git** and hosted at: https://github.com/zahra-ynp/Advanced-Data-Management
- The dataset version is tracked in `metadata/dataset_metadata.jsonld` (`"version": "1.0"`).

**Retention:**  
Raw data and all scripts will be retained for the duration of the academic program and at least 12 months after project submission, consistent with university research data policies.
