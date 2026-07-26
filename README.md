# Macroeconomic Sentiment and Inflation Database

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Database](https://img.shields.io/badge/Database-MS%20SQL%20Server-red.svg)](https://www.microsoft.com/sql-server/)

**Course:** Advanced Data Management  
**Author:** Zahra Younes Pour Langaroudi  
**Institution:** University of Trieste — M.Sc. in Data Science and Artificial Intelligence  

---

## 📌 Project Overview

This repository implements an end-to-end data engineering and analytics pipeline that integrates **macroeconomic time-series indicators** with **financial news sentiment analysis**. 

By processing raw financial news headlines from 2007 to 2023 using **FinBERT** (a financial domain-specific Transformer model) and joining them with official macroeconomic metrics from **FRED (Federal Reserve Economic Data)** and **Eurostat**, the database enables analytical research on the relationship between public economic sentiment and monetary/inflation trends.

---

## 🏗️ Architecture & Data Pipeline

The pipeline follows a multi-tier data management architecture:

1. **Raw Layer (`data/raw/`)**: Stores original, immutable source files including macroeconomic API responses and financial news text datasets.
2. **Processed Layer (`data/processed/`)**: Caches intermediate FinBERT sentiment checkpoint scores and aggregated article scores.
3. **Core Database Schema (`core`)**: A normalized relational database in MS SQL Server storing:
   - `core_macro_indicators_monthly`: Monthly time-series (CPI, Unemployment Rate, Federal Funds Rate, Industrial Production Index).
   - `core_daily_news`: FinBERT-scored news articles (date, title, source, sentiment score, sentiment label).
4. **Analytics Database Schema (`analytics`)**: Houses dynamic SQL views (`Analytics_Monthly_View`) that aggregate daily news sentiment to monthly levels, map regional sentiment to corresponding economic agencies, and compute Month-over-Month (MoM) economic changes.

---

## 📂 Repository Structure

```text
Advanced-Data-Management/
├── data/
│   ├── raw/                         ← Raw source files (never modified)
│   │   └── news/
│   │       └── FinSen_US_Categorized_Timestamp.csv
│   └── processed/                   ← Derived caches & FinBERT checkpoint outputs
│       └── finbert_article_scores.csv
├── metadata/
│   └── dataset_metadata.jsonld      ← JSON-LD metadata adhering to Schema.org standards
├── scripts/
│   ├── 01_create_schemas.sql        ← SQL: Creates 'core' and 'analytics' schemas
│   ├── 02_build_core_tables.sql      ← SQL: Defines DDL for Core tables
│   ├── 03_create_analytics_view.sql  ← SQL: Creates SQL View for ML feature extraction
│   └── data_prep.ipynb               ← Jupyter Notebook: Ingestion, FinBERT NLP & Database ETL
├── DMP.md                           ← Data Management Plan (DMP)
└── README.md                        ← Project Documentation
```

---

## ⚙️ Prerequisites & Environment Setup

### 1. Software Requirements
- **Python:** Version 3.8 or higher
- **Database:** Microsoft SQL Server (or SQL Server Express / LocalDB)
- **ODBC Driver:** `ODBC Driver 17 for SQL Server` (or Driver 18)
- **Jupyter Environment:** Jupyter Notebook or JupyterLab

### 2. External API Access
- **FRED API Key:** Required for fetching US macroeconomic data. Obtain a free API key from [St. Louis Fed API Key Registration](https://fred.stlouisfed.org/docs/api/api_key.html).

### 3. Python Package Dependencies

Install the required Python packages using `pip`:

```bash
pip install pandas numpy matplotlib sqlalchemy pyodbc fredapi transformers torch tqdm python-dotenv jupyter
```

---

## 🚀 Step-by-Step Guide to Run the Code

### Step 1: Database Setup
1. Open your MS SQL Server instance (e.g., via SSMS or Azure Data Studio).
2. Create a target database named `MacroSentimentDB`:
   ```sql
   CREATE DATABASE MacroSentimentDB;
   ```
3. Execute the SQL scripts in the `scripts/` directory in order:
   - **`01_create_schemas.sql`**: Initializes `core` and `analytics` schemas.
   - **`02_build_core_tables.sql`**: Constructs `core.core_daily_news` and `core.core_macro_indicators_monthly`.
   - **`03_create_analytics_view.sql`**: Builds the analytical feature view `analytics.Analytics_Monthly_View`.

### Step 2: Configure Environment Credentials
1. Open `scripts/data_prep.ipynb`.
2. Update the FRED API Key configuration cell:
   ```python
   FRED_API_KEY = "YOUR_FREE_FRED_API_KEY"
   ```
3. Verify your SQL Server connection parameters:
   ```python
   SERVER   = r'localhost'         # Or your SQL Server instance name
   DATABASE = 'MacroSentimentDB'
   ```

### Step 3: Run the Data Pipeline Notebook
Open `scripts/data_prep.ipynb` and run the cells sequentially to fetch FRED macroeconomic series, populate the database tables, and compute analytics.

> **Note on FinBERT Sentiment Analysis:** The pre-computed sentiment output (`finbert_article_scores.csv`) is already provided in `data/processed/`. The notebook skips heavy FinBERT inference by default (as commented in the code) and directly loads the ready-scored dataset into the database (`core.core_daily_news`).

---

## 📊 Analytics View Output

The resulting view `analytics.Analytics_Monthly_View` provides a clean feature matrix ready for machine learning and economic modeling:

| Feature Column | Type | Description |
|---|---|---|
| `month_date` | Date | 1st day of the month |
| `source_agency` | String | Data provider (`FRED` / `Eurostat`) |
| `country` | String | Geographic region (`US` / `EU`) |
| `avg_monthly_sentiment` | Float | Aggregated FinBERT sentiment score ($-1.0$ to $+1.0$) |
| `cpi_value` | Float | Consumer Price Index value |
| `unemployment_rate` | Float | Unemployment Rate (%) |
| `fed_funds_rate` | Float | Federal Funds Rate (%) |
| `ind_production_value` | Float | Industrial Production Index |
| `cpi_mom` | Float | Derived Month-over-Month CPI change |
| `ind_production_mom` | Float | Derived Month-over-Month Industrial Production change |

---

## 📄 Documentation & Metadata

- **`DMP.md`**: Detailed Data Management Plan covering data collection, storage layers, copyright, preservation, and API query parameters.
- **`metadata/dataset_metadata.jsonld`**: Structured JSON-LD metadata complying with Schema.org standards for open research data.

---

## 📜 License

This project and its derived datasets/views are licensed under the **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)** license. Upstream data remains under the terms of the respective data providers (FRED, Eurostat, Kaggle, HuggingFace).