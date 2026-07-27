# Data Management Plan (DMP)

**Project:** Macroeconomic Sentiment and Inflation Database

**Author:** Zahra Younes Pour Langaroudi

**Institution:** University of Trieste - Data Science and Artificial Intelligence

**Date:** 2026-07-27

**Version:** 3.0

---

## 1. Scope and Data Collected

The project combines macroeconomic time-series data with financial-news text to support analysis of the relationship between economic conditions and news sentiment. The repository includes a normalized database design, region-aware analytics, role-based access, asset examples, and a Streamlit presentation layer around that analytical dataset.

### 1.1 Macroeconomic time series

Quantitative indicators are acquired from official REST APIs for the period 2007-2023:

- **FRED (Federal Reserve Economic Data):** `CPIAUCSL` (Consumer Price Index), `UNRATE` (Unemployment Rate), `FEDFUNDS` (Effective Federal Funds Rate), and `INDPRO` (Industrial Production Index) for the United States.
- **Eurostat SDMX API:** European macroeconomic observations, including the Harmonised Index of Consumer Prices, for the European Union/Euro Area and Italy where available.

The database stores observations in long format: one row per month, source agency, and indicator. This avoids adding a new physical column whenever an indicator is introduced.

### 1.2 Financial-news text

The unstructured sources are:

- **Kaggle - FinSen Financial Sentiment Dataset:** financial-news headlines and article content supplied as CSV files.
- **Hugging Face - Financial News Multisource:** a multi-source news corpus distributed in Apache Parquet format.

FinBERT produces an article-level sentiment label and a score between -1 and +1, calculated as `P(positive) - P(negative)`. The analytical views aggregate these scores by month and region before joining them to macroeconomic observations.

### 1.3 Application-supporting data

The current repository also contains limited supporting records used by the Streamlit application:

- users, password hashes and salts, roles, companies, and scoped access grants;
- example financial assets with class, region, company, market value, currency, and valuation date.

These records support authentication, authorization, and demonstration of the dashboard.

---

## 2. Data Architecture and Storage Layers

The current implementation uses six logical layers. The first two are file-based; the remaining layers are implemented in Microsoft SQL Server or in the Streamlit application.

| Layer | Purpose | Main objects or location | Persistence |
|---|---|---|---|
| **Raw** | Preserve source material without modification and retain a traceable origin for each article. | `data/raw/` (CSV, Parquet, and downloaded/API source material where retained) | Persistent files |
| **Processed** | Store reproducible intermediate results and avoid repeating expensive model inference. | `data/processed/finbert_article_scores.csv` and other generated checkpoints | Persistent derived files |
| **Core** | Hold cleaned, normalized, queryable facts and reference data. | SQL Server schema `core` | Persistent tables |
| **Analytics** | Join, aggregate, calculate month-over-month changes, and reshape data for analysis and dashboards. | SQL Server schema `analytics` | Recomputable views |
| **Access and governance** | Authenticate users and define role-, company-, and region-scoped permissions. | SQL Server schema `auth` | Persistent tables and views |
| **Application** | Present authorized analytics, news content, and asset information without creating a separate analytical copy. | `streamlit_app.py` | Runtime presentation layer |

### 2.1 Raw layer

Raw files are treated as immutable. The database column `core.daily_news.lake_pointer_url` links an ingested news record back to its raw file. The application accepts only paths that resolve inside the project's `data/` directory, limiting accidental access to files elsewhere on the host.

### 2.2 Processed layer

Processed files contain deterministic or computationally expensive intermediate results. In particular, the precomputed FinBERT article scores serve as a checkpoint so the pipeline can be rerun without repeating model inference. Processed files remain derived data: they may be regenerated from the raw inputs.

### 2.3 Core database layer

The `core` schema is the system of record for normalized analytical data and shared reference entities.

| Table | Granularity and role | Important relationships |
|---|---|---|
| `core.source_regions` | One row per supported geography (`US`, `EU`, `IT`, `GLB`, `APAC`, `ME`, `LATAM`); stores code, name, and country/continent type. | Referenced by news, source agencies, access grants, and assets. |
| `core.source_agencies` | One row per macroeconomic provider; currently seeds FRED and Eurostat. | Each agency belongs to one region through `region_id`. |
| `core.indicators` | One row per indicator definition; currently seeds CPI, unemployment, federal funds, and industrial production codes and units. | Referenced by monthly observations. |
| `core.monthly_macro_indicators` | One row per month, agency, and indicator, with a numeric `indicator_value`. | Unique key `(month_date, agency_id, indicator_id)` prevents duplicate observations. |
| `core.daily_news` | One row per scored article, including publication date, title, source, region, score, label, and raw-file pointer. | Optional `region_id` enables regional sentiment aggregation and traceability. |
| `core.assets` | One row per example/company asset as of a valuation date. | Optional links to `core.source_regions` and `auth.companies`; indexed by date and region. |

The normalized structure separates descriptive entities from facts. For example, agency names and indicator units are stored once, while the monthly fact table stores only their identifiers and observed values.

### 2.4 Analytics layer

Analytics objects are views rather than duplicated tables, so outputs stay synchronized with the core data.

| View | Grain | Purpose |
|---|---|---|
| `analytics.Monthly_View` | One row per month, region, source agency, and indicator | Long-format research view. It aggregates article sentiment monthly, joins sentiment to macroeconomic data through the agency's region, and calculates `indicator_mom` with `LAG` within each agency/indicator series. |
| `analytics.Monthly_Region_Wide_View` | One row per month and region | Dashboard-ready view. It pivots the four indicator codes into named value and month-over-month columns while retaining average monthly sentiment and region attributes. |

Month-over-month values are computed over the complete macroeconomic series before the sentiment join. This prevents missing-news months from incorrectly becoming the comparison baseline.


### 2.5 Access and governance layer

The `auth` schema supports application access without mixing identity records into analytical tables.

| Object | Type | Purpose |
|---|---|---|
| `auth.roles` | Table | Defines `admin`, `general`, and `company` roles. |
| `auth.users` | Table | Stores unique usernames/emails, salted password hashes, active status, and basic profile fields. |
| `auth.companies` | Table | Stores company identities used for company-scoped access and assets. |
| `auth.user_access` | Table | Bridge table assigning a role to a user, optionally scoped to a company and/or region; duplicate grants are blocked by a unique constraint. |
| `auth.vw_user_login` | View | Exposes only the fields needed by the application login flow. |
| `auth.vw_user_permissions` | View | Expands each access grant with user, role, company, and region descriptions. |
| `auth.vw_user_access_summary` | View | Produces an administrative summary of roles, grant counts, companies, and regions per user. |

The Streamlit application verifies PBKDF2-SHA256 hashes and retains compatibility with the project's legacy salted SHA-256 records. Region filters are applied to analytics and news queries. Asset access is derived from the user's admin/company grants and their region/company scope.

### 2.6 Application layer

`streamlit_app.py` is a read-oriented presentation layer over SQL Server and the raw-news files. It:

- authenticates users through `auth.vw_user_login`;
- obtains authorization scope from `auth.vw_user_permissions`;
- reads regional time series from `analytics.Monthly_Region_Wide_View`;
- reads article metadata from `core.daily_news` and resolves full article content through the stored raw-file pointer;
- displays asset information from `core.assets` subject to the user's grants.

---

## 3. Data Flow and Transformations

1. Source files and API responses are acquired and retained in, or reproducibly associated with, the raw layer.
2. Dates, identifiers, regions, and numerical values are cleaned and standardized in `scripts/data_prep.ipynb`.
3. FinBERT scores article text; the checkpoint output is stored in `data/processed/`.
4. Reference records are resolved to surrogate keys and data is loaded into `core.daily_news` and `core.monthly_macro_indicators`.
5. SQL views aggregate monthly sentiment, calculate indicator month-over-month differences, and produce long and region-wide analytical shapes.
6. Authentication and access views translate user grants into company/region scopes.
7. The Streamlit application queries only the rows permitted for the signed-in user and links selected news records back to their raw content.

### SQL deployment order

The repository's database scripts should be executed in this order:

1. `scripts/01_create_schemas.sql`
2. `scripts/02a_create_source_regions.sql`
3. `scripts/02b_build_core_tables.sql`
4. `scripts/03_create_analytics_view.sql`
5. `scripts/03b_create_monthly_region_wide_view.sql`
6. `scripts/04_create_auth_tables.sql`
7. `scripts/05_create_access_views.sql`
8. `scripts/06_create_assets_table.sql`

---

## 4. Ownership, Licensing, and Responsibilities

The project is shared at <https://github.com/zahra-ynp/Advanced-Data-Management>.

Repository code, metadata, and eligible derived outputs are made available under **CC BY-NC 4.0**. Raw source data is not relicensed by this project and remains governed by the terms of its provider. Users reproducing the pipeline are responsible for checking the current source terms and attribution requirements.

| Source or output | Owner/provider | Applicable terms |
|---|---|---|
| FRED macroeconomic data | Federal Reserve Bank of St. Louis and originating agencies | FRED/provider terms; many U.S. government series are public domain |
| Eurostat data | European Commission / Eurostat | Eurostat reuse policy, generally aligned with attribution-based reuse |
| FinSen dataset | Kaggle contributor `eaglewhl` | Dataset page and Kaggle terms |
| Financial News Multisource | `Brianferrell787` via Hugging Face | Dataset-card and source-specific terms |
| Project code, metadata, and eligible derived outputs | Zahra Younes Pour Langaroudi | CC BY-NC 4.0 |

The project author is responsible for maintaining the pipeline, schema documentation, access configuration, and derived outputs. Upstream providers remain responsible for their source data.

---

## 5. Security, Privacy, and Access Control

- API keys and database credentials must be supplied through environment variables or other local secret-management mechanisms and must not be committed.
- The SQL tables contain application identities and password hashes. These data are confidential operational data even when sample accounts are used.
- Production deployments should replace seeded demonstration credentials, use PBKDF2-formatted hashes, limit database privileges, and protect transport connections.
- The application uses parameterized queries for user-controlled values and restricts raw-file resolution to the project data directory.
- Authorization is grant-based: access may be global, region-scoped, company-scoped, or a combination determined by role.
- Public releases should exclude local `.env` files, connection strings, operational user records, and any raw source material that cannot be redistributed.

---

## 6. Metadata, Quality, and Documentation

The repository uses complementary documentation artifacts:

- `DMP.md` - human-readable management, governance, storage, and preservation plan.
- `metadata/dataset_metadata.jsonld` - descriptive metadata using Schema.org concepts.
- `metadata/data_dictionary.json` - column-level structural definitions.
- `metadata/data_lineage.jsonld` - provenance and transformation relationships using W3C PROV-O concepts.
- SQL scripts - authoritative definitions of the currently implemented schemas, constraints, tables, indexes, and views.


---

## 7. Preservation and Reproducibility

**Raw/derived separation:** Raw inputs are immutable. Processed checkpoints, core records, and analytical views are derived and reproducible.

**Version control:** Code, SQL definitions, DMP revisions, and metadata are maintained in Git.

**Retention:** Raw data, documentation, code, and derived outputs will be retained for the duration of the academic program and for at least 12 months after project submission.

---

## Appendix A. Core API Query Parameters

### A.1 Authentication and security

- **Credential management:** FRED keys and database settings must not be embedded in committed source or metadata.
- **Access requirements:** FRED requires a registered API key. The Eurostat dissemination API is publicly accessible without an API key.

### A.2 FRED

- **Date range:** `2007-01-01` to `2023-12-31`
- **Series:** `CPIAUCSL`, `UNRATE`, `FEDFUNDS`, `INDPRO`
- **Example request:**

  ```text
  https://api.stlouisfed.org/fred/series/observations?series_id=CPIAUCSL&file_type=json&api_key=YOUR_API_KEY
  ```

### A.3 Eurostat

- **Dataset:** `prc_hicp_midx` (Harmonised Index of Consumer Prices)
- **Format:** JSON/SDMX response
- **Geographies used by the project:** Italy and the Euro Area/European aggregate as configured in the notebook
- **Example request:**

  ```text
  https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/dataflow/ESTAT/prc_hicp_midx/1.0?format=JSON
  ```
