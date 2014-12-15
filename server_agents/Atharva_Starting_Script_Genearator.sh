#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script is used to generate the starting script location for a job
#Created Date : 3 Nov  2014
#Created By : SHI - Abhishek
#
#*************************************************************************************************************************/
#-- Script related variables
scriptName="$(basename -- "$this")"

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh

#-- Creating Script for FIRST RUN - Changing the table name 
if [[ $1 == "-FIRST_RUN" ]]; then
	tblJobConf=$tblFirstRunJobConf
	echo "==>INFO: Inside -FIRST_RUN option, this will create FIRST run script from table-$tblJobConf where at_script_generated='N'" 
	#-- Get all scripts for which starting script needs to be geretaed
	jobs_for_wchich_scripts_to_be_gen=`sqlite_query "$databaseName" "SELECT request_id FROM $tblJobConf where at_script_generated='N';"`
	if [[ -z $jobs_for_wchich_scripts_to_be_gen ]]; then
        	echo "==>INFO: No new job found for which script has to be generated, exiting"
        	exit 0
	fi
	#-- Start looping for each job_id's
	for request_id in $jobs_for_wchich_scripts_to_be_gen; do
        	echo "job- $job_id--"
        	#-- Get all required information for job
        	job_name=`sqlite_query "$databaseName" "SELECT job_name FROM $tblJobConf where request_id=$request_id ;"`
        	cd_command=`sqlite_query "$databaseName" "SELECT cd_command FROM $tblJobConf where request_id=$request_id ;"`
        	starting_script=`sqlite_query "$databaseName" "SELECT starting_script FROM $tblJobConf where request_id=$request_id ;"`
        	run_command=`sqlite_query "$databaseName" "SELECT run_command FROM $tblJobConf where request_id=$request_id ;"`
        	echo "==>INFO: JOB INFORMATION-> job_name=$job_name, cd_command=$cd_command, starting_script=$starting_script, run_command=$run_command"
        	at_script_location=`sqlite_query "$databaseName" "SELECT at_script_location FROM $tblJobConf where request_id=$request_id ;"`

        	#-- Check if all required parameters for job are present
        	if [[ -z $job_name ]] || [[ -z $cd_command ]] || [[ -z $starting_script ]] || [[  -z $run_command ]] || [[ -z $at_script_location ]]; then
                	echo "Dont have ample job related information to create script for request_id=$request_id"
                	exit 1
        	fi
		#-- Replace all white-spaces with _ in job_name
		job_name="${job_name// /_}" 
        	#-- Append every script with AT_
        	at_run_script_name="$starting_name$job_name.sh"
        	final_file="$at_script_location/$at_run_script_name"
        	echo "==>INFO: Creating if has right permission"

        	#-- Check if write permission is there
        	if [ -w $at_script_location ]; then
                	#-- Start creating the script
                	echo "INFO==> Writting to location $final_file"
                	DATE=`date +%Y-%m-%d`
                	echo -e "#!/bin/bash " > $final_file
                	echo -e "#*************************************************************************************************************************" >> $final_file
                	echo -e "#Created Date : $DATE" >> $final_file
                	echo -e "#Created By : ATHARVA AUTOMATED PROCESS" >> $final_file
                	echo -e "#************************************************************************************************************************* \n \n" >> $final_file
                	echo "#-- Script related variables" >> $final_file
                	echo "#-- Job Specific variables :ENDS"  >> $final_file
                	#-- Job specific parameters
                	echo "job_id=$job_id " >> $final_file
                	echo -e "job_name=\"$job_name\" " >> $final_file
                	echo -e "cd_command=\"$cd_command\" " >> $final_file
                	echo -e "starting_script=\"$starting_script\" " >> $final_file
                	echo -e "run_command=\"$run_command\" " >> $final_file
		 	echo "#-- Job Specific variables :ENDS" >> $final_file
                	#-- Use standard template to generate rest of the information
                	cat TEMPLATE_STARTING_SCRTIP.sh >> $final_file
                	echo "==> INFO: SCRIPT create for request_id=$request_id"
                	#-- Update first run job conf so that same job_id is not picked again
                	sqlite_query "$databaseName" "UPDATE $tblJobConf SET at_script_generated='Y', at_run_script_name='$at_run_script_name' WHERE request_id='$request_id' ;"
                	if [[ $? -ne 0 ]]; then
                        	echo "==>ERROR: Unable to update the database for job_id=$job_id, exiting"
                        	exit 1
                	fi
        	else
                	echo "ERROR==> Dont have permission to write in directory $at_script_location, exiting"
                	exit 1
        	fi
	done
	exit 0
fi
	

#-- Script created on basis of first run
#-- Get all scripts for which starting script needs to be geretaed
jobs_for_wchich_scripts_to_be_gen=`sqlite_query "$databaseName" "SELECT job_id FROM $tblJobConf where trace='Y' AND at_script_generated='N';"`
if [[ -z $jobs_for_wchich_scripts_to_be_gen ]]; then
	echo "==>INFO: No new job found for which script has to be generated, exiting"
	exit 0
fi

#-- Start looping for each job_id's
for job_id in $jobs_for_wchich_scripts_to_be_gen; do
	echo "job- $job_id--"
	#-- Get all required information for job
	job_name=`sqlite_query "$databaseName" "SELECT job_name FROM $tblJobConf where trace='Y' AND job_id=$job_id ;"`
	cd_command=`sqlite_query "$databaseName" "SELECT cd_command FROM $tblJobConf where trace='Y' AND job_id=$job_id ;"`
	starting_script=`sqlite_query "$databaseName" "SELECT starting_script FROM $tblJobConf where trace='Y' AND job_id=$job_id ;"`	
	run_command=`sqlite_query "$databaseName" "SELECT run_command FROM $tblJobConf where trace='Y' AND job_id=$job_id ;"`
	echo "==>INFO: JOB INFORMATION-> job_name=$job_name, cd_command=$cd_command, starting_script=$starting_script, run_command=$run_command"
	at_script_location=`sqlite_query "$databaseName" "SELECT at_script_location FROM $tblJobConf where trace='Y' AND job_id=$job_id ;"`
	
	#-- Check if all required parameters for job are present
	if [[ -z $job_name ]] || [[ -z $cd_command ]] || [[ -z $starting_script ]] || [[  -z $run_command ]] || [[ -z $at_script_location ]]; then
		echo "Dont have ample job related information to create script for job_id=$job_id"
		exit 1
	fi
	
	#-- Append every script with AT_
	at_run_script_name="$starting_name$job_name.sh"
	final_file="$at_script_location/$at_run_script_name"
	echo "==>INFO: Creating if has right permission"
	
	#-- Check if write permission is there	
	if [ -w $at_script_location ]; then
		#-- Start creating the script
		echo "INFO==> Writting to location $final_file"
		DATE=`date +%Y-%m-%d`
		echo -e "#!/bin/bash " > $final_file
		echo -e "#*************************************************************************************************************************" >> $final_file
		echo -e "#Created Date : $DATE" >> $final_file
		echo -e "#Created By : ATHARVA AUTOMATED PROCESS" >> $final_file
		echo -e "#************************************************************************************************************************* \n \n" >> $final_file
		echo "#-- Script related variables" >> $final_file
		echo "#-- Job Specific variables :ENDS"  >> $final_file
		#-- Job specific parameters
		echo "job_id=$job_id " >> $final_file
		echo -e "job_name=\"$job_name\" " >> $final_file
		echo -e "cd_command=\"$cd_command\" " >> $final_file
		echo -e "starting_script=\"$starting_script\" " >> $final_file
		echo -e "run_command=\"$run_command\" " >> $final_file
		echo "#-- Job Specific variables :ENDS" >> $final_file 
		#-- Use standard template to generate rest of the information
		cat TEMPLATE_STARTING_SCRTIP.sh >> $final_file
		echo "==> INFO: SCRIPT create for job_id=$job_id"
		#-- Update job conf so that same job_id is not picked again
		sqlite_query "$databaseName" "UPDATE $tblJobConf SET at_script_generated='Y', at_run_script_name='$at_run_script_name' WHERE job_id=$job_id ;"
		if [[ $? -ne 0 ]]; then
			echo "==>ERROR: Unable to update the database for job_id=$job_id, exiting"
			exit 1
		fi
	else
		echo "ERROR==> Dont have permission to write in directory $at_script_location, exiting"
		exit 1
	fi
done
