# Macroeconomic Sentiment and Inflation Database

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Database](https://img.shields.io/badge/Database-MS%20SQL%20Server-red.svg)](https://www.microsoft.com/sql-server/)

**Course:** Advanced Data Management  
**Author:** Zahra Younes Pour Langaroudi  
**Institution:** University of Trieste — M.Sc. in Data Science and Artificial Intelligence  

---

## Project Overview

This repository implements an end-to-end data engineering and analytics pipeline that integrates **macroeconomic time-series indicators** with **financial news sentiment analysis**. 

By processing raw financial news headlines from 2007 to 2023 using **FinBERT** (a financial domain-specific Transformer model) and joining them with official macroeconomic metrics from **FRED (Federal Reserve Economic Data)** and **Eurostat**, the database enables analytical research on the relationship between public economic sentiment and monetary/inflation trends.

---

## Architecture & Data Pipeline

The pipeline follows a multi-tier data management architecture:

1. **Raw Layer (`data/raw/`)**: Stores original, immutable source files including macroeconomic API responses and financial news text datasets.
2. **Processed Layer (`data/processed/`)**: Caches intermediate FinBERT sentiment checkpoint scores and aggregated article scores.
3. **Core Database Schema (`core`)**: A normalized relational database in MS SQL Server storing:
   - `core_macro_indicators_monthly`: Monthly time-series (CPI, Unemployment Rate, Federal Funds Rate, Industrial Production Index).
   - `core_daily_news`: FinBERT-scored news articles (date, title, source, sentiment score, sentiment label).
4. **Analytics Database Schema (`analytics`)**: Houses dynamic SQL views (`Analytics_Monthly_View`) that aggregate daily news sentiment to monthly levels, map regional sentiment to corresponding economic agencies, and compute Month-over-Month (MoM) economic changes.

---

##  Prerequisites & Environment Setup

### 1. Software Requirements
- **Python:** Version 3.8 or higher
- **Database:** Microsoft SQL Server (or SQL Server Express / LocalDB)

### 2. External API Access
- **FRED API Key:** Required for fetching US macroeconomic data. Obtain a free API key from [St. Louis Fed API Key Registration](https://fred.stlouisfed.org/docs/api/api_key.html).

### 3. Python Package Dependencies

Install the required Python packages using `pip`:

```bash
pip install pandas numpy matplotlib sqlalchemy pyodbc fredapi transformers torch tqdm python-dotenv jupyter
```

---

## Step-by-Step Guide to Run the Code

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

## Documentation & Metadata

- **`DMP.md`**: Detailed Data Management Plan covering data collection, storage layers, copyright, preservation, and API query parameters.
- **`metadata/dataset_metadata.jsonld`**: Structured JSON-LD metadata complying with Schema.org standards for open research data.
- **`metadata/data_dictionary.json`**: Comprehensive data dictionary documenting every database table, view, and file dataset with column-level definitions, data types, constraints, value domains, and business meaning.
- **`metadata/data_lineage.jsonld`**: Provenance and lineage metadata using W3C PROV-O ontology, documenting the complete data flow from external sources through transformation stages to the final analytics layer.

---

## License

This project and its derived datasets/views are licensed under the **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)** license. Upstream data remains under the terms of the respective data providers (FRED, Eurostat, Kaggle, HuggingFace).
