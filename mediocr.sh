# Worthless snippets of code that may come in handy some day

# From plumbr.sh:
# Look through the pipe and see what it is connected to, ignoring additional settings
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
}
