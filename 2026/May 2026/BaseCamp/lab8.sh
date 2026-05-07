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
BG_BLUE=$(tput setab 4)

BOLD=$(tput bold)
RESET=$(tput sgr0)

clear

# ===================== HEADER =====================

echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${CYAN}${BOLD}        🎙️ PERKVERSE SPEECH API LAB SCRIPT          ${RESET}"
echo "${CYAN}${BOLD}====================================================${RESET}"
echo "${GREEN}YouTube: https://www.youtube.com/@PerkVers${RESET}"
echo

echo "${YELLOW}${BOLD}Starting Execution...${RESET}"
echo

# ===================== API CHECK =====================

if [[ -z "$API_KEY" ]]; then
echo "${RED}${BOLD}❌ ERROR: API_KEY variable is not set.${RESET}"
echo "${YELLOW}Run:${RESET} export API_KEY=YOUR_API_KEY"
exit 1
fi

echo "${GREEN}✅ API Key detected${RESET}"
echo

# ===================== CREATE REQUEST FILE =====================

echo "${BLUE}${BOLD}[1/3] Creating request.json...${RESET}"

cat > request.json <<EOF
{
"config": {
"encoding": "FLAC",
"languageCode": "en-US"
},
"audio": {
"uri": "gs://cloud-samples-tests/speech/brooklyn.flac"
}
}
EOF

echo "${GREEN}✅ request.json created${RESET}"
echo

# ===================== SEND API REQUEST =====================

echo "${MAGENTA}${BOLD}[2/3] Sending Speech-to-Text API Request...${RESET}"

curl -s -X POST 
-H "Content-Type: application/json" 
--data-binary @request.json 
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \

> result.json

echo "${GREEN}✅ API response saved to result.json${RESET}"
echo

# ===================== DISPLAY RESULT =====================

echo "${CYAN}${BOLD}[3/3] Transcription Result:${RESET}"
echo

cat result.json

echo
echo "${BG_GREEN}${BLACK}${BOLD} LAB COMPLETED SUCCESSFULLY ${RESET}"
echo

echo "${GREEN}${BOLD}====================================================${RESET}"
echo "${GREEN}${BOLD}         ✅ SPEECH API LAB FINISHED                 ${RESET}"
echo "${GREEN}${BOLD}====================================================${RESET}"
echo

echo "${MAGENTA}${BOLD}🔥 Powered by PerkVerse (@PerkVers)${RESET}"
echo "${BLUE}👉 https://www.youtube.com/@PerkVers${RESET}"
echo "${YELLOW}Like 👍 Share 🔁 Subscribe 🔔${RESET}"
echo
