pre(){}

HOLDFOR=""
if [ ${#REQS[@]} -ne "0" ]
then
	#echo $REQS
	# TODO: Fix missing insertion of , down here
	HOLDFOR=`printf '%s\n' "${REQS[@]}"|paste -sd','`
	HOLDFOR="$HOLDFOR, $NODE"
fi

RETURNFILES=""
if [ ${#PROS[@]} -ne "0" ]
then
	#echo $REQS
	RETURNFILES=""
	RETURNFILES=`printf '%s\n' "${PROS[@]}"|paste -sd','`
fi

# Create the job description in JDL format
echo "$JOB_NAME = ["
echo " description = ["
echo "  JobType = \"Normal\";"
echo "  Executable = \"/usr/bin/bash\";"
echo "  Arguments = \"$NODE\";"
echo "  InputSandbox = {$HOLDFOR};"
echo "  StdOutput = \"$FILE_LOG_ERR\";"
echo "  StdError = \"$FILE_LOG_OUT\";"
echo "  OutputSandbox = {$RETURNFILES};"
echo "  ShallowRetryCount = 1;"
echo " ];"
echo "];"
JOBID=$JOB_NAME
