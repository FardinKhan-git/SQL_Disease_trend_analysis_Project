# Data Analytics Project
# Project 1: Disease Prevalance and trend analysis 
About Data:The national health survey  data was collected from Australian Bureau of Statistics.It contains data from  2001 to 2022.It contains data for different health conditions which includes Arthritis(c),Asthma,Back problems (dorsopathies),Cancer,Chronic obstructive pulmonary disease,Diabetes mellitus,Hayfever and allergic rhinitis,Heart, stroke and vascular disease,Hypertension,Kidney disease,Mental and behavioural conditions,Osteoporosis.
It also contains self asssessed health status and health risk factor data

## Project Description
### Overview
This project analyzes long-term trends in health indicators using data from the Australian Bureau of Statistics. The focus is on understanding the rise and prevalence of chronic diseases and behavioral health risk factors across a 21-year period. It combines data cleaning, SQL-based trend analysis, and categorical classification to extract meaningful public health insights.

### Tools & Technologies
SQL (MySQL): Data loading, transformation, and trend analysis

Python (Pandas, NumPy): Data preprocessing and reshaping

Excel: Initial raw data source

Data Source: Australian Bureau of Statistics
### Data Cleaning (Python):

Loaded an Excel file with inconsistent headers

Identified the correct header row dynamically

Reshaped the data from wide to long format

Cleaned indicator names and exported to CSV
##Database Preparation (MySQL):

Created a normalized SQL table health_metrics with indexes for faster querying

Loaded cleaned CSV data using LOAD DATA INFILE.
##Category Classification:

Auto-categorized health indicators into groups: Chronic Disease, Serious Condition, Mental Health, Behavioral, Nutrition, Biometrics, and Physical Activity

### Trend Analysis:

Identified top 5 diseases with the highest percentage growth from 2001 to 2022

Analyzed year-by-year rates of chronic disease and behavioral conditions per total population.








