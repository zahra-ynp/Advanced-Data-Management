CREATE TABLE core.daily_news (
    article_id INT IDENTITY(1,1) PRIMARY KEY,
    news_date DATE NOT NULL,
    title VARCHAR(500),
    source_name VARCHAR(100),
    region_id INT NULL,
    sentiment_score FLOAT,
    sentiment_label VARCHAR(50),
    lake_pointer_url VARCHAR(500),

    CONSTRAINT FK_News_Region FOREIGN KEY (region_id)
        REFERENCES core.source_regions (region_id)
);
GO

CREATE TABLE core.monthly_macro_indicators (
    record_id        INT           IDENTITY(1,1) PRIMARY KEY,
    month_date       DATE          NOT NULL,
    source_agency    VARCHAR(100)  NOT NULL,
    region_id        INT           NULL,
    indicator_name   VARCHAR(100)  NOT NULL,
    indicator_value  FLOAT         NULL,
    unit             VARCHAR(50)   NULL,

    CONSTRAINT UQ_Macro_Indicator UNIQUE (month_date, source_agency, region_id, indicator_name),

    CONSTRAINT FK_Macro_Region FOREIGN KEY (region_id)
        REFERENCES core.source_regions (region_id)
);
GO