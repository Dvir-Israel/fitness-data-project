import streamlit as st

st.set_page_config(page_title="Home", layout="wide")

st.title("🏠 Welcome to the Fitness Dashboard")

st.write("Use the sidebar to navigate, or click below:")

if st.button("📊 Go to Body Metrics"):
    st.switch_page("pages/Streamlit_bodymetrics.py")

if st.button("🏋️ Go to Training Metrics"):
    st.switch_page("pages/Streamlit_trainingmetrics.py")

if st.button("😴 Go to Sleep Metrics"):
    st.switch_page("pages/Streamlit_sleepmetrics.py")
