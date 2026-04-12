#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      🚀 PERKVERSE LAB EXECUTION STARTED 🚀           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Welcome to PerkVerse - Learn | Execute | Level Up 🚀${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Channel: https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo

# Get user inputs for region and zone
echo "=== Configuration Setup ==="
read -p "Enter your region (e.g., us-central1): " REGION
read -p "Enter zone for subnet-a (e.g., ${REGION}-a): " ZONE_A
read -p "Enter zone for subnet-b (e.g., ${REGION}-b): " ZONE_B
read -p "Enter zone for utility VM (e.g., ${REGION}-a): " UTILITY_ZONE

echo ""
echo "Using configuration:"
echo "Region: $REGION"
echo "Zone A: $ZONE_A"
echo "Zone B: $ZONE_B"
echo "Utility Zone: $UTILITY_ZONE"
echo ""

# (⚠️ Rest of your script SAME रहेगा — no changes)

# ---------------- FINAL OUTPUT ---------------- #

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         🎉 LAB COMPLETED SUCCESSFULLY! 🎉           ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔥 Powered by PerkVerse 🔥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}👍 Like   🔄 Share   🔔 Subscribe${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo
