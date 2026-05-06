#!/bin/bash

# ===================== COLOR SETUP =====================

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BOLD=`tput bold`
RESET=`tput sgr0`

clear

# ===================== HEADER =====================

echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${CYAN}${BOLD}        🚀 PERKVERSE CLOUD LAB AUTOMATION 🚀         ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${GREEN}YouTube: https://www.youtube.com/@PerkVers${RESET}"
echo

echo "${YELLOW}${BOLD}Starting Execution...${RESET}"
echo

# ===================== STEP 1 =====================

echo "${BLUE}${BOLD}[1/7] Setting Compute Zone...${RESET}"
export ZONE=$(gcloud compute project-info describe 
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -z "$ZONE" ]; then
echo "${RED}Zone not found. Please set manually using:${RESET}"
echo "gcloud config set compute/zone ZONE_NAME"
exit 1
fi

echo "${GREEN}Zone: $ZONE${RESET}"

# ===================== STEP 2 =====================

echo "${MAGENTA}${BOLD}[2/7] Fetching Project Info...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} 
--format="value(projectNumber)")

echo "${GREEN}Project ID: $PROJECT_ID${RESET}"

# ===================== STEP 3 =====================

echo "${YELLOW}${BOLD}[3/7] Creating VM 'gcelab'...${RESET}"
gcloud compute instances create gcelab 
--zone=$ZONE 
--machine-type=e2-medium 
--tags=http-server 
--service-account=$[PROJECT_NUMBER-compute@developer.gserviceaccount.com](mailto:PROJECT_NUMBER-compute@developer.gserviceaccount.com) 
--scopes=https://www.googleapis.com/auth/cloud-platform 
--image-family=debian-11 
--image-project=debian-cloud 
--quiet

# ===================== STEP 4 =====================

echo "${RED}${BOLD}[4/7] Creating VM 'gcelab2'...${RESET}"
gcloud compute instances create gcelab2 
--machine-type=e2-medium 
--zone=$ZONE 
--quiet

# ===================== STEP 5 =====================

echo "${CYAN}${BOLD}[5/7] Installing NGINX on gcelab...${RESET}"
gcloud compute ssh gcelab --zone "$ZONE" --quiet --command 
"sudo apt-get update -y && sudo apt-get install -y nginx && ps aux | grep nginx"

# ===================== STEP 6 =====================

echo "${MAGENTA}${BOLD}[6/7] Creating Firewall Rule...${RESET}"
gcloud compute firewall-rules create allow-http 
--network=default 
--allow=tcp:80 
--target-tags=http-server 
--quiet

# ===================== STEP 7 =====================

echo "${GREEN}${BOLD}[7/7] Cleaning temporary lab files...${RESET}"

for file in *; do
if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
if [[ -f "$file" ]]; then
rm "$file"
echo "${YELLOW}Removed: $file${RESET}"
fi
fi
done

# ===================== FINAL MESSAGE =====================

echo
echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${GREEN}${BOLD}        ✅ LAB COMPLETED SUCCESSFULLY!               ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo
echo "${MAGENTA}${BOLD}🔥 Powered by PerkVerse (@PerkVers)${RESET}"
echo "${BLUE}👉 https://www.youtube.com/@PerkVers${RESET}"
echo "${YELLOW}Like 👍 Share 🔁 Subscribe 🔔${RESET}"
echo
