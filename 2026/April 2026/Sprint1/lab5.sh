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
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE PERKVERSE - INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
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

# Set project variables
PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# Task 1: Configure HTTP and health check firewall rules
echo ""
echo "=== TASK 1: Configuring Firewall Rules ==="

echo "Creating HTTP firewall rule..."
gcloud compute firewall-rules create app-allow-http \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=10.10.0.0/16 \
    --rules=tcp:80

echo "Creating health check firewall rule..."
gcloud compute firewall-rules create app-allow-health-check \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --rules=tcp

echo "Firewall rules created successfully!"
echo ""

# Task 2
echo "=== TASK 2: Creating Instance Templates and Groups ==="

gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-b \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION

sleep 30

gcloud compute instance-groups managed create instance-group-1 \
    --template=instance-template-1 \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --zone=$ZONE_A

gcloud compute instance-groups managed create instance-group-2 \
    --template=instance-template-2 \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --zone=$ZONE_B

sleep 60

gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --zone=$ZONE_A \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8

gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --zone=$ZONE_B \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8

echo "Instance groups created!"
echo ""

# Utility VM
gcloud compute instances create utility-vm \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --private-network-ip=10.10.20.50 \
    --zone=$UTILITY_ZONE \
    --tags=lb-backend

sleep 90

# Load Balancer
echo "=== TASK 3: Internal Load Balancer ==="

gcloud compute health-checks create tcp my-ilb-health-check \
    --port=80 \
    --region=$REGION

gcloud compute backend-services create my-ilb-backend-service \
    --load-balancing-scheme=INTERNAL \
    --protocol=TCP \
    --health-checks=my-ilb-health-check \
    --health-checks-region=$REGION \
    --region=$REGION

gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-1 \
    --instance-group-zone=$ZONE_A \
    --region=$REGION

gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-2 \
    --instance-group-zone=$ZONE_B \
    --region=$REGION

gcloud compute addresses create my-ilb-ip \
    --region=$REGION \
    --subnet=subnet-b \
    --addresses=10.10.30.5

gcloud compute forwarding-rules create my-ilb \
    --load-balancing-scheme=INTERNAL \
    --network=my-internal-app \
    --subnet=subnet-b \
    --address=10.10.30.5 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=my-ilb-backend-service \
    --backend-service-region=$REGION \
    --region=$REGION

sleep 60

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@PerkVers${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
