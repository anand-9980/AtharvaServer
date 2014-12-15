#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script is used to delete strace logs for completed jobs
#Created Date : 4 Nov  2014
#Created By : SHI - Abhishek
#
#*************************************************************************************************************************/
#-- Script related variables
scriptName="$(basename -- "$this")"

directory_to_delete=$1

#-- Load properties
. ./CONF_ATHARVA_AGENT.properties
. ./Common_function.sh

#-- Get all scripts for which starting script needs to be geretaed
logs_for_running_jobs=`sqlite_query "$databaseName" "SELECT logTraceFile FROM $tblRunTransaction;"`
if [[ -z $logs_for_running_jobs ]]; then
	echo "exiting ..."
	exit 0
fi

echo "logs_for_running_jobs is "$logs_for_running_jobs
#file_not_to_delete=`echo $logs_for_running_jobs | tr ' ' '|'`

echo "file_not_to_delete is : "$file_not_to_delete

files_name_no_delete=""
IFS=" "
ary=($logs_for_running_jobs)
for key in "${!ary[@]}";
do
    abc="${ary[$key]}"
    fileName=`basename $abc`
    files_name_no_delete=$files_name_no_delete"|"$fileName
    # CREATING ARRAY FOR ONE HIERACHY(DIV,CATG,SUBCATG COMBINATION): STARTS
done

final_files_no_delete="${files_name_no_delete#?}"


cd /home/user/aanand1/expStrace/dev_agent_tracer/trace_pool;
rm !($final_files_no_delete)

cd -

echo "final_files_no_delete --> "$final_files_no_delete

