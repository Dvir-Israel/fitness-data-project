import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from load_config import load_config
# Import relevant libraries
import pandas as pd
import streamlit as st
from sqlalchemy import create_engine


def main():
    # Load config
    cfg = load_config("local")

    # Set wide layout
    st.set_page_config(page_title="Sleep Dashboard", layout="wide")

    # Set up SQL Server connection
    driver = cfg["db"]["driver"]
    server = cfg["db"]["server"]
    database = cfg["db"]["database"]

    connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
    engine = create_engine(connection_string)

    # Load Sleep data
    with engine.connect() as conn:
        df = pd.read_sql("SELECT * FROM VS_Metrics_Weekly", conn)

    st.title("📊 Sleep Overview")

    # Create a week filter using select box
    weeks = sorted(df['Week'].unique())
    selected_week = st.selectbox("Select Week", weeks, key="week_select", label_visibility="collapsed")

    # Make the select box smaller
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
    st.write("**Select Week:**", selected_week)

    # Filter data for selected week
    filtered_df = df[df['Week'] == selected_week]

    if not filtered_df.empty:
        metrics_top = ["AvgSleepScore", "SleepQualityRating"]

        # Function to display each metric in a styled box
        def metric_box(label, value):
            if isinstance(value, (int, float)):
                value_display = f"{value:.4f}"
            else:
                value_display = str(value)
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
                    <div style="font-size: 24px; color: #1E88E5;">{value_display}</div>
                </div>
            """, unsafe_allow_html=True)

        # Display metrics
        cols_top = st.columns(len(metrics_top))
        for col, metric in zip(cols_top, metrics_top):
            value = filtered_df.iloc[0][metric]
            with col:
                metric_box(metric, value)

    else:
        st.warning("No data found for the selected week.")

if __name__ == "__main__":
    main()