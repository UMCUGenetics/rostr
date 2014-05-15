# Decide on what parts of the pipeline require other parts
for NODENAME in ${PIPELINE[@]}
do {
	NODE=$DIR_NODES/$NODENAME.sh
	REQS=(`grep '#RS requires' $NODE | cut -d\  -f3-`)
	PROS=(`grep '#RS provides' $NODE | cut -d\  -f3-`)
	TYPE=(`grep '#RS widenode' $NODE | cut -d\  -f2-`)
	
	if [ "$TYPE" = 'widenode' ]
	then
		WIDENODES+=($NODENAME)
		declare "WIDENODES_${NODENAME}=1" 
	fi
	#echo ${WIDENODES[@]}
	
	# Determine what this node provides
	for PRO in ${PROS[@]}
	do
		if [ `arrayGet PROVIDES $PRO` ]
		then
			echo COLLISION: $PRO by $NODENAME is already provided by `arrayGet PROVIDES $PRO`
			exit
		fi
		# Get rid of dots for variable declaration
		PRO=`replaceDots $PRO`
		# Remember the provided output
		declare "PROVIDES_${PRO}=${NODENAME}"
	done
	
	# Determine what nodes provide the requirements
	for REQ in ${REQS[@]}
	do
		if [ ! `arrayGet PROVIDES $REQ` ]
		then
			echo MISSING: requirement $REQ by $NODENAME is UNKNOWN
			exit
		fi
		# Remember the stated requirement
		declare "REQUIRES_${NODENAME}=${REQ} `arrayGet REQUIRES $NODENAME`"
	done
} done

# Look through the pipe and see what it is connected to
traceReq(){
	local TRACES=`arrayGet REQUIRES $1`
	for TRACE in ${TRACES[@]}
	do
		IGNORETRACE=0
		# If provided by conf (i.e. prev broken run) don't bother
		for INNAME in ${WANTEDIN[@]}
		do
			if [ "$TRACE" == "$INNAME" ]
			then
				IGNORETRACE=1
				break
			fi
		done
		# Not provided, trace the pipe
		if [ $IGNORETRACE -eq 0 ]
		then
			PLUNGED+=(`arrayGet PROVIDES $TRACE`)
			traceReq `arrayGet PROVIDES $TRACE`
		fi
	done
}

# Check for wanted outputs and only keep required nodes to reach our goals
if [ ! "$WANTEDOUT" == "" ]
then {
	PLUNGED=()
	for OUTNAME in ${WANTEDOUT[@]}
	do
		NODENAME=`arrayGet PROVIDES $OUTNAME`
		PLUNGED+=($NODENAME)
		traceReq $NODENAME
	done

	# Create a shorter pipeline if possible
	REDUCEDPIPE=()
	for PIPE in ${PIPELINE[@]}
	do
		for PLUN in ${PLUNGED[@]}
		do
			if [ "$PIPE" == "$PLUN" ]
			then
				REDUCEDPIPE+=($PIPE)
				break
			fi
		done
	done

	# Take the shortcut
	echo Plunging the pipeline resulted in: ${REDUCEDPIPE[@]}
	PIPELINE=() # Empty it first, simply overwriting goes wrong
	PIPELINE=${REDUCEDPIPE[@]}
} fi
