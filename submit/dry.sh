# Dry run for dependency checks
preSubmit() {
	MISSINGVARS=""
	KNOWNVARS=""
}

submit() {
	echo "> > Runs:" $NODE

	for ARG in ${ARGS[@]}
	do
    	echo $ARG
	done

	USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*' $NODE | sort | uniq`)
	for USEDVAR in ${USEDVARIABLES[@]}
	do
		VARNAME=`echo $USEDVAR | cut -b 1 --complement`
		VARVAL=`eval echo $USEDVAR`
		if [ ! "$VARVAL" = "" ]
		then
			KNOWNVARS="$KNOWNVARS $NODENAME:$VARNAME=$VARVAL"
		else
			MISSINGVARS="$MISSINGVARS $NODENAME:$VARNAME"
		fi
	done

	JOBID="N/A: Dry run"
}

postSubmit () {
	echo ""
	echo "Variables that were set:"
	echo $KNOWNVARS | tr -s [:space:] \\n | sort | uniq
	echo ""
	echo "Variables that were not set:"
	echo $MISSINGVARS | tr -s [:space:] \\n | sort | uniq
}
