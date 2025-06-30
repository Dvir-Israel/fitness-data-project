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
    st.set_page_config(page_title="Body Metrics Dashboard", layout="wide")

    # Set up SQL Server connection
    driver = cfg["db"]["driver"]
    server = cfg["db"]["server"]
    database = cfg["db"]["database"]

    connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
    engine = create_engine(connection_string)

    # Load Body Metrics
    with engine.connect() as conn:
        df = pd.read_sql("SELECT * FROM VWM_BodyMetrics", conn)

    st.title("📊 Body Metrics Overview")

    # Create a week filter using buttons
    weeks = sorted(df['Week'].unique())
    selected_week = st.selectbox("Select Week", weeks, key="week_select", label_visibility="collapsed")
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

    # Filter data
    filtered_df = df[df['Week'] == selected_week]

    if not filtered_df.empty:
        metrics_top = ["BMI", "FFMI", "LBM", "BFM", "W2HR"]
        metrics_bottom = ["AverageWeight", "AverageChest", "AverageWaist", "AverageNeck", "AverageArm", "AverageBFP"]

        # Function to display each metric in a box with 4 decimals
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

        st.markdown("<br>", unsafe_allow_html=True)  # Add some space between rows

        # Bottom row
        cols_bottom = st.columns(len(metrics_bottom))
        for col, metric in zip(cols_bottom, metrics_bottom):
            value = filtered_df.iloc[0][metric]
            with col:
                metric_box(metric, value)

    else:
        st.warning("No data found for the selected week.")

if __name__ == "__main__":
    main()