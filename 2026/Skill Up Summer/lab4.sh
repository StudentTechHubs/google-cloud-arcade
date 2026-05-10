#!/bin/bash

# =========================
# PerkVerse - Google Cloud Lab Automation Script
# Lab: Configure VPC Networks, Firewall Rules, and VM Connectivity
# YouTube: https://www.youtube.com/@PerkVers
# =========================

# ---------- Colors ----------
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# ---------- Clear Screen ----------
clear

# ---------- Banner ----------
echo -e "${CYAN}${BOLD}====================================================================${RESET}"
echo -e "${CYAN}${BOLD}                 PERKVERSE - INITIATING EXECUTION                   ${RESET}"
echo -e "${CYAN}${BOLD}====================================================================${RESET}"
echo

# ---------- Input Section ----------
echo -e "${YELLOW}${BOLD}Please enter the required configuration values:${RESET}"
echo

read -p "$(echo -e "${BLUE}${BOLD}Enter VPC_NAME: ${RESET}")" VPC_NAME
read -p "$(echo -e "${BLUE}${BOLD}Enter SUBNET_A: ${RESET}")" SUBNET_A
read -p "$(echo -e "${BLUE}${BOLD}Enter SUBNET_B: ${RESET}")" SUBNET_B
read -p "$(echo -e "${BLUE}${BOLD}Enter FIREWALL_1 (SSH Rule Name): ${RESET}")" FIREWALL_1
read -p "$(echo -e "${BLUE}${BOLD}Enter FIREWALL_2 (RDP Rule Name): ${RESET}")" FIREWALL_2
read -p "$(echo -e "${BLUE}${BOLD}Enter FIREWALL_3 (ICMP Rule Name): ${RESET}")" FIREWALL_3
read -p "$(echo -e "${BLUE}${BOLD}Enter ZONE_1 (e.g. us-central1-a): ${RESET}")" ZONE_1
read -p "$(echo -e "${BLUE}${BOLD}Enter ZONE_2 (e.g. us-east1-b): ${RESET}")" ZONE_2

# ---------- Derived Variables ----------
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
REGION_1=${ZONE_1%-*}
REGION_2=${ZONE_2%-*}
VM_1="us-test-01"
VM_2="us-test-02"

# ---------- Validation ----------
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}${BOLD}Error: Unable to detect active GCP project.${RESET}"
    exit 1
fi

# ---------- Summary ----------
echo
echo -e "${GREEN}${BOLD}================ CONFIGURATION SUMMARY ================${RESET}"
echo -e "${CYAN}Project ID   : ${WHITE}$PROJECT_ID${RESET}"
echo -e "${CYAN}VPC Name     : ${WHITE}$VPC_NAME${RESET}"
echo -e "${CYAN}Subnet A     : ${WHITE}$SUBNET_A ($REGION_1)${RESET}"
echo -e "${CYAN}Subnet B     : ${WHITE}$SUBNET_B ($REGION_2)${RESET}"
echo -e "${CYAN}Firewall 1   : ${WHITE}$FIREWALL_1${RESET}"
echo -e "${CYAN}Firewall 2   : ${WHITE}$FIREWALL_2${RESET}"
echo -e "${CYAN}Firewall 3   : ${WHITE}$FIREWALL_3${RESET}"
echo -e "${CYAN}Zone 1       : ${WHITE}$ZONE_1${RESET}"
echo -e "${CYAN}Zone 2       : ${WHITE}$ZONE_2${RESET}"
echo -e "${CYAN}VMs          : ${WHITE}$VM_1, $VM_2${RESET}"
echo -e "${GREEN}${BOLD}======================================================${RESET}"
echo

# ---------- Confirm ----------
read -p "$(echo -e "${YELLOW}${BOLD}Proceed with setup? (y/n): ${RESET}")" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}${BOLD}Setup aborted.${RESET}"
    exit 1
fi

# ---------- Start ----------
echo
echo -e "${MAGENTA}${BOLD}Starting Google Cloud VPC Lab Setup...${RESET}"
echo

# ---------- Create VPC ----------
echo -e "${BLUE}${BOLD}Creating VPC: $VPC_NAME${RESET}"
gcloud compute networks create "$VPC_NAME" \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

# ---------- Create Subnets ----------
echo -e "${BLUE}${BOLD}Creating Subnet A: $SUBNET_A${RESET}"
gcloud compute networks subnets create "$SUBNET_A" \
    --network="$VPC_NAME" \
    --region="$REGION_1" \
    --range=10.10.10.0/24

echo -e "${BLUE}${BOLD}Creating Subnet B: $SUBNET_B${RESET}"
gcloud compute networks subnets create "$SUBNET_B" \
    --network="$VPC_NAME" \
    --region="$REGION_2" \
    --range=10.10.20.0/24

# ---------- Firewall Rules ----------
echo -e "${BLUE}${BOLD}Creating Firewall Rule: $FIREWALL_1 (SSH)${RESET}"
gcloud compute firewall-rules create "$FIREWALL_1" \
    --network="$VPC_NAME" \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0

echo -e "${BLUE}${BOLD}Creating Firewall Rule: $FIREWALL_2 (RDP)${RESET}"
gcloud compute firewall-rules create "$FIREWALL_2" \
    --network="$VPC_NAME" \
    --allow=tcp:3389 \
    --source-ranges=0.0.0.0/0

echo -e "${BLUE}${BOLD}Creating Firewall Rule: $FIREWALL_3 (ICMP)${RESET}"
gcloud compute firewall-rules create "$FIREWALL_3" \
    --network="$VPC_NAME" \
    --allow=icmp \
    --source-ranges=0.0.0.0/0

# ---------- Create VM 1 ----------
echo -e "${BLUE}${BOLD}Creating VM: $VM_1${RESET}"
gcloud compute instances create "$VM_1" \
    --zone="$ZONE_1" \
    --subnet="$SUBNET_A" \
    --machine-type=e2-standard-2 \
    --tags=allow-icmp

# ---------- Create VM 2 ----------
echo -e "${BLUE}${BOLD}Creating VM: $VM_2${RESET}"
gcloud compute instances create "$VM_2" \
    --zone="$ZONE_2" \
    --subnet="$SUBNET_B" \
    --machine-type=e2-standard-2 \
    --tags=allow-icmp

# ---------- Wait ----------
echo -e "${YELLOW}${BOLD}Waiting for instances to initialize...${RESET}"
sleep 20

# ---------- Connectivity Test ----------
echo -e "${BLUE}${BOLD}Testing connectivity between VMs...${RESET}"

EXTERNAL_IP_2=$(gcloud compute instances describe "$VM_2" \
    --zone="$ZONE_2" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

gcloud compute ssh "$VM_1" \
    --zone="$ZONE_1" \
    --quiet \
    --command="ping -c 3 $EXTERNAL_IP_2"

# ---------- Final Message ----------
echo
echo -e "${CYAN}${BOLD}=======================================================${RESET}"
echo -e "${CYAN}${BOLD}              LAB COMPLETED SUCCESSFULLY!              ${RESET}"
echo -e "${CYAN}${BOLD}=======================================================${RESET}"
echo
echo -e "${RED}${BOLD}${UNDERLINE}https://www.youtube.com/@PerkVers${RESET}"
echo -e "${GREEN}${BOLD}Don't forget to Like, Share and Subscribe!${RESET}"
echo

# ---------- Self Cleanup ----------
rm -f -- "$0"
