# Torque translator
submit() {
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
		if [ $ANAME = "cpu" ]
		then
			SUBARGS="$SUBARGS -l nodes=1:ppn=$(($AVAL<$ARG_JOB_CPU_MAX?$AVAL:$ARG_JOB_CPU_MAX))"
		fi
		
		if [ $ANAME = "array" ]
		then
			SUBARGS="$SUBARGS -t ${AVAL//,/:}"
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
	
	# Submit to Torque
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
