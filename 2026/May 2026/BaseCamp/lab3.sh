#!/bin/bash

# ===================== COLORS =====================

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

BOLD=$(tput bold)
RESET=$(tput sgr0)

clear

# ===================== HEADER =====================

echo "${CYAN}${BOLD}========================================================${RESET}"
echo "${CYAN}${BOLD}         🚀 PERKVERSE CLOUD LAB AUTOMATION 🚀           ${RESET}"
echo "${CYAN}${BOLD}========================================================${RESET}"
echo "${GREEN}YouTube: https://www.youtube.com/@PerkVers${RESET}"
echo

echo "${MAGENTA}${BOLD}Starting Execution...${RESET}"
echo

# ===================== PROJECT DETAILS =====================

echo "${YELLOW}${BOLD}[1/8] Fetching Project Details...${RESET}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
echo "${RED}❌ Failed to fetch Project ID${RESET}"
exit 1
fi

ZONE=$(gcloud compute project-info describe 
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

[[ -z "$ZONE" ]] && ZONE="us-central1-a"

REGION="${ZONE%-*}"

echo "${GREEN}✅ Project ID : $PROJECT_ID${RESET}"
echo "${GREEN}✅ Zone       : $ZONE${RESET}"
echo "${GREEN}✅ Region     : $REGION${RESET}"
echo

# ===================== CONFIG =====================

echo "${BLUE}${BOLD}[2/8] Setting Compute Config...${RESET}"

gcloud config set compute/zone "$ZONE" >/dev/null
gcloud config set compute/region "$REGION" >/dev/null

# ===================== STORAGE BUCKET =====================

echo "${YELLOW}${BOLD}[3/8] Creating Storage Bucket...${RESET}"

BUCKET_NAME="${PROJECT_ID}-bucket"

if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
echo "${YELLOW}⚠ Bucket already exists: $BUCKET_NAME${RESET}"
else
gsutil mb -l US gs://$BUCKET_NAME
echo "${GREEN}✅ Bucket created${RESET}"
fi

# ===================== VM CREATION =====================

echo "${MAGENTA}${BOLD}[4/8] Creating VM Instance...${RESET}"

if gcloud compute instances describe my-instance 
--zone="$ZONE" >/dev/null 2>&1; then

```
echo "${YELLOW}⚠ Existing VM found. Recreating...${RESET}"

gcloud compute instances delete my-instance \
    --zone="$ZONE" \
    --quiet
```

fi

gcloud compute instances create my-instance 
--machine-type=e2-medium 
--zone="$ZONE" 
--image-family=debian-12 
--image-project=debian-cloud 
--boot-disk-size=10GB 
--boot-disk-type=pd-balanced 
--tags=http-server 
--quiet

echo "${GREEN}✅ VM Created${RESET}"

# ===================== DISK CREATION =====================

echo "${CYAN}${BOLD}[5/8] Creating Persistent Disk...${RESET}"

if gcloud compute disks describe mydisk 
--zone="$ZONE" >/dev/null 2>&1; then

```
echo "${YELLOW}⚠ Existing disk found. Recreating...${RESET}"

gcloud compute disks delete mydisk \
    --zone="$ZONE" \
    --quiet
```

fi

gcloud compute disks create mydisk 
--size=200GB 
--zone="$ZONE" 
--quiet

echo "${GREEN}✅ Disk Created${RESET}"

# ===================== ATTACH DISK =====================

echo "${BLUE}${BOLD}[6/8] Attaching Disk to VM...${RESET}"

gcloud compute instances attach-disk my-instance 
--disk=mydisk 
--zone="$ZONE" 
--quiet

echo "${GREEN}✅ Disk Attached${RESET}"

echo "${YELLOW}Waiting for VM initialization...${RESET}"
sleep 20

# ===================== INSTALL NGINX =====================

echo "${MAGENTA}${BOLD}[7/8] Installing NGINX...${RESET}"

cat > install_nginx.sh <<'EOF'
#!/bin/bash

sudo apt update -y
sudo apt install nginx -y

sudo systemctl enable nginx
sudo systemctl start nginx

echo "NGINX Installed Successfully!"
EOF

chmod +x install_nginx.sh

gcloud compute scp install_nginx.sh 
my-instance:/tmp/install_nginx.sh 
--zone="$ZONE" 
--quiet

gcloud compute ssh my-instance 
--zone="$ZONE" 
--quiet 
--command="bash /tmp/install_nginx.sh"

rm -f install_nginx.sh

echo "${GREEN}✅ NGINX Installed${RESET}"

# ===================== GET EXTERNAL IP =====================

echo "${CYAN}${BOLD}[8/8] Verifying Web Server...${RESET}"

EXTERNAL_IP=$(gcloud compute instances describe my-instance 
--zone="$ZONE" 
--format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo
echo "${GREEN}${BOLD}========================================================${RESET}"
echo "${GREEN}${BOLD}            ✅ LAB COMPLETED SUCCESSFULLY               ${RESET}"
echo "${GREEN}${BOLD}========================================================${RESET}"
echo

echo "${CYAN}🌐 Website URL:${RESET} http://${EXTERNAL_IP}"
echo

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP)

if [[ "$HTTP_STATUS" == "200" ]]; then
echo "${GREEN}✅ HTTP Status: 200 OK${RESET}"
else
echo "${YELLOW}⚠ Server may still be starting...${RESET}"
fi

echo
echo "${BG_GREEN}${BLACK}${BOLD} ALL TASKS COMPLETED SUCCESSFULLY ${RESET}"
echo

echo "${MAGENTA}${BOLD}🔥 Powered by PerkVerse (@PerkVers)${RESET}"
echo "${BLUE}👉 https://www.youtube.com/@PerkVers${RESET}"
echo "${YELLOW}Like 👍 Share 🔁 Subscribe 🔔${RESET}"
echo
