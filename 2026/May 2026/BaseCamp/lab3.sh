#!/bin/bash

# ==========================================================
# PerkVerse - Google Cloud Lab Automation Script
# Lab: Cloud Storage + Compute Engine + Persistent Disk + NGINX
# YouTube: https://www.youtube.com/@PerkVers
# ==========================================================

# -------------------- Colors --------------------
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_GREEN=$(tput setab 2)
BG_RED=$(tput setab 1)
BG_BLUE=$(tput setab 4)

BOLD=$(tput bold)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)

# -------------------- Banner --------------------
clear
echo "${BG_BLUE}${WHITE}${BOLD}==============================================================${RESET}"
echo "${BG_BLUE}${WHITE}${BOLD}              PERKVERSE - INITIATING EXECUTION               ${RESET}"
echo "${BG_BLUE}${WHITE}${BOLD}==============================================================${RESET}"
echo
echo "${CYAN}${BOLD}Lab Tasks:${RESET}"
echo "${GREEN}1.${RESET} Create Cloud Storage Bucket"
echo "${GREEN}2.${RESET} Create Compute Engine VM"
echo "${GREEN}3.${RESET} Create and Attach Persistent Disk"
echo "${GREEN}4.${RESET} Install and Verify NGINX"
echo

# -------------------- Project Info --------------------
echo "${YELLOW}${BOLD}Fetching Project Details...${RESET}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED}${BOLD}Error: No active Google Cloud project found.${RESET}"
    exit 1
fi

ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [[ -z "$ZONE" ]]; then
    ZONE="us-central1-a"
fi

REGION="${ZONE%-*}"

echo "${GREEN}Project ID : ${PROJECT_ID}${RESET}"
echo "${GREEN}Zone       : ${ZONE}${RESET}"
echo "${GREEN}Region     : ${REGION}${RESET}"
echo

# -------------------- Task 1: Bucket --------------------
echo "${MAGENTA}${BOLD}Task 1: Creating Cloud Storage Bucket...${RESET}"

BUCKET_NAME="${PROJECT_ID}-bucket"

if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
    echo "${YELLOW}Bucket already exists: gs://${BUCKET_NAME}${RESET}"
else
    gsutil mb -l US "gs://${BUCKET_NAME}"
    echo "${GREEN}Bucket created: gs://${BUCKET_NAME}${RESET}"
fi

# -------------------- Task 2: VM --------------------
echo
echo "${MAGENTA}${BOLD}Task 2: Creating Compute Engine VM...${RESET}"

if gcloud compute instances describe my-instance \
    --zone="$ZONE" >/dev/null 2>&1; then
    echo "${YELLOW}Instance already exists. Deleting old instance...${RESET}"
    gcloud compute instances delete my-instance \
        --zone="$ZONE" --quiet
    sleep 10
fi

gcloud compute instances create my-instance \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --tags=http-server

echo "${GREEN}VM 'my-instance' created successfully.${RESET}"

# -------------------- Task 3: Persistent Disk --------------------
echo
echo "${MAGENTA}${BOLD}Task 3: Creating Persistent Disk...${RESET}"

if gcloud compute disks describe mydisk \
    --zone="$ZONE" >/dev/null 2>&1; then
    echo "${YELLOW}Disk already exists. Deleting old disk...${RESET}"
    gcloud compute disks delete mydisk \
        --zone="$ZONE" --quiet
    sleep 5
fi

gcloud compute disks create mydisk \
    --zone="$ZONE" \
    --size=200GB

echo "${GREEN}Disk 'mydisk' created successfully.${RESET}"

echo "${CYAN}Attaching disk to VM...${RESET}"
gcloud compute instances attach-disk my-instance \
    --disk=mydisk \
    --zone="$ZONE"

echo "${GREEN}Disk attached successfully.${RESET}"

# -------------------- Wait --------------------
echo
echo "${YELLOW}${BOLD}Waiting for VM initialization...${RESET}"
sleep 30

# -------------------- Task 4: Install NGINX --------------------
echo
echo "${MAGENTA}${BOLD}Task 4: Installing NGINX...${RESET}"

cat > install_nginx.sh <<'EOF'
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "NGINX installed successfully!"
EOF

chmod +x install_nginx.sh

gcloud compute scp install_nginx.sh \
    my-instance:/tmp/ \
    --zone="$ZONE" \
    --quiet

gcloud compute ssh my-instance \
    --zone="$ZONE" \
    --quiet \
    --command="bash /tmp/install_nginx.sh"

rm -f install_nginx.sh

# -------------------- Get External IP --------------------
EXTERNAL_IP=$(gcloud compute instances describe my-instance \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo
echo "${GREEN}${BOLD}NGINX Installed Successfully!${RESET}"
echo "${CYAN}Web Server URL:${RESET} http://${EXTERNAL_IP}"
echo

# -------------------- HTTP Test --------------------
echo "${YELLOW}${BOLD}Testing HTTP Response...${RESET}"

if curl -s --head --max-time 10 "http://${EXTERNAL_IP}" | grep -q "200 OK"; then
    echo "${GREEN}HTTP 200 OK - Web server is working perfectly.${RESET}"
else
    echo "${YELLOW}Server may still be starting. Open the URL manually in your browser.${RESET}"
fi

# -------------------- Final Summary --------------------
echo
echo "${BG_GREEN}${BLACK}${BOLD}==============================================================${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}               LAB COMPLETED SUCCESSFULLY!                   ${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}==============================================================${RESET}"
echo
echo "${CYAN}${BOLD}Task Summary:${RESET}"
echo "${GREEN}✓${RESET} Cloud Storage bucket created"
echo "${GREEN}✓${RESET} Compute Engine VM created"
echo "${GREEN}✓${RESET} Persistent disk created and attached"
echo "${GREEN}✓${RESET} NGINX installed and verified"
echo
echo "${RED}${BOLD}${UNDERLINE}https://www.youtube.com/@PerkVers${RESET}"
echo "${GREEN}${BOLD}Don't forget to Like, Share and Subscribe for more lab solutions!${RESET}"
echo

# -------------------- Self Cleanup --------------------
rm -f -- "$0"
