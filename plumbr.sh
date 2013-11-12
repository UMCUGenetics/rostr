# Decide on what parts of the pipeline require other parts
for NODENAME in ${PIPELINE[@]}
do {
	NODE=./nodes/$NODENAME.sh
	REQS=(`grep '#RS requires' $NODE | cut -d\  -f3-`)
	PROS=(`grep '#RS provides' $NODE | cut -d\  -f3-`)
	# Determine what this node provides
	for PRO in ${PROS[@]}
	do
		#echo Provides $PRO
		if [ `arrayGet PROVIDES $PRO` ]
		then
			echo COLLISION: $PRO by $NODENAME is already provided by `arrayGet PROVIDES $PRO`
			exit
		fi
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

# Brackets to ignore this block of useless code...
if false; then
# Look through the pipe and see what it is connected to ignoring additional settings
traceReqEnd(){
	local TRACES=`arrayGet REQUIRES $1`
	for TRACE in ${TRACES[@]}
	do
		NONENDNODES+=(`arrayGet PROVIDES $TRACE`)
		traceReq `arrayGet PROVIDES $TRACE`
	done
}

# Determine end nodes
if [ "$WANTEDOUT" == "" ]
then {
	echo 'No targeted output specified, testing for end nodes'
	
	# Test for output necessities
	NONENDNODES=()
	for PIPE in ${PIPELINE[@]}
	do
		echo 'Testing' $PIPE needing `arrayGet REQUIRES $PIPE`
		traceReqEnd $PIPE
	done
	#echo ${NONENDNODES[@]}
	
	# Extract end nodes
	ENDNODES=()
	for PIPE in ${PIPELINE[@]}
	do
		ENDNODE=1
		for PLUN in ${NONENDNODES[@]}
		do
			if [ "$PIPE" == "$PLUN" ]
			then
				ENDNODE=0
				break
			fi
		done
		if [ $ENDNODE -eq 1 ]
		then
			echo $PIPE
			ENDNODES+=($PIPE)
		fi
	done
	echo ${ENDNODES[@]}
	# Now we have the end nodes which is worthless as we would like its
	# outputs for the code below... rewrite for forward tracing after
	# adding edges in the other direction perhaps
} fi

fi

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
