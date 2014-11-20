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
			ARR_START=`echo $AVAL | cut -d '-' -f1`
			ARR_END=`echo $AVAL | cut -d '-' -f2 | cut -d ',' -f1`
			ARR_STEP=`echo $AVAL | cut -d ',' -f2`
			
			if [ $ARR_STEP = "1" ]
			then
				SUBARGS="$SUBARGS -t ${ARR_START}-${ARR_END}"
			else
				SUBARGS="$SUBARGS -t $(seq -s, $ARR_START $ARR_STEP $ARR_END)"
			fi
		fi
	done

	# Obtain hold ids, replace splitting tag by actual arguments
	HOLDFOR=""
	if [ ${#REQS} -ne "0" ]
	then
		HOLDFORIDS=`getHoldIds`
		#HOLDFOR=${HOLDFOR//;/:}
		#HOLDFOR="-W depend=afterok$HOLDFOR"
		
		
		HOLDFOR_ARRAY=""
		HOLDFOR_SINGLE=""
		IFS=';' read -a HOLDFOR_ARR <<< "$HOLDFORIDS"
		for HOLDJOB in ${HOLDFOR_ARR[@]}
		do
			TEMPVAL=`echo $HOLDJOB|cut -d "." -f1`
			if [ ${TEMPVAL: -2} = '[]' ]; 
			then
				HOLDFOR_ARRAY="$HOLDFOR_ARRAY:$HOLDJOB"
			else
				HOLDFOR_SINGLE="$HOLDFOR_SINGLE:$HOLDJOB"
			fi
		done
		
		if [ ! $HOLDFOR_SINGLE = "" ]
		then
			HOLDFOR="$HOLDFOR -W depend=afterok$HOLDFOR_SINGLE"
		fi

		if [ ! $HOLDFOR_ARRAY = "" ]
		then
			HOLDFOR="$HOLDFOR -W depend=afterokarray$HOLDFOR_ARRAY"
		fi
		
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
