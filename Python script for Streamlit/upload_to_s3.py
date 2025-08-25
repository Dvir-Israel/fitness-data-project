import boto3
import os

# --- CONFIG ---
BUCKET_NAME = 'fitness-data-cloud'
PREFIX = 'training_data/'

# Corrected local path to source files
LOCAL_FOLDER = 'D:/Fitness data project/Fitness Data engineering project source files/'

# Mapping: S3 object key → local file path
FILES_TO_UPLOAD = {
    'Weigh-ins Data.xlsx': os.path.join(LOCAL_FOLDER, 'Weigh-ins Data.xlsx'),
    'Training plan Data Cloud.xlsx': os.path.join(LOCAL_FOLDER, 'Training plan Data Cloud.xlsx')
}

# --- INIT S3 CLIENT ---
s3 = boto3.client('s3')

# --- UPLOAD ---
for s3_filename, local_file_path in FILES_TO_UPLOAD.items():
    try:
        s3.upload_file(
            Filename=local_file_path,
            Bucket=BUCKET_NAME,
            Key=PREFIX + s3_filename
        )
        print(f"✅ Uploaded: {local_file_path} → s3://{BUCKET_NAME}/{PREFIX}{s3_filename}")
    except Exception as e:
        print(f"❌ Failed to upload {local_file_path}: {e}")
