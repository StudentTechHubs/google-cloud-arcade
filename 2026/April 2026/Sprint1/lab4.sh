#!/bin/bash

# ==============================
# COLORS
# ==============================
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

echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      STUDENTTECHHUB - NETWORK LAB EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

# ==============================
# INPUTS
# ==============================
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE (example us-central1-a): ${RESET_FORMAT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION_2 (example us-east1): ${RESET_FORMAT}" REGION_2

export ZONE REGION_2
export REGION="${ZONE%-*}"

# ==============================
# PROJECT
# ==============================
gcloud config set project $DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}Project: $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}Region: $REGION${RESET_FORMAT}"

# ==============================
# CREATE NETWORKS
# ==============================
gcloud compute networks create managementnet --subnet-mode=custom || true

gcloud compute networks subnets create managementsubnet-1 \
  --network=managementnet \
  --region=$REGION \
  --range=10.130.0.0/20 || true

gcloud compute networks create privatenet --subnet-mode=custom || true

gcloud compute networks subnets create privatesubnet-1 \
  --network=privatenet \
  --region=$REGION \
  --range=172.16.0.0/24 || true

gcloud compute networks subnets create privatesubnet-2 \
  --network=privatenet \
  --region=$REGION_2 \
  --range=172.20.0.0/20 || true

# ==============================
# FIREWALL RULES
# ==============================
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
  --network=managementnet \
  --allow icmp,tcp:22,tcp:3389 \
  --source-ranges=0.0.0.0/0 || true

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
  --network=privatenet \
  --allow icmp,tcp:22,tcp:3389 \
  --source-ranges=0.0.0.0/0 || true

# ==============================
# VM INSTANCES
# ==============================
gcloud compute instances create managementnet-vm-1 \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=managementsubnet-1 || true

gcloud compute instances create privatenet-vm-1 \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=privatesubnet-1 || true

# ==============================
# APPLIANCE VM
# ==============================
gcloud compute instances create vm-appliance \
  --zone=$ZONE \
  --machine-type=e2-standard-4 \
  --network-interface=subnet=privatesubnet-1 \
  --network-interface=subnet=managementsubnet-1 || true

# ==============================
# DONE
# ==============================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         STUDENTTECHHUB LAB COMPLETED SUCCESSFULLY 🚀 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
