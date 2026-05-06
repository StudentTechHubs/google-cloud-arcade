#!/bin/bash

# ================== COLORS ==================

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
RESET='\033[0m'
BOLD='\033[1m'

clear

# ================== HEADER ==================

echo -e "${CYAN}${BOLD}====================================================${RESET}"
echo -e "${CYAN}${BOLD}        🚀 PERKVERSE AUTO LAB SCRIPT 🚀              ${RESET}"
echo -e "${CYAN}${BOLD}====================================================${RESET}"
echo -e "${GREEN}YouTube: https://www.youtube.com/@PerkVers${RESET}"
echo

# ================== INPUT ==================

read -p "Enter Zone (example: us-east4-c): " ZONE

if [[ -z "$ZONE" ]]; then
echo -e "${RED}❌ Zone cannot be empty!${RESET}"
exit 1
fi

REGION="${ZONE%-*}"
PROJECT_ID=$(gcloud config get-value project)

echo -e "${GREEN}Project: $PROJECT_ID${RESET}"
echo -e "${GREEN}Zone: $ZONE | Region: $REGION${RESET}"

# ================== CONFIG ==================

echo -e "${BLUE}${BOLD}[1/6] Setting config...${RESET}"
gcloud config set compute/zone "$ZONE" >/dev/null
gcloud config set compute/region "$REGION" >/dev/null

# ================== CREATE VM ==================

echo -e "${MAGENTA}${BOLD}[2/6] Creating VM (gcelab)...${RESET}"
gcloud compute instances create gcelab 
--zone "$ZONE" 
--machine-type e2-standard-2 
--quiet

# ================== CREATE DISK ==================

echo -e "${CYAN}${BOLD}[3/6] Creating disk (mydisk)...${RESET}"
gcloud compute disks create mydisk 
--size=200GB 
--zone "$ZONE" 
--quiet

# ================== ATTACH DISK ==================

echo -e "${YELLOW}${BOLD}[4/6] Attaching disk...${RESET}"
gcloud compute instances attach-disk gcelab 
--disk mydisk 
--zone "$ZONE" 
--quiet

sleep 8

# ================== REMOTE SETUP ==================

echo -e "${BLUE}${BOLD}[5/6] Formatting & mounting disk...${RESET}"

gcloud compute ssh gcelab --zone "$ZONE" --quiet --command="
echo 'Checking attached disks...'
lsblk

DEVICE=$(lsblk -dpno NAME | grep -v sda | head -n 1)

if [ -z "$DEVICE" ]; then
echo 'No extra disk found!'
exit 1
fi

echo 'Using device:' $DEVICE

sudo mkdir -p /mnt/mydisk

echo 'Formatting disk...'
sudo mkfs.ext4 -F $DEVICE

echo 'Mounting disk...'
sudo mount $DEVICE /mnt/mydisk

echo 'Persisting mount...'
echo "$DEVICE /mnt/mydisk ext4 defaults 0 2" | sudo tee -a /etc/fstab

echo '✅ Disk mounted successfully!'
"

# ================== VERIFY ==================

echo -e "${GREEN}${BOLD}[6/6] Verifying mount...${RESET}"
gcloud compute ssh gcelab --zone "$ZONE" --quiet --command="df -h | grep mydisk"

# ================== FINAL ==================

echo
echo -e "${CYAN}${BOLD}====================================================${RESET}"
echo -e "${GREEN}${BOLD}        ✅ LAB COMPLETED SUCCESSFULLY!               ${RESET}"
echo -e "${CYAN}${BOLD}====================================================${RESET}"
echo
echo -e "${MAGENTA}${BOLD}🔥 Powered by PerkVerse (@PerkVers)${RESET}"
echo -e "${BLUE}👉 https://www.youtube.com/@PerkVers${RESET}"
echo -e "${YELLOW}Like 👍 Share 🔁 Subscribe 🔔${RESET}"
echo

# ================== CLEANUP ==================

echo -e "${YELLOW}Cleaning script...${RESET}"
rm -f -- "$0"
