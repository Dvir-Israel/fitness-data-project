Fitness Data Engineering Project

This project is an end-to-end fitness data platform that extracts raw data from Excel and JSON sources, processes it via Python ETL pipelines, stores it in a normalized SQL Server database, and visualizes metrics using Streamlit.

🔍 Overview

This project aims to centralize and analyze personal fitness data by combining various sources into a unified database, allowing consistent and insightful tracking of metrics over time.

📁 Project Structure

fitness-data-project/
│
├── Garmin extract/               # Raw JSON data from Garmin (sleep, user info)
├── Excel data/                   # Excel files with measurements, weigh-ins, and training
├── Python script for Streamlit/  # ETL + Streamlit app code
├── SQL queries/                  # All SQL table/view scripts
└── README.md

💾 Data Sources

Excel Files

Weigh-ins & Measurements: Multiple sheets (each = 1 week)

Training Plan: Weekly logs of sets, reps, weights, and exercises

Garmin JSON Files

User Profile: Basic user data (name, etc.)

Sleep Data: Daily entries containing sleep stage durations and timestamps

🛠️ Technologies Used

Python: ETL (Pandas, NumPy, SQLAlchemy)

SQL Server: Relational data warehouse

Streamlit: Front-end data visualization

Git: Version control

🧱 Database Schema

![Screenshot 2025-06-26 205939](https://github.com/user-attachments/assets/ab370cd0-1809-4211-9f43-29182aa163e9)



Tables:

Users: Personal info

Measurements: Body measurements over time

WeighIns: Weekly weight logs

TrainingPrograms & TrainingProgramDetails: Structure and logs of training sessions

SleepData: Daily sleep metrics from Garmin

📊 Calculated Metrics

📏 Body Metrics (via VWM_BodyMetrics):

BMI: Body Mass Index

FFMI: Fat-Free Mass Index

LBM: Lean Body Mass

BFM: Body Fat Mass

W2HR: Waist-to-Height Ratio

BFP: Body Fat Percentage (from ETL using U.S. Navy formula)

Average Weight Loss: ΔWeight week-over-week

🏋️ Training Metrics (via VTP_TrainingMetrics):

P1RM: Projected One-Rep Max (adjusted for reps)

EVS: Effective Volume Score (training load with intensity factor)

ATL: Adjusted Training Load (weight ÷ reps)

WI: Workout Intensity (EVS × ATL)

ARPW: Average Reps Per Weight (in VTP_RepAverage)

😴 Sleep Metrics (via VS_Metrics, VS_Metrics_Weekly):

Total Sleep Score: Duration-based

REM/Deep/Light/Awake Scores: Stage ratios

Respiration Score: Based on breath rate fluctuation

Overall Sleep Score: Weighted composite

Sleep Quality Rating: Categorical tag (Excellent → Very Poor)

🖥️ Streamlit App

Features:

Tabbed pages for:

Body Metrics

Training Performance

Sleep Analysis

All metrics sourced from SQL views

Fully dynamic with latest data on refresh

🔄 ETL Pipeline

ETL scripts (Python):

Parse JSON/Excel files

Clean and normalize data

Perform deduplication and upserts

Push to SQL Server

✅ Future Improvements

Add automated CI pipeline for data ingestion

Deploy Streamlit app with secure user access (via Streamlit Cloud / Docker)

Manage the project in a Cloud environment

🧠 Author

Dvir IsraelOpen to feedback, collaboration, and coffee ☕

GitHub: Dvir-Israel

📜 License

This project is currently private. Reach out if you’d like to contribute.

