#!/bin/bash

#######################################################
### Script: install_uploader.sh			            ###
### Author: Joseph Lee                              ###
#######################################################
# dependencies unzip
#######################################################
# Input Parameters:
# $1 directory of where the logfiles are located
# $2 wildcard of logfile to ingest all
# $3 target bucket to upload files in
#######################################################

if [ $# -ne 3 ]; then
  echo "Illegal number of arguments passed."
  echo "Usage: install_uploader.sh <log_directory> <log_wildcard> <target_bucket>"
  echo "e.g.   install_uploader.sh \"/path/to/logs/\" \"*myfile.log*\" \"target_bucket\""
  exit 1
fi

##------------------------------------------------------------------------------------
# configure awscli
# append the contents of the generated credentials file to the existing file

# check if ~/.aws/ directory exists. if not create.
# then add the credentials and config files to that directory
##------------------------------------------------------------------------------------
function configure() {
    if test -d ~/.aws; then
        echo 'backing up credentials'
        sudo mv ~/.aws/config ~/.aws/config.original.willrestore
        sudo mv ~/.aws/credentials ~/.aws/credentials.original.willrestore
        sudo cp config ~/.aws/.
        sudo cp credentials ~/.aws/.
    else
        echo 'setting up credentials'
        sudo mkdir ~/.aws
        sudo cp config ~/.aws/.
        sudo cp credentials ~/.aws/.
    fi
    chmod 600 ~/.aws/config
    chmod 600 ~/.aws/credentials
}


##------------------------------------------------------------------------------------
# go to target directory
# then upload everything (with the right wildcards)
function upload_data() {
    log_directory=${1}
    log_wildcard=${2}
    target_bucket=${3}

    if test -d ${log_directory}; then
        cd ${log_directory}
        aws s3 cp . s3://${target_bucket}/ --recursive --profile s3uploader --exclude "*" --include "${log_wildcard}*"
    else
        printf "Invalid directory ${log_directory}"
        exit
    fi

}

function teardown() {
    # if there is a backup config already, then it means that awscli exists.
    if test -a ~/.aws/config.original.willrestore; then
        echo 'restoring configs to original state!'
        sudo mv ~/.aws/config.original.willrestore ~/.aws/config
        sudo mv ~/.aws/credentials.original.willrestore ~/.aws/credentials
    else
        # if no backup config, delete awscli entirely because it means it wasn't installed originally
        echo 'restoring system to original state!'
        sudo rm -R ~/.aws/
        sudo rm -rf /usr/local/aws
        sudo rm /usr/local/bin/aws
    fi
}



##------------------------------------------------------------------------------------
# check if awscli exists on the system and installs it if necessary

# check sudo access
rootid=$(id -u)
if [ "$rootid" -ne 0 ] ; then
    echo "no root, please change to root"
    exit
else
    echo "yes root"
    if aws --version &>/dev/null ; then
        # awscli exists!
        echo "good to go!"
    else
        echo "awscli doesnt exist"
        # awscli doesn't exist! installing awscli...
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip awscli-bundle.zip

        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
        # See if $PATH contains /usr/local/bin (output will be empty if it doesnt)
        ispath=$(echo $PATH | grep /usr/local/bin)
        if [ -z "$ispath" ] ; then
            echo 'adding /usr/local/bin to PATH...'
            export PATH=/usr/local/bin:$PATH
        fi
    fi

    configure
    upload_data ${1} ${2} ${3}
    teardown

fi
