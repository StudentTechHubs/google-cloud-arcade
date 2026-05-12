#!/bin/bash

# ================== COLORS ==================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
GOLD_TEXT=$'\033[38;5;220m'
LIME_TEXT=$'\033[38;5;118m'
NAVY_TEXT=$'\033[38;5;27m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# ================== BANNER ==================
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              PERKVERSE - INITIATING EXECUTION...                  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Subscribe to PerkVerse:${RESET_FORMAT}"
echo "${GREEN_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo

# ================== USER INPUT ==================
echo -e "${GOLD_TEXT}${BOLD_TEXT}Enter the Region (e.g. us-central): ${RESET_FORMAT}"
read REGION

if [[ -z "$REGION" ]]; then
  echo "${RED_TEXT}Region cannot be empty!${RESET_FORMAT}"
  exit 1
fi

echo -e "${GOLD_TEXT}${BOLD_TEXT}Enter the Message to display on App Engine: ${RESET_FORMAT}"
read MESSAGE

if [[ -z "$MESSAGE" ]]; then
  echo "${RED_TEXT}Message cannot be empty!${RESET_FORMAT}"
  exit 1
fi

# ================== FETCH PROJECT DETAILS ==================
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching project details...${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo "${RED_TEXT}Unable to detect Project ID.${RESET_FORMAT}"
  exit 1
fi

ZONE=$(gcloud compute instances list \
  --filter="name=lab-setup" \
  --format="value(zone.basename())" \
  --limit=1)

if [[ -z "$ZONE" ]]; then
  ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
fi

if [[ -z "$ZONE" ]]; then
  ZONE="us-central1-a"
fi

# Normalize region
if [[ "$REGION" == "us-west" ]]; then
  REGION="us-west1"
fi

echo "${GREEN_TEXT}Project ID : $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}Zone       : $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Region     : $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}Message    : $MESSAGE${RESET_FORMAT}"
echo

# ================== ENABLE APP ENGINE API ==================
echo "${TEAL_TEXT}${BOLD_TEXT}Enabling App Engine API...${RESET_FORMAT}"
gcloud services enable appengine.googleapis.com

sleep 10

# ================== CONFIGURE LAB-SETUP INSTANCE ==================
echo "${LIME_TEXT}${BOLD_TEXT}Configuring lab-setup instance...${RESET_FORMAT}"

gcloud compute ssh lab-setup \
  --zone "$ZONE" \
  --project "$PROJECT_ID" \
  --quiet \
  --command "
    gcloud services enable appengine.googleapis.com &&
    if [ ! -d python-docs-samples ]; then
      git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
    fi
  " || true

# ================== CLONE SAMPLE REPOSITORY ==================
echo "${TEAL_TEXT}${BOLD_TEXT}Cloning sample repository...${RESET_FORMAT}"

rm -rf python-docs-samples

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world || {
  echo "${RED_TEXT}Failed to enter sample directory.${RESET_FORMAT}"
  exit 1
}

# ================== UPDATE APPLICATION MESSAGE ==================
echo "${LIME_TEXT}${BOLD_TEXT}Updating application message...${RESET_FORMAT}"

sed -i "32c\    return \"$MESSAGE\"" main.py

# ================== CREATE APP ENGINE APPLICATION ==================
echo "${NAVY_TEXT}${BOLD_TEXT}Creating App Engine application...${RESET_FORMAT}"

gcloud app describe >/dev/null 2>&1 || \
gcloud app create \
  --service-account="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --region="$REGION"

# ================== DEPLOY APPLICATION ==================
echo "${TEAL_TEXT}${BOLD_TEXT}Deploying application...${RESET_FORMAT}"
gcloud app deploy --quiet

# ================== OPEN APP URL ==================
APP_URL=$(gcloud app browse --no-launch-browser 2>/dev/null | tail -n 1)

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Application deployed successfully!${RESET_FORMAT}"
if [[ -n "$APP_URL" ]]; then
  echo "${CYAN_TEXT}App URL: ${UNDERLINE_TEXT}${APP_URL}${RESET_FORMAT}"
fi

# ================== FINALIZE LAB-SETUP INSTANCE ==================
echo "${LIME_TEXT}${BOLD_TEXT}Finalizing lab setup...${RESET_FORMAT}"

gcloud compute ssh lab-setup \
  --zone "$ZONE" \
  --project "$PROJECT_ID" \
  --quiet \
  --command "
    gcloud services enable appengine.googleapis.com >/dev/null 2>&1
  " || true

# ================== SUCCESS MESSAGE ==================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo

# ================== CLEANUP ==================
cd ~
rm -rf python-docs-samples
rm -f -- "$0"
