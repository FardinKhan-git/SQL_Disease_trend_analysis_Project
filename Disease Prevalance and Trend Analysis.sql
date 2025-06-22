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
/*Disease Prevalance view*/
CREATE VIEW disease_prevalence AS
SELECT 
    h1.indicator,
    h1.year,
    h1.value,
    ROUND(h1.value / h2.value * 100, 2) AS prevalence_percentage
FROM health_metrics h1
JOIN (
    SELECT year, MAX(value) as value
    FROM health_metrics 
    WHERE indicator = 'Total persons all ages'
    GROUP BY year
) h2 ON h1.year = h2.year
WHERE h1.category IN ('Chronic Disease', 'Serious Condition');
/*Yearly Health Summary view*/
CREATE VIEW yearly_health_summary AS
SELECT 
    year,
    MAX(CASE WHEN indicator = 'Excellent / Very good' THEN value END) AS excellent_health,
    MAX(CASE WHEN indicator = 'Fair / Poor' THEN value END) AS poor_health,
    MAX(CASE WHEN indicator = 'Current daily smoker' THEN value END) AS smokers,
    MAX(CASE WHEN indicator = 'Total Overweight / Obese' THEN value END) AS overweight_obese
FROM health_metrics
GROUP BY year;

/*Top 5 most prevalent diseases by year*/
SELECT *
FROM disease_prevalence
WHERE year = 2022
ORDER BY prevalence_percentage DESC
LIMIT 5;

/*Compare obesity vs smoking in a given year*/
SELECT year, 
    MAX(CASE WHEN indicator = 'Current daily smoker' THEN value END) AS smokers,
    MAX(CASE WHEN indicator = 'Total Overweight / Obese' THEN value END) AS overweight
FROM health_metrics
GROUP BY year
ORDER BY year;

/*Correlation Between Chronic Disease and Behavioral Risk Values*/
SELECT 
    d.year,
    d.value AS chronic_disease_total,
    b.value AS behavioral_total
FROM (
    SELECT year, SUM(value) AS value
    FROM health_metrics
    WHERE category = 'Chronic Disease'
    GROUP BY year
) d
JOIN (
    SELECT year, SUM(value) AS value
    FROM health_metrics
    WHERE category = 'Behavioral'
    GROUP BY year
) b ON d.year = b.year
ORDER BY d.year;


SELECT 
    h.year,
    h.value AS diabetes_rate,
    y.smokers,
    y.overweight_obese,
    s.seifa_score -- Assuming you have a SEIFA table
FROM health_metrics h
JOIN yearly_health_summary y ON h.year = y.year
LEFT JOIN seifa_data s ON h.year = s.year -- Example join
WHERE h.indicator = 'Diabetes mellitus'
INTO OUTFILE '/tmp/diabetes_ml.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

