#!/bin/bash

# ==============================
# COLORS & FORMATTING
# ==============================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        STUDENTTECHHUB - EXECUTION STARTED               ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

# ==============================
# REGION SETUP
# ==============================
export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# ==============================
# GET LOAD BALANCER IP
# ==============================
export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')

echo "${GREEN_TEXT}Load Balancer IP Found: $EXTERNAL_IP_FANCY${RESET_FORMAT}"

# ==============================
# UPDATE REACT ENV
# ==============================
cd ~/monolith-to-microservices/react-app/

cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

# ==============================
# BUILD REACT APP
# ==============================
npm install
npm run build

# ==============================
# UPLOAD TO BUCKET
# ==============================
cd ~
rm -rf monolith-to-microservices/*/node_modules

gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

# ==============================
# ROLLING REPLACE FRONTEND
# ==============================
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable=100%

# ==============================
# AUTOSCALING
# ==============================
gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
    --zone=$ZONE \
    --max-num-replicas=2 \
    --target-load-balancing-utilization=0.60

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
    --zone=$ZONE \
    --max-num-replicas=2 \
    --target-load-balancing-utilization=0.60

# ==============================
# ENABLE CDN
# ==============================
gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn \
    --global

# ==============================
# CREATE NEW TEMPLATE
# ==============================
gcloud compute instance-templates create fancy-fe-new \
    --region=$REGION \
    --source-instance-template=fancy-fe

# ==============================
# UPDATE MIG TEMPLATE
# ==============================
gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
    --zone=$ZONE \
    --version=template=fancy-fe-new

# ==============================
# UPDATE WEBSITE CONTENT
# ==============================
cd ~/monolith-to-microservices/react-app/src/pages/Home

if [ -f index.js.new ]; then
    mv index.js.new index.js
fi

# ==============================
# REBUILD AFTER CONTENT CHANGE
# ==============================
cd ~/monolith-to-microservices/react-app
npm install
npm run build

# ==============================
# REUPLOAD
# ==============================
cd ~
rm -rf monolith-to-microservices/*/node_modules

gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

# ==============================
# FINAL ROLLING REPLACE
# ==============================
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable=100%

# ==============================
# CLEANUP
# ==============================
rm -f TechCode1.sh TechCode2.sh

# ==============================
# DONE
# ==============================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}All tasks executed successfully.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Autoscaling + CDN + Deployment completed.${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Load Balancer IP:${RESET_FORMAT} ${WHITE_TEXT}$EXTERNAL_IP_FANCY${RESET_FORMAT}"
