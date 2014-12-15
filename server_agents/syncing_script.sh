


#trace_pool=`sqlite3 DB_ATHARVA.db "select logTraceFile from runTransactionsIGour"`


#echo $trace_pool > temp_file
<<1
while read line
do
sleep 3;
        # display $line or do somthing with $line
	echo "$line"
done < temp_file
1

count=0;
set -x 
while [ 1 ];
do
	count=`expr $count + 1`
	echo  -e "$count run .........\n";
	for f in `ls -m1 test_igour`
	do
	sleep 1;
	  echo $f
	sleep 1;
	done	
#	ls -m1 trace_pool_igour;
	#cd /home/user/aanand1/expStrace/dev_agent_tracer;
	#ls -l 2>>/dev/null
#	sleep 1;
done
