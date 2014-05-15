# PBS translator
submit() {
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
		if [ $ANAME = "cpu" ]
		then
			SUBARGS="$SUBARGS -l nodes=1:ppn=$AVAL"
		fi
	done

	# Obtain hold ids, replace splitting tag by actual arguments
	HOLDFOR=""
	if [ ${#REQS} -ne "0" ]
	then
		HOLDFOR=`getHoldIds`
		HOLDFOR=${HOLDFOR//;/:}
		HOLDFOR="-W depend=afterok$HOLDFOR"
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
}
