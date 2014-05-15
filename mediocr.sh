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

# Temporary removed first try implementation of partial wide node stuff
# Configured to be partial
		PARTIALS=`arrayGet PARTIAL $NODENAME`
		if [ ! "" = "$PARTIALS" ]
		then
			echo Partial wide detected: $PARTIALS
			PARTIALS=($PARTIALS) # Array pl0x
			for PART in ${PARTIALS[@]}
			do
				LBLUSE=`echo $PART | cut -d\; -f1`
				LBLALI=`echo $PART | cut -d\; -f2`
				
				#echo "From column/alias: "$LBLCOL", take labels: "$LBLUSE", and write to: "$LBLALI
				LBLUSEARR=$(echo $LBLUSE | tr "," "\n")
				for LBLUSEELE in $LBLUSEARR
				do
					LBLTMP=`echo $LBLUSEELE | cut -d\= -f1`
					LBLLBL=`echo $LBLUSEELE | cut -d\= -f2`
					LBLFIL=`echo $LBLTMP | cut -d\: -f1`
					LBLCOL=`echo $LBLTMP | cut -d\: -f2`
					
					# TODO: Swap ALIAS check below with this right underneath
					if [ `arrayGet LABELS_ALIAS $LBLLBL` ]
					then
						echo found job as: `arrayGet LABELS_ALIAS $LBLLBL`
					else
						if [ $LBLTMP = "ALIAS" ]
						then
							echo MISSING: partial dependency $LBLUSEELE "(" $PART ")" is not known in ALIAS
							exit
						fi
						echo Lookup for $LBLUSEELE in file returns:
						awk -v col=$LBLCOL -v lbl=$LBLLBL '$col == lbl { print $1 }' $LBLFIL
					fi
				done
				JOBID=$RANDOM
				echo declaring key LABELS_ALIAS_${LBLALI} as value $JOBID #JOBIDHERE_FOR_${LBLUSE}
				declare "LABELS_ALIAS_${LBLALI}=$JOBID"#JOBIDHERE_FOR_${LBLUSE}
				#declare "${LBLALI}_JOBIDS_${NODENAME}=${JOBID}"
			done
			
		# Unspecified, take all
		else
			# Full wide code here
		fi
