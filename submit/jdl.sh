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
	echo "    Arguments = \"$NODE\";"
	echo "    InputSandbox = {$INPUTREQS};"
	echo "    StdOutput = \"$FILE_LOG_ERR\";"
	echo "    StdError = \"$FILE_LOG_OUT\";"
	echo "    OutputSandbox = {$RETURNFILES, \"$FILE_LOG_OUT\", \"$FILE_LOG_ERR\" };"
	echo "    ShallowRetryCount = 1;"
	echo "   ];"
	echo "  ];"
}

jdlPostSubmitText(){
    echo " ];"
    echo " Dependencies = {$DEPENDENCIES};"
	echo "]"
}

preSubmit() {
	DEPENDENCIES=""
	FILE_JDLSPEC=$DIR_OUTPUT/dag.jdl
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
			
	jdlSubmitText >> $FILE_JDLSPEC
	JOBID=$JOB_NAME
}

postSubmit() {
	# Fix the curly brackets and commas that mess up otherwise
	DEPENDENCIES=${DEPENDENCIES//\}\{/\}\, \{}
	jdlPostSubmitText >> $FILE_JDLSPEC
}
