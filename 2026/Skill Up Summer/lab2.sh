#!/bin/bash

# ===================== COLOR DEFINITIONS =====================
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

# ===================== HELPER FUNCTIONS =====================
print_banner() {
    clear
    echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}            PerkVerse - Google Cloud Lab Automation         ${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}Custom VPC Network and Firewall Configuration Lab${RESET_FORMAT}"
    echo
    echo "${YELLOW_TEXT}${BOLD_TEXT}YouTube Channel:${RESET_FORMAT} ${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
    echo
}

section_header() {
    echo
    echo "${MAGENTA_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo "${MAGENTA_TEXT}${BOLD_TEXT}$1${RESET_FORMAT}"
    echo "${MAGENTA_TEXT}${BOLD_TEXT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET_FORMAT}"
    echo
}

success_msg() {
    echo "${GREEN_TEXT}${BOLD_TEXT}✓ $1${RESET_FORMAT}"
}

error_exit() {
    echo "${RED_TEXT}${BOLD_TEXT}✗ $1${RESET_FORMAT}"
    exit 1
}

# ===================== START =====================
print_banner

# ===================== INPUT =====================
echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter three regions:${RESET_FORMAT}"
read -p "Enter REGION 1 (e.g., us-central1): " REGION1
read -p "Enter REGION 2 (e.g., europe-west1): " REGION2
read -p "Enter REGION 3 (e.g., asia-east1): " REGION3

[[ -z "$REGION1" || -z "$REGION2" || -z "$REGION3" ]] && \
    error_exit "All three regions are required."

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} $PROJECT_ID"
echo "${CYAN_TEXT}${BOLD_TEXT}Regions Selected:${RESET_FORMAT}"
echo "  • $REGION1"
echo "  • $REGION2"
echo "  • $REGION3"

# ===================== CREATE NETWORK =====================
section_header "Creating Custom VPC Network"

gcloud compute networks create taw-custom-network \
    --subnet-mode=custom

success_msg "VPC network 'taw-custom-network' created."

# ===================== CREATE SUBNETS =====================
section_header "Creating Subnets"

gcloud compute networks subnets create subnet-$REGION1 \
    --network=taw-custom-network \
    --region=$REGION1 \
    --range=10.0.0.0/16
success_msg "subnet-$REGION1 created (10.0.0.0/16)."

gcloud compute networks subnets create subnet-$REGION2 \
    --network=taw-custom-network \
    --region=$REGION2 \
    --range=10.1.0.0/16
success_msg "subnet-$REGION2 created (10.1.0.0/16)."

gcloud compute networks subnets create subnet-$REGION3 \
    --network=taw-custom-network \
    --region=$REGION3 \
    --range=10.2.0.0/16
success_msg "subnet-$REGION3 created (10.2.0.0/16)."

# ===================== LIST SUBNETS =====================
section_header "Listing Created Subnets"
gcloud compute networks subnets list --network=taw-custom-network

# ===================== FIREWALL RULES =====================
section_header "Creating Firewall Rules"

# Allow HTTP
gcloud compute firewall-rules create nw101-allow-http \
    --network=taw-custom-network \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http
success_msg "Firewall rule 'nw101-allow-http' created."

# Allow ICMP
gcloud compute firewall-rules create nw101-allow-icmp \
    --network=taw-custom-network \
    --allow=icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=rules
success_msg "Firewall rule 'nw101-allow-icmp' created."

# Allow Internal Traffic
gcloud compute firewall-rules create nw101-allow-internal \
    --network=taw-custom-network \
    --allow=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=10.0.0.0/16,10.1.0.0/16,10.2.0.0/16
success_msg "Firewall rule 'nw101-allow-internal' created."

# Allow SSH
gcloud compute firewall-rules create nw101-allow-ssh \
    --network=taw-custom-network \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=ssh
success_msg "Firewall rule 'nw101-allow-ssh' created."

# Allow RDP
gcloud compute firewall-rules create nw101-allow-rdp \
    --network=taw-custom-network \
    --allow=tcp:3389 \
    --source-ranges=0.0.0.0/0
success_msg "Firewall rule 'nw101-allow-rdp' created."

# ===================== FINAL SUCCESS MESSAGE =====================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}               LAB COMPLETED SUCCESSFULLY! 🚀              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Resources Created:${RESET_FORMAT}"
echo "  ✅ VPC Network: taw-custom-network"
echo "  ✅ Subnet: subnet-$REGION1"
echo "  ✅ Subnet: subnet-$REGION2"
echo "  ✅ Subnet: subnet-$REGION3"
echo "  ✅ Firewall Rules:"
echo "     • nw101-allow-http"
echo "     • nw101-allow-icmp"
echo "     • nw101-allow-internal"
echo "     • nw101-allow-ssh"
echo "     • nw101-allow-rdp"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Thanks for using PerkVerse!${RESET_FORMAT}"
echo "${BLUE_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}👍 Like | 🔄 Share | 🔔 Subscribe${RESET_FORMAT}"
echo
