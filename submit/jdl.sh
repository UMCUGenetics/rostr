jdlPreSubmitText() {
	echo "[" 
    echo " Type=\"dag\";"
    #InputSandbox={""};
    echo " VirtualOrganization=\"alzseq400\";"
    #Requirements=other.GlueCEStateStatus=="Production";
    #Rank=other.GlueCEStateFreeCPUs;
    echo " Nodes = ["
}

# Create the job description in JDL format
jdlSubmitText() {
	echo "  $JOB_NAME = ["
	echo "   description = ["
	echo "    JobType = \"Normal\";"
	echo "    Executable = \"/usr/bin/bash\";"
	echo "    Arguments = \"$FILE_JDLJOB\";"
	echo "    InputSandbox = {$INPUTREQS};"
	echo "    StdOutput = \"$FILE_LOG_ERR\";"
	echo "    StdError = \"$FILE_LOG_OUT\";"
	echo "    OutputSandbox = {$RETURNFILES, \"$FILE_LOG_OUT\", \"$FILE_LOG_ERR\" };"
	echo "    ShallowRetryCount = 1;"
	echo "   ];"
	echo "  ];"
}

jdlPostSubmitText() {
    echo " ];"
    echo " Dependencies = {$DEPENDENCIES};"
	echo "];"
}

jdlCreateJobFile() {
	# Create a job file containing all set variables
	FILE_JDLJOB=$DIR_OUTPUT/jdlsubmission/$JOB_NAME.sh
	echo "# Set all variables for this script first" > $FILE_JDLJOB
	USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*' $NODE | sort | uniq`)
	for USEDVAR in ${USEDVARIABLES[@]}
	do
		VARNAME=`echo $USEDVAR | cut -b 1 --complement`
		VARVAL=`eval echo $USEDVAR`
		if [ ! $VARVAL = "" ]
		then
			echo "$VARNAME=$VARVAL" >> $FILE_JDLJOB
			#continue
		else
			#MISSINGVARS="$MISSINGVARS $NODENAME:$VARNAME"
			echo $VARNAME is unset!
		fi
	done
	echo -e "" >> $FILE_JDLJOB
	echo "# Copy of the job itself" >> $FILE_JDLJOB
	cat $NODE >> $FILE_JDLJOB
}

preSubmit() {
	DEPENDENCIES=""
	set +e
	mkdir $DIR_OUTPUT/jdlsubmission
	set -e
	FILE_JDLSPEC=$DIR_OUTPUT/jdlsubmission/rostr.jdl
	jdlPreSubmitText > $FILE_JDLSPEC
}

submit() {
	INPUTREQS=""
	if [ ${#REQS[@]} -ne "0" ]
	then
		INPUTREQS=`printf \"$FILE_OUTPUT.'%s\"\n' "${REQS[@]}"|paste -sd','`
		INPUTREQS="$INPUTREQS, \"$NODE\""
		
		for REQ in ${REQS[@]}
		do
			DEPENDENCY=`arrayGet PROVIDES $REQ`
			DEPENDENCIES="$DEPENDENCIES{RoStr_${SAMPLE}_${DEPENDENCY}, $JOB_NAME}"
		done
	fi

	RETURNFILES=""
	if [ ${#PROS[@]} -ne "0" ]
	then
		RETURNFILES=""
		RETURNFILES=`printf \"$FILE_OUTPUT.'%s\"\n' "${PROS[@]}"|paste -sd','`
	fi
	
	jdlCreateJobFile	
	jdlSubmitText >> $FILE_JDLSPEC
	JOBID=$JOB_NAME
}

postSubmit() {
	# Fix the curly brackets and commas that mess up otherwise
	DEPENDENCIES=${DEPENDENCIES//\}\{/\}\, \{}
	jdlPostSubmitText >> $FILE_JDLSPEC
}
