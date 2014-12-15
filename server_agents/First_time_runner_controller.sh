#!/bin/bash
#*************************************************************************************************************************
#Created Date : 11 Nov  2014
#Created By : SHI - Abhishek
#
#*************************************************************************************************************************/

#-- Script related variables
scriptName=`basename $0`
queueNameForFirstRun="firstRunPool"
unique_stace_op_Location="NA"
log_location="/home/user/aanand1/expStrace/dev_agent_tracer/log_firct_run.txt"
#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh


#-- Function : starts

#-- Main program starts

#-- Get all new requests
echo "==>INFO: Calling adapter to fetch all new requests"
bash Adapter_Atharva_Database.sh "-GET_ALL_NEW_REQUEST_FROM_ATHARVA"
if [[ $? -ne 0 ]]; then
        echo -e "\n ==>ERROR-- Inserting all valid requests for first run from table - MYSQL-job_info, into SQLITE-firstRunjobConf "
	#-- TODO Update falire into mysql table
        exit 1
fi


#-- Generate all scripts for new request
echo "==>INFO: Generating starting scripts"
bash Atharva_Starting_Script_Genearator.sh "-FIRST_RUN"
if [[ $? -ne 0 ]]; then
        echo -e "\n ==>ERROR-- Creating starting script for all new requests "
        #-- TODO Update falire into mysql table
        exit 1
fi

#-- Iterate for each job and start running
all_request_ids=`sqlite_query "$databaseName" "SELECT request_id FROM $tblFirstRunJobConf where first_run_comp='N';"`
if [[ -z $all_request_ids ]]; then
	echo "==>DEBUG:-$scriptName- No new request fro which FIRST RUN is required is found, exiting"
	exit 0
else
	for request_id in $all_request_ids; do
		echo "==>INFO: Will execute first run for request_id=$request_id"
		#-- Run the script as first run now
		bash Atharva_First_TimeRunner.sh $request_id &
	done
fi
#-- Wait for all processes to complete before exiting
wait
echo "==>INFO:-$scriptName=========== ALL DONE ========== Completed all FIRST RUN request, EXITING =="
exit 0
#-- Change status in MYSQl table-requestInfo column-status to WIP

#-- Once done send this output to strcae
#-- Start Posting strace
firstRunStraceLoc="/home/user/aanand1/expStrace/dev_agent_tracer/trace_pool/9_dummy_post_proc.txt"
echo "==>INFO: Starting to send strace output for FIRST RUN from file - $firstRunStraceLoc"

java -cp first_run_activemq.jar com.shi.FirstRunStarceSender "$firstRunStraceLoc" "$queueNameForFirstRun"
if [[ $? -ne 0 ]]; then
	echo -e "\n ==>ERROR-- \e[31m While sending output FIRST RUN to ACTIVEMQ, RequestID-$requestId, STRACE_LOCATION-$firstRunStraceLoc \e[0m "
        exit 1
fi

echo "==>INFO: Script completed"
