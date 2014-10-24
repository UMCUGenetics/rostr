# Local translator
# Do the actual work
submitForReal() {
    echo $ARG_TASKID
	source $NODE
	JOBID="N/A: Local run"
}

# Dump the output and errors to files as if you were the real thing
submit() {
	ARR_START=1
	ARR_END=1
	ARR_STEP=1
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
				
		if [ $ANAME = "array" ]
		then
			ARR_START=`echo $AVAL | cut -d '-' -f1`
			ARR_END=`echo $AVAL | cut -d '-' -f2 | cut -d ',' -f1`
			ARR_STEP=`echo $AVAL | cut -d ',' -f2`
		fi
	done
	    
	for SEQ_ITER in $(seq $ARR_START $ARR_STEP $ARR_END)
	do
		export ARG_TASKID=$SEQ_ITER
		submitForReal >> $FILE_LOG_OUT 2>> $FILE_LOG_ERR
	done
}
