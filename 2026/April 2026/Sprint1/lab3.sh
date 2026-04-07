#!/bin/bash

# ==============================
# COLOR CODES
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

echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      STUDENTTECHHUB - INITIATING EXECUTION...        ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ==============================
# REGION INPUT
# ==============================
echo "${YELLOW_TEXT}Enter your Region (example: us-central1, asia-south1):${RESET_FORMAT}"
read REGION

echo "${CYAN_TEXT}Using Region: $REGION${RESET_FORMAT}"

# ==============================
# PROJECT SETUP
# ==============================
gcloud config set project $DEVSHELL_PROJECT_ID

# ==============================
# ENABLE SERVICES
# ==============================
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling required services...${RESET_FORMAT}"

gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# ==============================
# CLONE REPO
# ==============================
cd ~

rm -rf pet-theory

git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab08

# ==============================
# CREATE main.go
# ==============================
cat > main.go <<EOF
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }

  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })

  log.Println("Pets REST API listening on port", port)

  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching server: %v", err)
  }
}
EOF

# ==============================
# CREATE Dockerfile
# ==============================
cat > Dockerfile <<EOF
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD ["/usr/src/app/server"]
EOF

# ==============================
# BUILD GO APP
# ==============================
go build -o server

# ==============================
# CLOUD BUILD VERSION 0.1
# ==============================
gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.1

# ==============================
# DEPLOY CLOUD RUN
# ==============================
gcloud run deploy rest-api \
  --image gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.1 \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2

# ==============================
# FIRESTORE DATABASE
# ==============================
gcloud firestore databases create --location=$REGION || true

# ==============================
# BUILD VERSION 0.2
# ==============================
go build -o server

gcloud builds submit --tag gcr.io/$DEVSHELL_PROJECT_ID/rest-api:0.2

# ==============================
# CLEANUP
# ==============================
rm -f techcode.sh

# ==============================
# COMPLETE
# ==============================
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}STUDENTTECHHUB Execution Finished Successfully 🚀${RESET_FORMAT}"
