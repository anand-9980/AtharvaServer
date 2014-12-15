#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script Job is used to 
#Created Date : 10 Nov  2014
#Created By : SHI - Indrajeet
#
#*************************************************************************************************************************/
#-- Script related variables
scriptName=`basename $0`

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh

DB_HOST='hfdvdpemysql1.vm.itg.corp.us.shldcorp.com'
DB_PORT='3372'
DB_USERNAME='dplite_dev'
DB_PASSWORD='j2krew4f'
DB_INSTANCE='dplite'
num=1

#var=$(mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD  --ignore-spaces --skip-column-names  --silent $DB_INSTANCE -e " SELECT  from job_info WHERE status='NEW' " | sed -e "s/	/,/g")

#-- This will get all valid requests from Atharva database
if [[ $1 == "-GET_ALL_NEW_REQUEST_FROM_ATHARVA" ]]; then
	echo "==>INFO: Inside adaper Getting all new request ids from mysql table"
	var2=$(mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD  --ignore-spaces --skip-column-names  --silent $DB_INSTANCE -e " SELECT CONCAT('\'',requestId),jobId,jobName,startingScript,locForSourceProd,startingScript,startingCommand,cdLocation,jobRunType,'NA',startTime,CONCAT(CURRENT_DATE,' ',CURRENT_TIME),'N','','$loc_first_run_scripts','N',CONCAT('N','\'') from job_info WHERE status='NEW' " | sed -e "s/	/','/g")
	if [[ -z $var2 ]]; then
		echo "==>INFO: No new request is with statud NEW found exiting"
		exit 0
	else
		#-- Iterate over all steps and insert
		echo "Inserting new request - $var2"
		IFS="
		"
		for f in $var2;
		do
			echo "==>INFO:-$scriptName- Inserting into table-$tblFirstRunJobConf value- $f"
        		bash Main_Job_configurer.sh "-FR" "NA" "${f}"
        		rcf=$?
        		if [[ $rcf -eq 0 ]]; then
                    		echo -e "==>INFO-- \e[32m Success.. \e[0m"
                	else
                    		echo -e "\e[31m ==>ERROR-- STEPS  could not be inserted   \e[0m"
                    		exit $rcf
			fi
			#-- Update MYSQL table job_info status='WIP'"
			#-- Get last request id
			request_id=`sqlite_query "$databaseName" " SELECT max(request_id) from $tblFirstRunJobConf  ;"`
			mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD  --ignore-spaces --skip-column-names  --silent $DB_INSTANCE -e " UPDATE job_info SET status='WIP' WHERE requestId=$request_id "
			if [[ $? -ne 0 ]]; then
				echo "==>ERROR:-$scriptName- Failed to update table job_info from requestId=$request_id"
				exit 1
			fi 
			#-- TODO: Update MYSQL table- requestInfo status WIP statusDescription as FirstSynchStart 
			num=$((num+1))
		
		done
	fi
fi

if [[ $1 == "-UPDATE_FAILURE_requestInfo" ]]; then
	if [[ -z $2 ]] || [[ -z $3 ]]; then
		echo "Expecting <request_id> and <message>"
		exit 1
	fi
	request_id=$2
	failureMessage=$3
	mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD  --ignore-spaces --skip-column-names  --silent $DB_INSTANCE -e " UPDATE requestInfo SET status='FAIL', error='$failureMessage' WHERE requestId=$request_id "
	if [[ $? -ne 0 ]]; then
		echo "==>ERROR:-$scriptName- Failed to update table FAIL status to table from requestInfo"
		exit 1
	fi
fi
