#!/bin/bash

#author: Hoang Duong <hoangf.da@gmail.com> - https://github.com/wizhub

PROCESSING_DIR="/home/vagrant/delivery"
GIT_REPO="/home/vagrant/git/repository"
TMP_DIR="/home/vagrant/tmp"
TMP_COUNTER=0

LOG_DIR="/home/vagrant/delivery/logs"


PROCESSED_DIR="$LOG_DIR/processed"

# $1: log type: delivery, deployment
# $2: log level: INFO, WARNING, DEBUG, ERROR
# $3: log message
log2file() {  	
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
  
  if [ ! -f "$PROCESSED_DIR" ]; then
    mkdir -p $PROCESSED_DIR
  fi

  log2file "delivery" "info" "Initializing daemon..."
  
  if [ ! -d "$TMP_DIR" ]; then
    mkdir $TMP_DIR
  else
    rm -rf $TMP_DIR/*
  fi  
}

startCommit(){

init

# Lookup all .tar.gz and .zip archive
for file in $PROCESSING_DIR/*.tar.gz $PROCESSING_DIR/*.zip
do
	if [ -f "$file" ]; then
	  	TMP_COUNTER=$(($TMP_COUNTER+1))
	  	# Extract to tmp dir
	  	mkdir -p "/$TMP_DIR/$TMP_COUNTER"
	  	log2file "delivery" "info" "=========$file================================"
	  	log2file "delivery" "debug" "Extracting $file to /$TMP_DIR/$TMP_COUNTER .."
		{	
			# try to extract the archive using tarball
			tar xvzf $file -C "$TMP_DIR/$TMP_COUNTER" > /dev/null			
		} || {
			# extract the archive using unzip
			unzip -u $file -d "$TMP_DIR/$TMP_COUNTER" > /dev/null 
		}

		local tmp="$TMP_DIR/$TMP_COUNTER"
		local manifest="$tmp/manifest.txt"
		if [ ! -f $manifest ]; then
			log2file "delivery" "warning" "Can NOT find manifest.txt from $file archive"	
		else
			log2file "delivery" "debug" "Read file $manifest from $file archive"
			while read rawline
			do			
				# local line=$(trim "$rawline")
				local line="`echo "$rawline" | xargs`"			
			    log2file "delivery" "debug" "Got the line $line"
			    local filename
			    local branch
			    local message
			    #skip comment
				if [[ "$line" != \#* ]]; then
					log2file "delivery" "debug" "Processing line $line"
					# echo $line
					# split $line by commas
	      			filename=$(echo $line | cut -f1 -d,)
	      			branch=$(echo $line | cut -f2 -d,)
	      			message=$(echo $line | cut -f3 -d,)
	      			log2file "delivery" "debug" "Preparing to commit $filename to $branch with message: $message "
	      			
	      			if [ ! -f $tmp/$filename ]; then
	      				log2file "delivery" "error" "Cannot find $commitFile in directory $TMP_DIR/$TMP_COUNTER/"      				
	      			else
	      				# try to commit $filename to $branch with message $message
	      				(
					     	git --git-dir=$GIT_REPO/.git --work-tree=$GIT_REPO checkout $branch > /dev/null 2>&1 &&
							ls $tmp
					        cp $tmp/$filename $GIT_REPO/$filename &&
					        git --git-dir=$GIT_REPO/.git --work-tree=$GIT_REPO add $GIT_REPO/$filename > /dev/null 2>&1 &&
					        git --git-dir=$GIT_REPO/.git --work-tree=$GIT_REPO commit -m "$message" > /dev/null 2>&1 &&					        
					        log2file "delivery" "info" "Committed file $filename to $branch successfully"
					    ) ||
					    (
					        log2file "delivery" "error" "Failed to commit $filename to $branch "
					        continue
					    )
	      			fi
				fi
			done < $manifest
		fi
		# Move processed file to PROCESSED_DIR
		log2file "delivery" "debug" "Moving file $file to $PROCESSED_DIR..."
		mv $file $PROCESSED_DIR
	fi
done
}


# Run commit job
startCommit