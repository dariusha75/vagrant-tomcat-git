#!/bin/bash

#author: Hoang Duong <hoangf.da@gmail.com> - https://github.com/wizhub

GIT_REPO="/home/vagrant/git/repository"
LOG_DIR="/home/vagrant/delivery/logs"
TMP_DIR="/home/vagrant/tmp"
TOMCAT_HOME="/var/lib/tomcat6"
TMP_COUNTER=0
DEPLOYED_DIR="$LOG_DIR/deployed"

# $1: log type: delivery, deployment
# $2: log level: INFO, WARNING, DEBUG, ERROR
# $3: log message
log2file(){  	
  	LOG_FILENAME="$LOG_DIR/$1_$(date +"%Y%m%d").txt"
  	if [ ! -f "$LOG_FILENAME" ]; then
	    touch $LOG_FILENAME
	fi
  	level="$2"
    echo "$(date +"%m-%d-%Y %T") - ${level^^} : $3" >> "$LOG_FILENAME"
}

# initialize
init() {        
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 
  fi
  
  if [ ! -f "$DEPLOYED_DIR" ]; then
    mkdir -p $DEPLOYED_DIR
  fi

  log2file "deployment" "info" "Initializing daemon..."
  
}

startDeploy() {
	init
	cd $GIT_REPO
	listCommits="`git log --format="%H" --since="5 minutes ago"`"
	for commit in $listCommits
	do
		fullBranch="`git branch --contains "$commit"`"
		branch="`echo "${fullBranch#\*}" | xargs`"
		log2file "deployment" "debug" "here is last commit: $commit === branch: $branch"
		echo "here is commit: $commit === branch: $branch"

		listFile="`git show --pretty="format:" --name-only "$commit"`"
		for file in $listFile
		do 
			if [[ $file == *.war ]]; then
				if [ -f "$GIT_REPO/$file" ]; then
				echo "Process: $file on branch: $branch"
				log2file "deployment" "debug" "Processing: $file on branch: $branch.."
				local appName="${file%*.}"
				local deployName="$branch-$appName"
				log2file "deployment" "debug" "Deploying $file to $TOMCAT_HOME/webapps/$deployName.."
				echo "Deploying $file to $TOMCAT_HOME/webapps/$deployName"
				# Remove the application if it exist
				if [ -d "$TOMCAT_HOME/webapps/$deployName" ]; then
					log2file "deployment" "debug" "Remove existed application $deployName in $TOMCAT_HOME/webapps"
					rm -rf "$TOMCAT_HOME/webapps/$deployName"
				fi
				# Copy new application war file to be auto deploy by tomcat
				(
					cp "$GIT_REPO/$file" "$TOMCAT_HOME/webapps/$deployName"
					log2file "deployment" "info" "Deployed $GIT_REPO/$file to $TOMCAT_HOME/webapps/ under $deployName name successfully"
					log2file "deployment" "debug" "Back up file $GIT_REPO/$file to $DEPLOYED_DIR..."
					cp "$GIT_REPO/$file" "$DEPLOYED_DIR/$file"					
				) || (
					log2file "deployment" "error" "Failed to deploy $GIT_REPO/$file to $TOMCAT_HOME/webapps/ under $deployName name"
				)
				else
					log2file "deployment" "warning" " $GIT_REPO/$file is not a valid war file!"
				fi			
			fi
		done
	done
}

startDeploy