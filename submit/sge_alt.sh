# Sun Grid Engine translator via script files

preSubmit() {
	# Setup directory to store submission scripts
	mkdir -p $DIR_OUTPUT/subscripts-${STAMP}

	# Create a cancellation script to abort SGE jobs
	FILE_CANCEL=$DIR_OUTPUT/cancel-$STAMP
	echo "qdel \`tr '\n' ' ' < $DIR_OUTPUT/jobids-$STAMP\`" > $FILE_CANCEL
	chmod +x $FILE_CANCEL
}


submit() {
	FILE_SUBSCRIPT=$DIR_OUTPUT/subscripts-${STAMP}/${NODECOUNT}-${SUBMITCOUNT}-${NODENAME}-${SAMPLE}.sh

	# Add basic variables using SGE formatting
	echo "#!/bin/bash" > $FILE_SUBSCRIPT

	echo "#$ -N $JOB_NAME" >> $FILE_SUBSCRIPT
	echo "#$ -o $FILE_LOG_OUT" >> $FILE_SUBSCRIPT
	echo "#$ -e $FILE_LOG_ERR" >> $FILE_SUBSCRIPT

	# Add optional variables using SGE formatting
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
		if [ $ANAME = "cores" ]
		then
			echo "#$ -pe $SGE_PE $(($AVAL<$ARG_JOB_CPU_MAX?$AVAL:$ARG_JOB_CPU_MAX))"
		fi
		if [ $ANAME = "memory" ]
		then
			echo "#$ -l h_vmem=${AVAL}"
		fi
		if [ $ANAME = "array" ]
		then
			echo "#$ -t ${AVAL//,/:}"
		fi
		if [ $ANAME = "wtime" ]
		then
			echo "#$ -l h_rt=${AVAL//,/:}"
		fi
	done >> $FILE_SUBSCRIPT

	# Add predecessor job ids using SGE formatting
	HOLDFOR=`getHoldIds`
	echo -e "${HOLDFOR//;/\n#$ -hold_jid }" >> $FILE_SUBSCRIPT

	# Determine bash variables the job needs to run
	KNOWNVARS=""
	MISSINGVARS=""
	USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*\|\${[a-zA-Z0-9_]*' $NODE | sed -e 's/${/$/g' | sort | uniq`)
	for USEDVAR in ${USEDVARIABLES[@]}
	do
		VARNAME=`echo $USEDVAR | cut -b 1 --complement`
		VARVAL=`eval echo $USEDVAR`
		if [ ! "$VARVAL" = "" ]
		then
			KNOWNVARS="${KNOWNVARS}${VARNAME}='${VARVAL}'\n"
		else
			MISSINGVARS="${MISSINGVARS}## ${VARNAME}\n"
		fi
	done
	echo -e "\n\n" >> $FILE_SUBSCRIPT
	
	# Add bash variables using SGE formatting
	echo -e $KNOWNVARS >> $FILE_SUBSCRIPT

	# Add the job script
	cat $NODE >> $FILE_SUBSCRIPT

	# Submit to SGE
	JOBID=`qsub $FILE_SUBSCRIPT`

	# Fix the JobID
	JOBID=`echo $JOBID | cut -d\  -f3 | cut -d. -f1`
}
