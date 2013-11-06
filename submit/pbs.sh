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
	echo $REQS
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
	-N RoStr_${SAMPLE}_${NODENAME} \
	-e $DIR_LOG/${SAMPLE}_${NODENAME}.e${STAMP} \
	-o $DIR_LOG/${SAMPLE}_${NODENAME}.o${STAMP} \
	$SUBARGS \
	$NODE \
	$ADDS`






# RoStr, back to you!
