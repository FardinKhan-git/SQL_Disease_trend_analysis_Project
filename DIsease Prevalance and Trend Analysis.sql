CREATE TABLE health_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    indicator VARCHAR(255) NOT NULL,
    year INT NOT NULL,
    value DECIMAL(15,2) NOT NULL,
    category VARCHAR(50),
    INDEX idx_indicator (indicator),
    INDEX idx_year (year),
    INDEX idx_category (category),
    INDEX idx_indicator_year (indicator, year)
) ENGINE=InnoDB;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/australian_bureau_final_CLEANED_Final.csv'
INTO TABLE health_metrics
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(indicator, year, value)
SET category = CASE
    WHEN indicator IN ('Arthritis', 'Diabetes mellitus', 'Asthma', 'Chronic obstructive pulmory disease', 'Hypertension', 'Back problems', 'Mental and behavioural conditions', 'Osteoporosis') THEN 'Chronic Disease'
    WHEN indicator IN ('Cancer', 'Kidney disease', 'Heart stroke and vascular disease') THEN 'Serious Condition'
    WHEN indicator LIKE '%psychological distress%' OR indicator LIKE '%Mental%' THEN 'Mental Health'
    WHEN indicator LIKE '%smok%' OR indicator LIKE '%drink%' OR indicator LIKE '%alcohol%' THEN 'Behavioral'
    WHEN indicator LIKE '%BMI%' OR indicator LIKE '%weight%' OR indicator LIKE '%Obesity%' THEN 'Biometrics'
    WHEN indicator LIKE '%fruit%' OR indicator LIKE '%vegetable%' OR indicator LIKE '%diet%' THEN 'Nutrition'
    WHEN indicator LIKE '%physical activity%' OR indicator LIKE '%exercise%' THEN 'Physical Activity'
    ELSE 'Other'
END;

WITH disease_growth AS (
    SELECT 
        indicator,
        MAX(CASE WHEN year = 2001 THEN value END) AS value_2001,
        MAX(CASE WHEN year = 2022 THEN value END) AS value_2022,
        (MAX(CASE WHEN year = 2022 THEN value END) - MAX(CASE WHEN year = 2001 THEN value END)) AS absolute_change,
        ROUND(
            ((MAX(CASE WHEN year = 2022 THEN value END) - MAX(CASE WHEN year = 2001 THEN value END)) / 
            MAX(CASE WHEN year = 2001 THEN value END)) * 100, 2
        ) AS pct_change
    FROM health_metrics
    WHERE category IN ('Chronic Disease', 'Serious Condition')
      AND year IN (2001, 2022)
    GROUP BY indicator
    HAVING value_2001 IS NOT NULL AND value_2022 IS NOT NULL
)  
SELECT 
    indicator,
    value_2001,
    value_2022,
    absolute_change,
    pct_change
FROM disease_growth
ORDER BY pct_change DESC
LIMIT 5;
SELECT 
    d.year,
    ROUND(d.disease_value / p.value * 100, 2) AS disease_rate,
    ROUND(b.behavior_value / p.value * 100, 2) AS behavior_rate
FROM (
    SELECT 
        year, 
        SUM(value) AS disease_value
    FROM health_metrics
    WHERE category = 'Chronic Disease'
    GROUP BY year
) d
JOIN (
    SELECT 
        year, 
        SUM(value) AS behavior_value
    FROM health_metrics
    WHERE category = 'Behavioral'
    GROUP BY year
) b ON d.year = b.year
JOIN (
    SELECT year, value
    FROM health_metrics
    WHERE indicator = 'Total persons all ages'
) p ON d.year = p.year
ORDER BY d.year;