
echo "==>INFO Running java"
#java  -classpath ".:sqlite-jdbc-3.8.7.jar" TestSqlite "currentRunningPool"
echo "Running Sender"

java -cp all_running_job_activemq.jar com.shi.JobInfoSender "runTransactions"
#java -cp strace_pool_sender_activemq.jar com.shi.LiveStarcePoolSender "runTransactions" "atharva_proc_msgs"
if [[ $? -ne 0 ]]; then
	echo "Falied to run java"
else
	echo "Java called successfully"
fi
echo "==>INFO: Run completed"
