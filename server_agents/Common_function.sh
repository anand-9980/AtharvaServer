#!/bin/bash
#********************************************************************************************************************
# Purpose : List of common function which will be used across scripts
# Date : 1st November 2014
# Author : SHI - Abhishek
#********************************************************************************************************************


#--1. To overcome sqlite concurent insertion problem this was created
function sqlite_query {
  local databaseName=$1
  local QUERY=$2
  local OUTPUT=""
  local RUN=1
  while [ "$RUN" = "1" ]; do
    OUTPUT=$(sqlite3 "$databaseName.db" "$QUERY" 2>>/dev/null)
    RETURNVAL="$?"
    if [ "$RETURNVAL" = "5" ]; then
      sleep 1;
    else
      RUN=O;
    fi
  done
  echo ${OUTPUT[@]}
}

