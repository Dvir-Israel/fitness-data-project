import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from load_config import load_config
# Import relevant libraries
import pandas as pd
import json
import os
from sqlalchemy import create_engine

def main():
    # Load config
    cfg = load_config("local")

    # --- Path to the JSON file ---
    file_path = cfg["paths"]["sleep_json"]

    # --- Load the JSON data ---
    with open(file_path, "r") as f:
        data = json.load(f)

    # --- Path to the JSON file ---
    file_path2 = cfg["paths"]["user_json"]

    # --- Load the JSON data ---
    with open(file_path2, "r") as f:
        user_data = json.load(f)

    # --- Step 1: Collect all unique keys across all entries ---
    all_keys = set()
    for entry in data:
        all_keys.update(entry.keys())

    # Step 2 & 3 combined (faster)
    rows = []
    for entry in data:
        row = {key: entry.get(key, None) for key in all_keys}
        rows.append(row)

    df = pd.DataFrame(rows, columns=list(all_keys))

    # Optional: Sort columns to put 'calendarDate' first
    columns = ['calendarDate'] + sorted([k for k in all_keys if k != 'calendarDate'])
    df = df[columns]

    # Filter the DataFrame to include only relevant sleep data
    relevant_sleep = df[df['sleepWindowConfirmationType'].str.lower().str.contains('enhanced|auto', regex=True)]

    # Create copy of the DataFrame to avoid modifying the original
    relevant_sleep = relevant_sleep.copy()

    # Convert timestamps to datetime
    relevant_sleep['sleepStartTimestampGMT'] = pd.to_datetime(relevant_sleep['sleepStartTimestampGMT'])
    relevant_sleep['sleepEndTimestampGMT'] = pd.to_datetime(relevant_sleep['sleepEndTimestampGMT'])
    relevant_sleep['calendarDate'] = pd.to_datetime(relevant_sleep['calendarDate'])

    # Add user information to the DataFrame
    relevant_sleep['firstName'] = user_data['firstName']
    relevant_sleep['lastName'] = user_data['lastName']

    # Set up SQL Server connection
    driver = cfg["db"]["driver"]
    server = cfg["db"]["server"]
    database = cfg["db"]["database"]

    connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
    engine = create_engine(connection_string)

    # Load the current data from the database Users table
    with engine.connect() as conn:
        existing_users_df = pd.read_sql("SELECT * FROM Users", conn)

    # First, make sure name casing matches
    relevant_sleep['firstName'] = relevant_sleep['firstName'].str.strip().str.lower()
    relevant_sleep['lastName'] = relevant_sleep['lastName'].str.strip().str.lower()
    existing_users_df['FirstName'] = existing_users_df['FirstName'].str.strip().str.lower()
    existing_users_df['LastName'] = existing_users_df['LastName'].str.strip().str.lower()

    # Merge the two DataFrames on first and last name
    merged_sleep = pd.merge(
        relevant_sleep,
        existing_users_df,
        left_on=['firstName', 'lastName'],
        right_on=['FirstName', 'LastName'],
        how='inner'  # or 'left' if you want to keep unmatched sleep records
    )

    # Drop first/last name columns and keep UserID
    merged_sleep = merged_sleep.drop(columns=['firstName', 'lastName', 'FirstName', 'LastName'])

    # Optional: reorder columns (UserID first)
    cols = ['UserID'] + [col for col in merged_sleep.columns if col != 'UserID']
    merged_sleep = merged_sleep[cols]

    # Load existing sleep data keys from SQL table SleepData
    with engine.connect() as conn:
        existing_sleep_df = pd.read_sql(
            "SELECT UserID, CalendarDate, SleepStartTimestampGMT FROM SleepData", conn
        )

    # Make sure datetime columns are parsed correctly
    merged_sleep['CalendarDate'] = pd.to_datetime(merged_sleep['calendarDate']).dt.date
    existing_sleep_df['CalendarDate'] = pd.to_datetime(existing_sleep_df['CalendarDate']).dt.date

    merged_sleep['SleepStartTimestampGMT'] = pd.to_datetime(merged_sleep['sleepStartTimestampGMT'])
    existing_sleep_df['SleepStartTimestampGMT'] = pd.to_datetime(existing_sleep_df['SleepStartTimestampGMT'])

    # Perform left merge to find new sleep records
    merged_df = merged_sleep.merge(
        existing_sleep_df,
        on=["UserID", "CalendarDate", "SleepStartTimestampGMT"],
        how="left",
        indicator=True
    )

    # Keep only rows not already in the DB
    new_sleep_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

    # Rename columns to match SleepData table schema if necessary
    # Note: your merged_sleep uses lowercase names, so map them accordingly
    new_sleep_rows_df = new_sleep_rows_df.rename(columns={
        "calendarDate": "CalendarDate",
        "sleepStartTimestampGMT": "SleepStartTimestampGMT",
        "sleepEndTimestampGMT": "SleepEndTimestampGMT",
        "awakeSleepSeconds": "AwakeSleepSeconds",
        "deepSleepSeconds": "DeepSleepSeconds",
        "lightSleepSeconds": "LightSleepSeconds",
        "remSleepSeconds": "RemSleepSeconds",
        "unmeasurableSeconds": "UnmeasurableSeconds",
        "averageRespiration": "AverageRespiration",
        "highestRespiration": "HighestRespiration",
        "lowestRespiration": "LowestRespiration",
        "retro": "Retro",
        "sleepWindowConfirmationType": "SleepWindowConfirmationType"
    })

    # Select only the columns present in SleepData (order not critical but nice to keep consistent)
    sleepdata_columns = [
        "UserID",
        "CalendarDate",
        "SleepStartTimestampGMT",
        "SleepEndTimestampGMT",
        "AwakeSleepSeconds",
        "DeepSleepSeconds",
        "LightSleepSeconds",
        "RemSleepSeconds",
        "UnmeasurableSeconds",
        "AverageRespiration",
        "HighestRespiration",
        "LowestRespiration",
        "Retro",
        "SleepWindowConfirmationType"
    ]

    new_sleep_rows_df = new_sleep_rows_df[sleepdata_columns]

    # Insert new rows into SleepData table
    if not new_sleep_rows_df.empty:
        new_sleep_rows_df.to_sql("SleepData", con=engine, if_exists="append", index=False, method="multi")
        print(f"✅ Inserted {len(new_sleep_rows_df)} new sleep record(s) into the SleepData table.")
    else:
        print("⚠️ No new sleep data to insert — skipping upload.")

# --- Run only if script is executed directly ---
if __name__ == "__main__":
    main()