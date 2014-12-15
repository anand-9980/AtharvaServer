#!/bin/bash
echo "starting to write"
i=1
while true
do

for j in {1..10}
do
echo "=====================================================================================================================================================================  this is line -- $j -> $i" | tee -a delTest.log
done

i=$((i+1))
sleep 1

done

