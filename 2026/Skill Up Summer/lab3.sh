#!/bin/bash

# ===================== COLOR DEFINITIONS =====================
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)

BOLD=$(tput bold)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)

# Random colors
TEXT_COLORS=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$MAGENTA" "$CYAN")
BG_COLORS=("$BG_RED" "$BG_GREEN" "$BG_BLUE" "$BG_MAGENTA")

RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# ===================== HELPER FUNCTIONS =====================
print_banner() {
    clear
    echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo "${CYAN}${BOLD}             PerkVerse - Cloud Lab Automation              ${RESET}"
    echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "${GREEN}${BOLD}Google Cloud Network Performance Lab${RESET}"
    echo
    echo "${YELLOW}${BOLD}YouTube Channel:${RESET} ${BLUE}${UNDERLINE}https://www.youtube.com/@PerkVers${RESET}"
    echo
}

section() {
    echo
    echo "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${MAGENTA}${BOLD}$1${RESET}"
    echo "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

success() {
    echo "${GREEN}${BOLD}✓ $1${RESET}"
}

# ===================== START =====================
print_banner
echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution...${RESET}"
echo

# ===================== GET DEFAULT ZONE & REGION =====================
section "Fetching Default Zone and Region"

export ZONE_1=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [[ -z "$ZONE_1" ]]; then
    echo "${RED}${BOLD}Could not detect default zone.${RESET}"
    exit 1
fi

export REGION_1="${ZONE_1%-*}"

gcloud config set compute/zone "$ZONE_1" >/dev/null
gcloud config set compute/region "$REGION_1" >/dev/null

success "Default Zone: $ZONE_1"
success "Default Region: $REGION_1"

# ===================== USER INPUT =====================
section "Enter Additional Zones"

read -p "Enter ZONE_2 (e.g., us-central1-b): " ZONE_2
read -p "Enter ZONE_3 (e.g., us-central1-c): " ZONE_3

export REGION_2="${ZONE_2%-*}"
export REGION_3="${ZONE_3%-*}"

success "ZONE_2: $ZONE_2 | REGION_2: $REGION_2"
success "ZONE_3: $ZONE_3 | REGION_3: $REGION_3"

# ===================== CREATE INSTANCES =====================
section "Creating VM Instances"

gcloud compute instances create us-test-01 \
    --subnet="subnet-$REGION_1" \
    --zone="$ZONE_1" \
    --machine-type=e2-standard-2 \
    --tags=ssh,http,rules
success "us-test-01 created"

gcloud compute instances create us-test-02 \
    --subnet="subnet-$REGION_2" \
    --zone="$ZONE_2" \
    --machine-type=e2-standard-2 \
    --tags=ssh,http,rules
success "us-test-02 created"

gcloud compute instances create us-test-03 \
    --subnet="subnet-$REGION_3" \
    --zone="$ZONE_3" \
    --machine-type=e2-standard-2 \
    --tags=ssh,http,rules
success "us-test-03 created"

gcloud compute instances create us-test-04 \
    --subnet="subnet-$REGION_1" \
    --zone="$ZONE_1" \
    --machine-type=e2-medium \
    --tags=ssh,http
success "us-test-04 created"

# ===================== PREPARE TOOL INSTALL SCRIPT =====================
section "Preparing Utility Installation Script"

cat > prepare_tools.sh <<'EOF'
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y traceroute mtr tcpdump iperf whois host dnsutils siege
timeout 10 traceroute -m 8 www.icann.org || true
EOF

chmod +x prepare_tools.sh
success "prepare_tools.sh created"

# ===================== INSTALL TOOLS =====================
section "Installing Tools on us-test-01"

gcloud compute scp prepare_tools.sh us-test-01:/tmp --zone="$ZONE_1" --quiet
gcloud compute ssh us-test-01 --zone="$ZONE_1" --quiet --command="bash /tmp/prepare_tools.sh"
success "Tools installed on us-test-01"

section "Installing Tools on us-test-02"

gcloud compute scp prepare_tools.sh us-test-02:/tmp --zone="$ZONE_2" --quiet
gcloud compute ssh us-test-02 --zone="$ZONE_2" --quiet --command="bash /tmp/prepare_tools.sh"
success "Tools installed on us-test-02"

section "Installing Tools on us-test-04"

gcloud compute scp prepare_tools.sh us-test-04:/tmp --zone="$ZONE_1" --quiet
gcloud compute ssh us-test-04 --zone="$ZONE_1" --quiet --command="bash /tmp/prepare_tools.sh"
success "Tools installed on us-test-04"

# ===================== START IPERF SERVER =====================
section "Starting iperf Server on us-test-01"

gcloud compute ssh us-test-01 --zone="$ZONE_1" --quiet \
    --command="nohup iperf -s > ~/iperf-server.log 2>&1 &"

success "iperf server started on us-test-01"

# ===================== RUN IPERF CLIENT =====================
section "Running iperf Client from us-test-02"

gcloud compute ssh us-test-02 --zone="$ZONE_2" --quiet \
    --command="iperf -c us-test-01.${ZONE_1}.c.${DEVSHELL_PROJECT_ID}.internal"

success "iperf test completed"

# ===================== CLEANUP TEMP FILE =====================
rm -f prepare_tools.sh

# ===================== FINAL MESSAGE =====================
echo
echo "${BG_GREEN}${BLACK}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}           LAB COMPLETED SUCCESSFULLY! 🚀                  ${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
echo

echo "${CYAN}${BOLD}Resources Created:${RESET}"
echo "  ✅ us-test-01"
echo "  ✅ us-test-02"
echo "  ✅ us-test-03"
echo "  ✅ us-test-04"
echo "  ✅ Network utilities installed"
echo "  ✅ iperf server/client tested"
echo

echo "${YELLOW}${BOLD}Thanks for using PerkVerse!${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@PerkVers${RESET}"
echo "${GREEN}${BOLD}👍 Like | 🔄 Share | 🔔 Subscribe${RESET}"
echo
