#!/bin/bash

# ===================== COLORS =====================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

# ===================== BANNER =====================
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}            PerkVerse - Google Cloud Lab Automation         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Custom VPC Network and Firewall Rules${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}YouTube Channel:${RESET_FORMAT} ${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo

# ===================== INPUT =====================
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION 1 (e.g., us-central1):${RESET_FORMAT}"
read REGION_1

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION 2 (e.g., europe-west1):${RESET_FORMAT}"
read REGION_2

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION 3 (e.g., asia-east1):${RESET_FORMAT}"
read REGION_3

# ===================== VALIDATION =====================
if [[ -z "$REGION_1" || -z "$REGION_2" || -z "$REGION_3" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}❌ All three regions are required.${RESET_FORMAT}"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Regions:${RESET_FORMAT}"
echo "  • $REGION_1"
echo "  • $REGION_2"
echo "  • $REGION_3"
echo

# ===================== CREATE NETWORK =====================
echo "${MAGENTA_TEXT}${BOLD_TEXT}➤ Creating custom VPC network...${RESET_FORMAT}"
gcloud compute networks create taw-custom-network \
    --subnet-mode=custom

# ===================== CREATE SUBNETS =====================
echo "${MAGENTA_TEXT}${BOLD_TEXT}➤ Creating subnets...${RESET_FORMAT}"

gcloud compute networks subnets create subnet-$REGION_1 \
    --network=taw-custom-network \
    --region=$REGION_1 \
    --range=10.0.0.0/16

gcloud compute networks subnets create subnet-$REGION_2 \
    --network=taw-custom-network \
    --region=$REGION_2 \
    --range=10.1.0.0/16

gcloud compute networks subnets create subnet-$REGION_3 \
    --network=taw-custom-network \
    --region=$REGION_3 \
    --range=10.2.0.0/16

# ===================== FIREWALL RULES =====================
echo "${MAGENTA_TEXT}${BOLD_TEXT}➤ Creating firewall rules...${RESET_FORMAT}"

# Allow HTTP
gcloud compute firewall-rules create nw101-allow-http \
    --network=taw-custom-network \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http

# Allow ICMP
gcloud compute firewall-rules create nw101-allow-icmp \
    --network=taw-custom-network \
    --allow=icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=rules

# Allow Internal Traffic
gcloud compute firewall-rules create nw101-allow-internal \
    --network=taw-custom-network \
    --allow=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=10.0.0.0/16,10.1.0.0/16,10.2.0.0/16

# Allow SSH
gcloud compute firewall-rules create nw101-allow-ssh \
    --network=taw-custom-network \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=ssh

# Allow RDP
gcloud compute firewall-rules create nw101-allow-rdp \
    --network=taw-custom-network \
    --allow=tcp:3389 \
    --source-ranges=0.0.0.0/0

# ===================== SUCCESS MESSAGE =====================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}               LAB COMPLETED SUCCESSFULLY! 🚀              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Resources Created:${RESET_FORMAT}"
echo "  ✅ VPC Network: taw-custom-network"
echo "  ✅ Subnet: subnet-$REGION_1 (10.0.0.0/16)"
echo "  ✅ Subnet: subnet-$REGION_2 (10.1.0.0/16)"
echo "  ✅ Subnet: subnet-$REGION_3 (10.2.0.0/16)"
echo "  ✅ Firewall Rules: HTTP, ICMP, Internal, SSH, RDP"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Thanks for using PerkVerse!${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}👍 Like | 🔄 Share | 🔔 Subscribe${RESET_FORMAT}"
echo
