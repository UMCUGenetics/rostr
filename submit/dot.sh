FILE_GRAPH=$DIR_OUTPUT/graph.txt

preSubmit() {
	# Setup graph txt file
	echo 'digraph {' > $FILE_GRAPH

	# Make clusters to group nodes over all samples
	for NODENAME in ${PIPELINE[@]}
	do
		# Looks like I cannot get this info from an array at this point
		THIS_NODE=$( readlink -f $DIR_NODES/$NODENAME.sh )
		THIS_TYPE=(`grep '^#RS widenode' $THIS_NODE | cut -d\  -f2-`)

		# No cluster for the widenode
		if [ "$THIS_TYPE" != 'widenode' ]
		then
			echo "subgraph cluster_${NODENAME}{" >> $FILE_GRAPH
			echo -e "style=filled;\ncolor=lightgrey;\nnode [style=filled,color=white]" >> $FILE_GRAPH
			echo "label = \"${NODENAME}\"" >> $FILE_GRAPH

			# Generate and add the same names as JOB_NAME and thus JOBID will become later
			for SAMPLE in ${SAMPLES[@]}
			do
				echo RoStr_${SAMPLE}_${NODENAME} >> $FILE_GRAPH
			done
			echo '}' >> $FILE_GRAPH
		fi
	done
}

submit() {
	# Get nodes this node is dependent on
	HOLDFOR=`getHoldIds`
	IFS=';' read -r -a HOLDARR <<< "$HOLDFOR"

	# Label is SSAMPLE if normal node...
	NODE_LABEL=${SAMPLE}
	if [ "$TYPE" = 'widenode' ]
	then
		# ... and NODENAME if widenode
		NODE_LABEL=${NODENAME}
		#echo "${JOB_NAME} [style=filled]" >> $FILE_GRAPH
	fi

	# KNOWNVARS=""
	# MISSINGVARS=""
	# USEDVARIABLES=(`grep -o '\$[a-zA-Z0-9_]*' $NODE | sort | uniq`)
	# for USEDVAR in ${USEDVARIABLES[@]}
	# do
	# 	VARNAME=`echo $USEDVAR | cut -b 1 --complement`
	# 	VARVAL=`eval echo $USEDVAR`
	# 	if [ ! "$VARVAL" = "" ]
	# 	then
	# 		KNOWNVARS="$KNOWNVARS\n$VARNAME=$VARVAL"
	# 	else
	# 		MISSINGVARS="$MISSINGVARS\n$VARNAME"
	# 	fi
	# done

	# Stuff label into the graph text file
	# echo "${JOB_NAME} [label=\"$NODE_LABEL\n\nSet Variables:$KNOWNVARS\n\nUnset Variables:$MISSINGVARS\"]" >> $FILE_GRAPH
	echo "${JOB_NAME} [label=\"$NODE_LABEL\"]" >> $FILE_GRAPH
	
	#echo "${JOB_NAME}[label=\"Job: ${NODENAME}\nSample: ${SAMPLE//wide/all}\"]" >> $FILE_GRAPH

	# Add connections between previous nodes and this node
	for HOLD in ${HOLDARR[@]}
	do
		echo "$HOLD -> $JOB_NAME" >> $FILE_GRAPH
	done

	# Set to add the node name to the system
	JOBID=$JOB_NAME
}

postSubmit() {
	# Finish the file
	echo '}' >> $FILE_GRAPH

	# Turn graph txt file into a pdf
	dot $FILE_GRAPH -Tpdf > ${FILE_GRAPH//.txt/.pdf}
}
