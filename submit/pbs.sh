# PBS translator

for ARG in $ARGS
do
	ANAME=`echo $ARG | cut -d ':' -f1`
	AVAL=`echo $ARG | cut -d ':' -f2`
	if [ $ANAME = "cpu" ]
	then
		SUBARGS="$SUBARGS -l nodes=1:ppn=$AVAL"
	fi
done

HOLDFOR=""
if [ ${#REQS} -ne "0" ]
then
	#echo $REQS
	HOLDFOR="-W depend=afterok"
	for REQ in $REQS
	do
		REQNODE=`arrayGet PROVIDES $REQ`
		HOLDID=`arrayGet ${SAMPLE}_JOBIDS ${REQNODE}`
		HOLDFOR="$HOLDFOR:$HOLDID"
	done
fi

# Submit to PBS
JOBID=`qsub \
	$HOLDFOR \
	-V \
	-N $JOB_NAME \
	-e $FILE_LOG_ERR \
	-o $FILE_LOG_OUT \
	$SUBARGS \
	$NODE \
	$ADDS`






# RoStr, back to you!
