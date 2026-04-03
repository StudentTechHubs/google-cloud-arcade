#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution - STUDENTTECHHUB${RESET}"

gcloud config set project $DEVSHELL_PROJECT_ID

git clone https://github.com/GoogleCloudPlatform/training-data-analyst

cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start

sed -i s/us-central/$REGION/g prepare_environment.sh

. prepare_environment.sh

gsutil mb gs://$DEVSHELL_PROJECT_ID-media

wget https://storage.googleapis.com/cloud-training/quests/Google_Cloud_Storage_logo.png

gsutil cp Google_Cloud_Storage_logo.png gs://$DEVSHELL_PROJECT_ID-media

export GCLOUD_BUCKET=$DEVSHELL_PROJECT_ID-media

cd quiz/gcp

cat > storage.py <<EOF_END
# TODO: Get the Bucket name from the
# GCLOUD_BUCKET environment variable
import os
bucket_name = os.getenv('GCLOUD_BUCKET')

# TODO: Import the storage module
from google.cloud import storage

# TODO: Create a client for Cloud Storage
storage_client = storage.Client()

# TODO: Use the client to get the Cloud Storage bucket
bucket = storage_client.get_bucket(bucket_name)

"""
Uploads a file to a given Cloud Storage bucket and returns the public url
to the new object.
"""
def upload_file(image_file, public):
    blob = bucket.blob(image_file.filename)

    blob.upload_from_string(
        image_file.read(),
        content_type=image_file.content_type)

    if public:
        blob.make_public()

    return blob.public_url
EOF_END

cd ../webapp/

cat > questions.py <<EOF_END
# TODO: Import the storage module
from quiz.gcp import storage, datastore

"""
uploads file into google cloud storage
- upload file
- return public_url
"""
def upload_file(image_file, public):
    if not image_file:
        return None

    public_url = storage.upload_file(
       image_file,
       public
    )

    return public_url

"""
uploads file into google cloud storage
- call method to upload file (public=true)
- call datastore helper method to save question
"""
def save_question(data, image_file):
    if image_file:
        data['imageUrl'] = str(upload_file(image_file, True))
    else:
        data['imageUrl'] = u''

    data['correctAnswer'] = int(data['correctAnswer'])
    datastore.save_question(data)
    return
EOF_END

cd ~/training-data-analyst/courses/developingapps/python/cloudstorage/start

python run_server.py

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
echo "${CYAN}${BOLD}Subscribe: https://www.youtube.com/@StudentTechHubs${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
