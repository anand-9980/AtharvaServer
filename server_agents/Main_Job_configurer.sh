#!/bin/bash
#*************************************************************************************************************************
#Purpose : This script is used to configure a job
#Created Date : 1 Nov  2014
#Created By : SHI - Abhishek
#
#*************************************************************************************************************************/
#-- Script related variables
create_table=" CREATE TABLE IF NOT EXISTS "
#-- Load properties
. ./CONF_ATHARVA_AGENT.properties

script="$(basename -- "$this")"
echo "$databaseName"

#-- Manual
function manual(){

echo -e "\n \e[32m ==>INFO: About this script \e[0m "

}

#-- Does initialization every time this script is called
function intiateDatabase() {
	#-- Create if jobConfTable does not exists
	final_struct="$create_table  $tblJobConf ( $tblJobConfSchema );"
	sqlite3  $databaseName.db "$final_struct"
	if [[ $? -ne 0 ]]; then
    		echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblJobConf  \e[0m "
        	exit 12
	fi
	echo "--- Table $tblJobConf created successfully if not present"
	
	#-- Create if firstRunjobConf does not exists
        final_struct="$create_table  $tblFirstRunJobConf ( $tblFirstRunJobConfSchema );"
        sqlite3  $databaseName.db "$final_struct"
        if [[ $? -ne 0 ]]; then
                echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblFirstRunJobConf  \e[0m "
                exit 12
        fi
        echo "--- Table $tblFirstRunJobConf created successfully if not present"
        
	#-- Create if runTransactions does not exists
        final_struct="$create_table  $tblRunTransaction ( $tblRunTransactionSchema );"
        sqlite3  $databaseName.db "$final_struct"
        if [[ $? -ne 0 ]]; then
                echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblRunTransaction  \e[0m "
                exit 12
        fi
        echo "--- Table $tblRunTransaction created successfully if not present"
	
	#-- Create if currentRunningPool does not exists
        final_struct="$create_table  $tblCurrentRunningJob ( $tblCurrentRunningJobSchema );"
        sqlite3  $databaseName.db "$final_struct"
        if [[ $? -ne 0 ]]; then
                echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblCurrentRunningJob  \e[0m "
                exit 12
        fi
        echo "--- Table $tblCurrentRunningJob created successfully if not present"
	
	#-- Create if firstRunjobConf does not exists
        final_struct="$create_table  $tblFirstRunJobConf ( $tblFirstRunJobConfSchema );"
        sqlite3  $databaseName.db "$final_struct"
        if [[ $? -ne 0 ]]; then
                echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblFirstRunJobConf  \e[0m "
                exit 12
        fi
        echo "--- Table $tblFirstRunJobConf created successfully if not present"

	#-- Create if firstTimeRunTracker does not exists
        final_struct="$create_table  $tblFirstTimeRunTracker ( $tblFirstTimeRunTrackerSchema );"
        sqlite3  $databaseName.db "$final_struct"
        if [[ $? -ne 0 ]]; then
                echo -e "\n ==>ERROR-- \e[31m ERROR while creating table - $tblFirstTimeRunTracker  \e[0m "
                exit 12
        fi
        echo "--- Table $tblFirstTimeRunTracker created successfully if not present"
}
intiateDatabase 

#-- Check if input argument is passed
if [ $# -eq 0 ]; then
	manual
	exit 0
fi

#--4. If the option is -IST insert steps
if [[ $1 == "-IST" ]]; then
    echo "==>INFO-- Updating/Inserting steps to be run"
    if [[ -z $2 ]] || [[ -z $3 ]]; then
        echo -e "\e[31m ==>ERROR-- Second variable [JobName] or Third variable [Step details] does not exists \e[0m "
                exit 11
    else
                sqlite3 $databaseName.db "INSERT INTO $tblJobConf VALUES $3"
                rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "\n==>INFO-- \e[32m For Job - $2, Step inserted is $3  \e[0m  \n"
                        exit $rc
                else
                        echo -e "\e[31m ==>ERROR-- Could insert the steps in table - $tblJobConf for $3 \e[0m"
                        exit $rc
                fi
    fi
fi
set -x
#-- For first run this is called -FR
if [[ $1 == "-FR" ]]; then
    echo "==>INFO-- Updating/Inserting steps to be run"
    if [[ -z $2 ]] || [[ -z $3 ]]; then
        echo -e "\e[31m ==>ERROR-- Second variable [JobName] or Third variable [Step details] does not exists \e[0m "
                exit 11
    else
                sqlite3 $databaseName.db "INSERT INTO "$tblFirstRunJobConf" VALUES ( $3 )";
                rc=$?
                if [[ $rc -eq 0 ]]; then
                        echo -e "\n==>INFO-- \e[32m For Job - $2, Step inserted is $3  \e[0m  \n"
                        exit $rc
                else
                        echo -e "\e[31m ==>ERROR-- Could insert the steps in table - $tblFirstRunJobConf for $3 \e[0m"
                        exit $rc
                fi
    fi
fi

echo -e "\n==>INFO- \e[32m Exiting from Configuration script  \e[0m "
