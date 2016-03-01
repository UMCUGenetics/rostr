# SLURM translator
submit() {
    echo ${ARGS[@]}
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
		if [ $ANAME = "cpu" ]
		then
			SUBARGS="$SUBARGS -c $(($AVAL<$ARG_JOB_CPU_MAX?$AVAL:$ARG_JOB_CPU_MAX))"
		fi
		
		if [ $ANAME = "array" ]
		then
			SUBARGS="$SUBARGS -a ${AVAL//,/:}"
		fi
	done

	# Obtain hold ids, replace splitting tag by actual arguments
	HOLDFOR=""
	if [ ${#REQS} -ne "0" ]
	then
		HOLDFOR=`getHoldIds`
		HOLDFOR=${HOLDFOR//;/,}
		HOLDFOR="-d ${HOLDFOR/,/}"
	fi

	# Submit to SGE
	JOBID=`sbatch \
		$HOLDFOR \
		-J $JOB_NAME \
		-e $FILE_LOG_ERR \
		-o $FILE_LOG_OUT \
		$SUBARGS \
		$NODE \
		$ADDS`
	
	# Fix the JobID
	JOBID=`echo $JOBID | cut -d\  -f4`
}
