#!/bin/bash
# --------------------- For testing -----------
#-- This script will run all jobs 

#-- clean old strace logs
#sudo rm /home/user/aanand1/expStrace/dev_agent_tracer/trace_pool/*

#--- Hit all jobs
echo "==>INFO: going to job directory"
cd /home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts/ 
echo "==>INFO: Running main job AT_dummy_post_proc.sh"
bash AT_dummy_post_proc.sh &

echo "==> INFO: Running AT_a_1_exp.sh"
#bash AT_a_1_exp.sh &
echo "==>INFO : starting another job - AT_a_2_exp.sh"
#bash AT_a_2_exp.sh &

echo "==>INFO : starting another job - AT_a_3_exp.sh"
#bash AT_a_3_exp.sh &

echo "==>INFO : starting another job -AT_10_call_pig.sh"
#bash AT_10_call_pig.sh &

wait
echo -e "\n ==> All job completed, exiting"
exit 0
