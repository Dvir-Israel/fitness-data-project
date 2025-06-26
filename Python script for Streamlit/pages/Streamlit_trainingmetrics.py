import pandas as pd
import streamlit as st
from sqlalchemy import create_engine

# Set wide layout
st.set_page_config(page_title="Body Metrics Dashboard", layout="wide")

# DB connection
driver = 'ODBC Driver 17 for SQL Server'
server = r'DESKTOP-UQP00A5\SQLEXPRESS'
database = 'Fitness Database'
connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
engine = create_engine(connection_string)

# Load Body Metrics
with engine.connect() as conn:
    df = pd.read_sql("SELECT * FROM VTP_TrainingMetrics", conn)

st.title("📊 Training Metrics Overview")

# Week filter first (note lowercase 'week')
weeks = sorted(df['week'].unique())
selected_week = st.selectbox("Select Week", weeks, key="week_select", label_visibility="collapsed")

# Then exercise filter based on selected week
filtered_by_week = df[df['week'] == selected_week]
exercises = sorted(filtered_by_week['Exercise'].unique())
selected_exercise = st.selectbox("Select Exercise", exercises, key="exercise_select")

st.markdown(
    """
    <style>
    div[data-baseweb="select"] > div {
        min-width: 70px !important;
        max-width: 70px !important;
        display: inline-block;
    }
    </style>
    """,
    unsafe_allow_html=True,
)

st.write("**Selected Week:**", selected_week)
st.write("**Selected Exercise:**", selected_exercise)

# Filter by both week and exercise
filtered_df = df[(df['week'] == selected_week) & (df['Exercise'] == selected_exercise)]

if not filtered_df.empty:
    metrics_top = ["Weight", "Sets", "AverageReps"]
    metrics_bottom = ["P1RM", "EVS", "ATL", "WI"]

    def metric_box(label, value):
        st.markdown(f"""
            <div style="
                border: 2px solid #4CAF50; 
                padding: 15px; 
                border-radius: 10px; 
                text-align: center; 
                font-weight: bold;
                font-size: 18px;
                margin-bottom: 10px;
                ">
                <div>{label}</div>
                <div style="font-size: 24px; color: #1E88E5;">{value:.4f}</div>
            </div>
        """, unsafe_allow_html=True)

    # Top row
    cols_top = st.columns(len(metrics_top))
    for col, metric in zip(cols_top, metrics_top):
        value = filtered_df.iloc[0][metric]
        with col:
            metric_box(metric, value)

    st.markdown("<br>", unsafe_allow_html=True)

    # Bottom row
    cols_bottom = st.columns(len(metrics_bottom))
    for col, metric in zip(cols_bottom, metrics_bottom):
        value = filtered_df.iloc[0][metric]
        with col:
            metric_box(metric, value)
else:
    st.warning("No data found for the selected week and exercise.")
