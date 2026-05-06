#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      🚀 PERKVERSE - INITIATING EXECUTION... 🚀        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Step 1: Get GCP project ID & Region
echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Fetching Project ID & Region...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project: $PROJECT_ID | Region: $REGION${RESET_FORMAT}"
echo

# Step 2: Create Docker Artifact Registry repository
echo "${GREEN_TEXT}${BOLD_TEXT}📦 Creating Artifact Registry repository...${RESET_FORMAT}"
gcloud artifacts repositories create example-docker-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="PerkVerse Docker Repo" \
    --project=$PROJECT_ID

# Step 3: Configure Docker
echo "${YELLOW_TEXT}${BOLD_TEXT}🔐 Configuring Docker authentication...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev

# Step 4: Pull Docker image
echo "${BLUE_TEXT}${BOLD_TEXT}⬇️ Pulling sample Docker image...${RESET_FORMAT}"
docker pull us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0

# Step 5: Tag Docker image
echo "${MAGENTA_TEXT}${BOLD_TEXT}🏷️ Tagging Docker image...${RESET_FORMAT}"
docker tag us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0 \
$REGION-docker.pkg.dev/$PROJECT_ID/example-docker-repo/sample-image:tag1

# Step 6: Push Docker image
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Pushing image to Artifact Registry...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$PROJECT_ID/example-docker-repo/sample-image:tag1

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}          🎉 LAB COMPLETED SUCCESSFULLY! 🎉            ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🔥 Subscribe to PerkVerse for more Cloud Labs 🚀${RESET_FORMAT}"
