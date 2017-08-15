FILE_CAT=$DIR_OUTPUT/cat.sh
DIR_CAT=$DIR_OUTPUT/cat

preSubmit() {
	# Ensure it's empty by removing any existing file
	#rm -f $FILE_CAT
	echo -e "### Concatenated export for: ###\n## ${PIPELINE// /\n## }" > $FILE_CAT
	mkdir -p $DIR_CAT
}

submit() {
	# Set to add the node name to the system
	JOBID="$NODENAME:$SAMPLE"

	echo -e "\n\n\n### New job definition ###" >> $FILE_CAT
	echo -e "# Node name: $NODENAME" >> $FILE_CAT
	echo -e "# Node file: $NODE" >> $FILE_CAT
	echo -e "# Sample name: $SAMPLE" >> $FILE_CAT
	echo -e "# Job ID: $JOBID" >> $FILE_CAT
	echo -e "# Submission args: ${ARGS[@]}" >> $FILE_CAT

	# Get nodes this node is dependent on
	HOLDFOR=`getHoldIds`
	echo -e "# Waits for: ${HOLDFOR//;/\n## }" >> $FILE_CAT

	KNOWNVARS=""
	MISSINGVARS=""
	USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*\|\${[a-zA-Z0-9_]*' $NODE | sed -e 's/${/$/g' | sort | uniq`)
	for USEDVAR in ${USEDVARIABLES[@]}
	do
		VARNAME=`echo $USEDVAR | cut -b 1 --complement`
		VARVAL=`eval echo $USEDVAR`
		if [ ! "$VARVAL" = "" ]
		then
			KNOWNVARS="${KNOWNVARS}${VARNAME}=${VARVAL}\n"
		else
			MISSINGVARS="${MISSINGVARS}## ${VARNAME}\n"
		fi
	done

	echo -e "\n\n# Variables unknown at submission time:" >> $FILE_CAT
	echo -e "$MISSINGVARS" >> $FILE_CAT

	echo -e "\n# Variables known at submission time:" >> $FILE_CAT
	echo -e $KNOWNVARS >> $FILE_CAT

	echo -e "\n# Actual job:" >> $FILE_CAT
	cat $NODE >> $FILE_CAT
}

postSubmit() {
	echo -e "\n\n\n### Concatenated export finished ###" >> $FILE_CAT
}
