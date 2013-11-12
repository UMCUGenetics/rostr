jdlPreSubmitText() {
	echo "[" 
    echo " Type=\"dag\";"
    #InputSandbox={"mother.py"};
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
	echo "    InputSandbox = {$HOLDFOR};"
	echo "    StdOutput = \"$FILE_LOG_ERR\";"
	echo "    StdError = \"$FILE_LOG_OUT\";"
	echo "    OutputSandbox = {$RETURNFILES \"$FILE_LOG_OUT\" \"$FILE_LOG_ERR\" };"
	echo "    ShallowRetryCount = 1;"
	echo "   ];"
	echo "  ];"
}

jdlPostSubmitText(){
    echo " ];"
    echo " Dependencies = $DEPENDENCIES;"
	echo "]"
}

preSubmit() {
	FILE_JDLSPEC=$DIR_OUTPUT/jdlspec
	jdlPreSubmitText > $FILE_JDLSPEC
}
	
submit() {
	HOLDFOR=""
	if [ ${#REQS[@]} -ne "0" ]
	then
		#echo $REQS
		# TODO: Fix missing insertion of , down here
		HOLDFOR=`printf \"$FILE_OUTPUT.'%s\"\n' "${REQS[@]}"|paste -sd','`
		HOLDFOR="$HOLDFOR, \"$NODE\""
	fi

	RETURNFILES=""
	if [ ${#PROS[@]} -ne "0" ]
	then
		#echo $REQS
		RETURNFILES=""
		RETURNFILES=`printf \"$FILE_OUTPUT.'%s\"\n' "${PROS[@]}"|paste -sd','`
	fi

	jdlSubmitText >> $FILE_JDLSPEC
	JOBID=$JOB_NAME
}

postSubmit() {
	DEPENDENCIES="{"
	for PIPE in ${PIPELINE[@]}
	do
		PIPEREQS=`arrayGet REQUIRES $PIPE`
		if [ ${#PIPEREQS[@]} -ne "0" ]
		then
			for PIPEREQ in ${PIPEREQS[@]}
			do
				DEPENDENCY=`arrayGet PROVIDES $PIPEREQ`
				DEPENDENCIES="$DEPENDENCIES {$DEPENDENCY, $PIPE}"
			done
		fi
	done
	DEPENDENCIES="$DEPENDENCIES }"
	jdlPostSubmitText >> $FILE_JDLSPEC
}
