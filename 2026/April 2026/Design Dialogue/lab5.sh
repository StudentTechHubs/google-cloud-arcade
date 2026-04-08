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
TEAL=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      STUDENTTECHHUB - INITIATING EXECUTION 🚀         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ==============================
# INPUT ZONE
# ==============================
echo "${CYAN_TEXT}Enter compute zone${RESET_FORMAT}"
read -p "Zone (e.g. us-central1-a): " ZONE

export ZONE
gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/zone $ZONE

# ==============================
# CLEAN + CLONE
# ==============================
cd ~
rm -rf monolith-to-microservices

git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd monolith-to-microservices

# ==============================
# SETUP
# ==============================
./setup.sh

# ==============================
# ENABLE API
# ==============================
gcloud services enable container.googleapis.com

# ==============================
# CREATE CLUSTER
# ==============================
gcloud container clusters create fancy-cluster \
  --num-nodes=3 \
  --machine-type=e2-standard-4

# ==============================
# DEPLOY MONOLITH
# ==============================
./deploy-monolith.sh

# ==============================
# WAIT FUNCTION
# ==============================
wait_for_ip() {
  SERVICE_NAME=$1
  echo "${TEAL}Waiting for external IP for $SERVICE_NAME...${RESET_FORMAT}"

  while true; do
    IP=$(kubectl get svc $SERVICE_NAME --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -n "$IP" ]]; then
      echo "${GREEN_TEXT}$SERVICE_NAME IP: $IP${RESET_FORMAT}"
      break
    fi
    sleep 10
  done
}

# ==============================
# ORDERS MICROSERVICE
# ==============================
cd ~/monolith-to-microservices/microservices/src/orders

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/orders:1.0.0 .

kubectl create deployment orders --image=gcr.io/$DEVSHELL_PROJECT_ID/orders:1.0.0 || true

kubectl expose deployment orders \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8081 || true

wait_for_ip orders

ORDERS_IP=$(kubectl get svc orders --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# ==============================
# UPDATE MONOLITH
# ==============================
cd ~/monolith-to-microservices/react-app

sed -i "s|REACT_APP_ORDERS_URL=.*|REACT_APP_ORDERS_URL=http://$ORDERS_IP/api/orders|" .env.monolith

npm run build:monolith

cd ~/monolith-to-microservices/monolith

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/monolith:2.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/$DEVSHELL_PROJECT_ID/monolith:2.0.0

# ==============================
# PRODUCTS MICROSERVICE
# ==============================
cd ~/monolith-to-microservices/microservices/src/products

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/products:1.0.0 .

kubectl create deployment products --image=gcr.io/$DEVSHELL_PROJECT_ID/products:1.0.0 || true

kubectl expose deployment products \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8082 || true

wait_for_ip products

PRODUCTS_IP=$(kubectl get svc products --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# ==============================
# UPDATE AGAIN
# ==============================
cd ~/monolith-to-microservices/react-app

sed -i "s|REACT_APP_PRODUCTS_URL=.*|REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP/api/products|" .env.monolith

npm run build:monolith

cd ~/monolith-to-microservices/monolith

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/monolith:3.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/$DEVSHELL_PROJECT_ID/monolith:3.0.0

# ==============================
# FRONTEND
# ==============================
cd ~/monolith-to-microservices/react-app

cp .env.monolith .env
npm run build

cd ~/monolith-to-microservices/microservices/src/frontend

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/frontend:1.0.0 .

kubectl create deployment frontend --image=gcr.io/$DEVSHELL_PROJECT_ID/frontend:1.0.0 || true

kubectl expose deployment frontend \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 || true

wait_for_ip frontend

# ==============================
# DELETE MONOLITH
# ==============================
kubectl delete deployment monolith || true
kubectl delete service monolith || true

# ==============================
# FINAL STATUS
# ==============================
kubectl get services

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     STUDENTTECHHUB LAB COMPLETED SUCCESSFULLY ✅      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
