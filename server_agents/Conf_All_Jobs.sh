#!/bin/bash
#*************************************************************************************************************************

#-- Write all jobs to be traced
step[0]="(123, 'dummy_post_proc', 'main_dp_post_process.sh', '/home/user/aanand1/expStrace', 'main_dp_post_process.sh','bash main_dp_post_process.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
step[1]="(124, 'a_1_exp', 'a_1_exp.sh', '/home/user/aanand1/expStrace', 'a_1_exp.sh','bash a_1_exp.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
step[2]="(125, 'a_2_exp', 'a_2_exp.sh', '/home/user/aanand1/expStrace', 'a_2_exp.sh','bash a_2_exp.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
step[3]="(126, 'a_3_exp', 'a_3_exp.sh', '/home/user/aanand1/expStrace', 'a_3_exp.sh','bash a_3_exp.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
step[4]="(127, '10_call_pig', '10_call_pig.sh', '/home/user/aanand1/expStrace', '10_call_pig.sh','bash 10_call_pig.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
#step[5]="(128, 'main_dp_post_process', 'main_dp_post_process.sh', '/home/user/aanand1/expStrace', 'main_dp_post_process.sh','bash main_dp_post_process.sh','/home/user/aanand1/expStrace', 'SINGLE', 'Y', '23:30', '2014-10-01:23:00:00', 'Y', '', '/home/user/aanand1/expStrace/dev_agent_tracer/atharva_starting_scripts', 'N')"
#-- Insert jobs into jobConf table

#-- Delete all values from tablr before inserting -
sqlite3 DB_ATHARVA.db "DELETE FROM jobConf;"
#-- Iterate over all steps and insert
for var in "${step[@]}"
do
        echo "Calling .. "
        bash Main_Job_configurer.sh "-IST" "NA" "${var}"
        rcf=$?
        if [[ $rcf -eq 0 ]]; then
                    echo -e "==>INFO-- \e[32m Success.. \e[0m"
                else
                    echo -e "\e[31m ==>ERROR-- STEPS  could not be inserted  &&&&&&&&  \e[0m"
                    exit $rcf
                fi
done

