#!/bin/bash

# Variables
PROJECT_ID="gke-sandbox-412119"
BUCKET_NAME="gke-sandbox-412119-tfstate"
REGION="us-east1"

# Check if the bucket exists
if ! gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
  echo "Bucket does not exist. Creating bucket..."
  gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
else
  echo "Bucket already exists."
fi
