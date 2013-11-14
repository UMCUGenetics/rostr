# Dry run for dependency checks
preSubmit() {
	MISSINGVARS=""
	KNOWNVARS=""
}

submit() {
	echo "> > Runs:" $NODE
	USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*' $NODE | sort | uniq`)
	for USEDVAR in ${USEDVARIABLES[@]}
	do
		VARNAME=`echo $USEDVAR | cut -b 1 --complement`
		VARVAL=`eval echo $USEDVAR`
		if [ ! $VARVAL = "" ]
		then
			#echo $VARNAME=$VARVAL
			KNOWNVARS="$KNOWNVARS $NODENAME:$VARNAME=$VARVAL"
		else
			MISSINGVARS="$MISSINGVARS $NODENAME:$VARNAME"
			#echo $VARNAME is unset!
		fi
	done

	JOBID="N/A: Dry run"
}

postSubmit () {
	echo "Arguments that were set:"
	echo $KNOWNVARS | tr -s [:space:] \\n | sort | uniq
	echo "Arguments that were not set:"
	echo $MISSINGVARS | tr -s [:space:] \\n | sort | uniq
}
