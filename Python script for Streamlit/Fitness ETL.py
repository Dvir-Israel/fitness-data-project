# Import relevant libraries
import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# read excels
xlweigh_ins = pd.read_excel(r"D:/Fitness data project/Fitness Data engineering project source files/Weigh-ins Data.xlsx",sheet_name=None
)
xltraining_plan = pd.read_excel(r"D:/Fitness data project/Fitness Data engineering project source files/Training plan Data.xlsx",sheet_name=None
)

# create combined DataFrame for weighins
Weigh_ins_df = pd.DataFrame()

for sheet_name, df in xlweigh_ins.items():
    # Check if the first row in the "Weight" column is not null
    if pd.isnull(df["Weight"].iloc[0]):
        continue
    
    # Add the sheet name to the "Week" column
    df["Week"] = sheet_name.split()[1]
    
    # Filter out rows where the "Weight" column is null (just in case there are any)
    df = df[df["Weight"].notna()]
    
    # Concatenate the filtered DataFrame to the combined one
    Weigh_ins_df = pd.concat([Weigh_ins_df, df], ignore_index=True)

# create combined DataFrame for weighins
Training_data_df = pd.DataFrame()

for sheet_name, df in xltraining_plan.items():
    # Check if the first row in the "Weight" column is not null
    if pd.isnull(df["Date"].iloc[0]):
        continue
    
    # Add the sheet name to the "SheetName" column
    df["Week"] = sheet_name.split()[1]
    
    # Filter out rows where the "SheetName" column is null (just in case there are any)
    df = df[df["Date"].notna()]
    
    # Concatenate the filtered DataFrame to the combined one
    Training_data_df = pd.concat([Training_data_df, df], ignore_index=True)

# Create weigh_ins_df with unique users
Weigh_ins_df_unique = Weigh_ins_df[['User_name', 'Height', 'Date']].groupby(level=0).first()

Users_df = pd.DataFrame({
    "UserID": [],
    "FirstName": [],
    "LastName": [],
    "Height": [],
    "Date": []
})

# Ensure the 'Date' column is in datetime format
Weigh_ins_df_unique['Date'] = pd.to_datetime(Weigh_ins_df_unique['Date'])

# Group by 'User_name' and get the first row for each group
Weigh_ins_df_unique = Weigh_ins_df_unique.groupby('User_name', as_index=False).first()

# Get the minimum date for each user and assign it correctly
min_dates = Weigh_ins_df_unique.groupby('User_name')['Date'].transform('min')
Weigh_ins_df_unique['Date'] = min_dates

Users_df["FirstName"] = Weigh_ins_df_unique["User_name"].str.split().str[0]
Users_df["LastName"] = Weigh_ins_df_unique["User_name"].str.split().str[1]
Users_df["Height"] = Weigh_ins_df_unique["Height"]
Users_df["Date"] = Weigh_ins_df_unique["Date"]

# Assign a UserID based on the Date (or any other column you want)
Users_df["UserID"] = Users_df["Date"].rank(method='dense').astype(int)

# Drop the Date column
Users_df = Users_df.drop(columns=["Date"])

Training_programs_df = pd.DataFrame({
    "TrainingProgramID": [],
    "TrainingProgramName": [],
    "Date": []
})

Training_data_df_unique = Training_data_df[['User_name', 'Training_Program', 'Date']].groupby(level=0).first()

# Ensure the 'Date' column is in datetime format
Training_data_df_unique['Date'] = pd.to_datetime(Training_data_df_unique['Date'])

# Group by 'User_name' and get the first row for each group
Training_data_df_unique = Training_data_df_unique.groupby('User_name', as_index=False).first()

# Get the minimum date for each user and assign it correctly
min_dates = Training_data_df_unique.groupby('User_name')['Date'].transform('min')
Training_data_df_unique['Date'] = min_dates

Training_programs_df["TrainingProgramName"] = Training_data_df_unique["Training_Program"]
Training_programs_df["Date"] = Training_data_df_unique["Date"]

# Assign a TrainingProgramID based on the Date (or any other column you want)
Training_programs_df["TrainingProgramID"] = Training_programs_df["Date"].rank(method='dense').astype(int)

# Drop the Date column
Training_programs_df = Training_programs_df.drop(columns=["Date"])

# Convert 'Week' column to integer type
Training_data_df["Week"] = Training_data_df['Week'].astype('int64')

# Convert 'Week' column to integer type
Weigh_ins_df["Week"] = Weigh_ins_df['Week'].astype('int64')

# Create a copy of Users_df for further processing
Users_df_copy = Users_df.copy()

# Create a new column 'User_name' by concatenating 'FirstName' and 'LastName'
Users_df_copy['User_name'] = Users_df_copy['FirstName'].str.strip() + ' ' + Users_df_copy['LastName'].str.strip()

# Merge Users_df_copy with Weigh_ins_df on 'User_name'
# and keep only the relevant columns for Measurements_df
merged_df = pd.merge(
    Users_df_copy[['UserID','User_name']],  # Keep only UserID + User_name
    Weigh_ins_df,
    on='User_name',
    how='inner'  # or 'left' if you want all users even if no measurement
)
Measurements_df = merged_df[['UserID', 'Height', 'Date', 'Waist', 'Arm', 'Neck', 'Chest', 'Week']].copy()

# Calculate Body Fat Percentage (BFP) using the Jackson and Pollock and drop the 'Height' column
Measurements_df.loc[:, 'BFP'] = (495 / (
    1.0324 - 0.19077 * np.log10(Measurements_df['Waist'] - Measurements_df['Neck']) +
    0.15456 * np.log10(Measurements_df['Height'])
) - 450) / 100
Measurements_df = Measurements_df.drop(columns=['Height'])

# Create a copy of Users_df for further processing
Weigh_ins_df_upload = merged_df[['UserID', 'Date', 'Weight', 'Week']].copy()

# Merge Users_df_copy with Training_data_df on 'User_name'
# and keep only the relevant columns for Training_data_df_Part_1
merged_df_2 = pd.merge(
    Users_df_copy[['UserID','User_name']],  # Keep only UserID + User_name
    Training_data_df,
    on='User_name',
    how='inner'  # or 'left' if you want all users even if no measurement
)
Training_data_df_Part_1 = merged_df_2[['UserID', 'Date', 'Training_Program', 'Split', 'Exercise', 'Number_of_Sets', 'Weight', 'Reps', 'Week']].copy()

# Create a copy of Training_programs_df for further processing
Training_programs_df_copy = Training_programs_df.copy()

# merge Training_programs_df_copy with Training_data_df_Part_1 on 'TrainingProgramName'
merged_df_3 = pd.merge(
    Training_programs_df_copy[['TrainingProgramID', 'TrainingProgramName']],
    Training_data_df_Part_1,
    left_on='TrainingProgramName',
    right_on='Training_Program',
    how='inner'  # or 'left', depending on your goal
)
Training_data_df_Part_2 = merged_df_3[['UserID', 'TrainingProgramID', 'Date', 'Split', 'Exercise', 'Number_of_Sets', 'Weight', 'Reps', 'Week']].copy()

# Step 1: Split 'Reps' column into multiple columns dynamically
reps_split = Training_data_df_Part_2['Reps'].astype(str).str.split(',', expand=True)

# Step 2: Rename the new columns to strings: '1', '2', '3', ...
reps_split.columns = [str(i + 1) for i in range(reps_split.shape[1])]

# Step 3: Concatenate with the original DataFrame
df_with_sets = pd.concat([Training_data_df_Part_2, reps_split], axis=1)

# Step 4: Melt the new rep columns into 'Set' and 'Reps_per_Set'
Training_data_df_Part_3 = df_with_sets.melt(
    id_vars=[col for col in df_with_sets.columns if col not in reps_split.columns],
    value_vars=reps_split.columns,
    var_name='Set',
    value_name='Reps_per_Set'
)

# Optional: Drop rows where 'Reps_per_Set' is NaN (if any exist)
Training_data_df_Part_3.dropna(subset=['Reps_per_Set'], inplace=True)

# Make sure 'Set' is numeric for proper sorting
Training_data_df_Part_3['Set'] = Training_data_df_Part_3['Set'].astype(int)

# Sort the DataFrame by Date, Split, Exercise, and Set
Training_data_df_Part_3 = Training_data_df_Part_3.sort_values(by=['Date', 'Split', 'Exercise', 'Set']).reset_index(drop=True)

# Step 5: Drop the original 'Reps' and 'Number_of_Sets' columns if they exist
Training_data_df_Upload = Training_data_df_Part_3.drop(columns=[col for col in ['Reps', 'Number_of_Sets'] if col in Training_data_df_Part_3.columns])

# Sort the final DataFrame columns for upload
Training_data_df_Upload = Training_data_df_Upload[['UserID', 'TrainingProgramID' , 'Date' , 'Split' , 'Exercise', 'Set', 'Weight', 'Reps_per_Set', 'Week']]

# Replace DRIVER with your installed ODBC driver version
driver = 'ODBC Driver 17 for SQL Server'

server = r'DESKTOP-UQP00A5\SQLEXPRESS'
database = 'Fitness Database'

connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
engine = create_engine(connection_string)

# Load the current data from the database Users table
with engine.connect() as conn:
    existing_users_df = pd.read_sql("SELECT UserID FROM Users", conn)

# Perform left merge from Users_df to existing_users_df
merged_df = Users_df.merge(existing_users_df, on="UserID", how="left", indicator=True)

# Keep only new rows (those not found in the DB)
new_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

# Upload only if new rows exist
if not new_rows_df.empty:
    new_rows_df.to_sql("Users", con=engine, if_exists="append", index=False, method="multi")
    print(f"✅ Inserted {len(new_rows_df)} new user(s) into the Users table.")
else:
    print("⚠️ No new users to insert — skipping upload.")

# Load the current data from the database TrainingPrograms table
with engine.connect() as conn:
    existing_programs_df = pd.read_sql("SELECT TrainingProgramID FROM TrainingPrograms", conn)

# Perform left merge from Training_programs_df to existing_programs_df
merged_df = Training_programs_df.merge(existing_programs_df, on="TrainingProgramID", how="left", indicator=True)

# Keep only new rows (those not found in the DB)
new_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

# Upload only if new rows exist
if not new_rows_df.empty:
    new_rows_df.to_sql("TrainingPrograms", con=engine, if_exists="append", index=False, method="multi")
    print(f"✅ Inserted {len(new_rows_df)} new training program(s) into the TrainingPrograms table.")
else:
    print("⚠️ No new training programs to insert — skipping upload.")

# Load the current data from the database Measurements table
with engine.connect() as conn:
    existing_measurements_df = pd.read_sql("SELECT UserID, Date FROM Measurements", conn)

# Convert Date columns to datetime type for both DataFrames
Measurements_df['Date'] = pd.to_datetime(Measurements_df['Date'])
existing_measurements_df['Date'] = pd.to_datetime(existing_measurements_df['Date'])

# Perform left merge from Measurements_df to existing_measurements_df
merged_df = Measurements_df.merge(existing_measurements_df, on=["UserID", "Date"], how="left", indicator=True)

# Keep only new rows (those not found in the DB)
new_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

# Upload only if new rows exist
if not new_rows_df.empty:
    new_rows_df.to_sql("Measurements", con=engine, if_exists="append", index=False, method="multi")
    print(f"✅ Inserted {len(new_rows_df)} new measurement(s) into the Measurements table.")
else:
    print("⚠️ No new measurements to insert — skipping upload.")

# Load the current data from the database WeighIns table
with engine.connect() as conn:
    existing_weighins_df = pd.read_sql("SELECT UserID, Date FROM WeighIns", conn)

# Convert Date columns to datetime type for both DataFrames
Weigh_ins_df_upload['Date'] = pd.to_datetime(Weigh_ins_df_upload['Date'])
existing_weighins_df['Date'] = pd.to_datetime(existing_weighins_df['Date'])

# Perform left merge from Weigh_ins_df_upload to existing_weighins_df
merged_df = Weigh_ins_df_upload.merge(existing_weighins_df, on=["UserID", "Date"], how="left", indicator=True)

# Keep only new rows (those not found in the DB)
new_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

# Upload only if new rows exist
if not new_rows_df.empty:
    # Rename the Weight column to WeighIn to match the database table column name
    new_rows_df = new_rows_df.rename(columns={"Weight": "WeighIn"})
    
    # Insert the new rows into the WeighIns table
    new_rows_df.to_sql("WeighIns", con=engine, if_exists="append", index=False, method="multi")
    print(f"✅ Inserted {len(new_rows_df)} new weigh-in(s) into the WeighIns table.")
else:
    print("⚠️ No new weigh-ins to insert — skipping upload.")

# Load the current data from the database TrainingProgramDetails table
with engine.connect() as conn:
    existing_training_data_df = pd.read_sql("SELECT UserID, TrainingProgramID, Date FROM TrainingProgramDetails", conn)

# Convert Date columns to datetime type for both DataFrames
Training_data_df_Upload['Date'] = pd.to_datetime(Training_data_df_Upload['Date'])
existing_training_data_df['Date'] = pd.to_datetime(existing_training_data_df['Date'])

# Perform left merge from Training_data_df_Upload to existing_training_data_df
merged_df = Training_data_df_Upload.merge(existing_training_data_df, on=["UserID", "TrainingProgramID", "Date"], how="left", indicator=True)

# Keep only new rows (those not found in the DB)
new_rows_df = merged_df[merged_df["_merge"] == "left_only"].drop(columns=["_merge"])

# Upload only if new rows exist
if not new_rows_df.empty:
    # Rename the columns to match the database table columns
    new_rows_df = new_rows_df.rename(columns={
        "Split": "TrainingSplit",
        "Exercise": "Exercise",
        "Set": "Set",
        "Weight": "Weight",
        "Reps_per_Set": "Reps",
        "Week": "Week"
    })
    
    # Insert the new rows into the TrainingProgramDetails table
    new_rows_df.to_sql("TrainingProgramDetails", con=engine, if_exists="append", index=False, method="multi")
    print(f"✅ Inserted {len(new_rows_df)} new training data(s) into the TrainingProgramDetails table.")
else:
    print("⚠️ No new training data to insert — skipping upload.")