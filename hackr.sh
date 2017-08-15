# Hack to get around the hashmap versus dot fight in bash
replaceDots() {
	INSTRING=$1
	INSTRING=${INSTRING//\./___DOT___}
	#echo ${INSTRING//\-/___HYPHEN___}
	echo ${INSTRING//\-/_}
}

# Get value from map by key:
arrayGet() { 
	local ARRAY=$1 INDEX=$2
	INDEX=`replaceDots $INDEX` # Hacky-hacky-hacky-hoo
    local i="${ARRAY}_$INDEX"
    subst="$i[@]"
    echo "${!subst}"
	#printf '%s' "${!i}"
}

# Check if element is in array
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Experimental: CPU count per job with only one mention
getNodeThreads() {
	for ARG in ${ARGS[@]}
	do
		ANAME=`echo $ARG | cut -d ':' -f1`
		AVAL=`echo $ARG | cut -d ':' -f2`
		if [ $ANAME = "cpu" ]
		then
			echo $(($AVAL<$ARG_JOB_CPU_MAX?$AVAL:$ARG_JOB_CPU_MAX))
			return 0
		fi
	done
	echo "1"
	return 0
}

# # Sample finder/loader (old, to be replaced)
# findSamples(){
# 	SAMPLEPATHS=`find $1 -name $TEXT_INPUT`
# 	SAMPLES=()
# 	#export FILE_SAMPLES=()
# 	for SAMPLEPATH in ${SAMPLEPATHS[@]}
# 	do {
# 		SAMPLE=`getSampleName $SAMPLEPATH`
# 		SAMPLE=`replaceDots $SAMPLE`
# 		if containsElement $SAMPLE "${SAMPLES[@]}"
# 		then
# 			echo $SAMPLE multiple files found
# 		else
# 			SAMPLES+=($SAMPLE)
# 		fi
# 		SAMPLEFULLPATH=$( readlink -f $SAMPLEPATH )
# 		#FILE_SAMPLES+=($SAMPLEFULLPATH)
# 		declare -g "INPUT_${SAMPLE}=${SAMPLEFULLPATH} `arrayGet INPUT $SAMPLE`"
# 	} done
# }

# loadSamples(){
# 	while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
# 		SAMPLEPATH=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $2}'`
# 		SAMPLE=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $1}'`
# 		SAMPLE=`replaceDots $SAMPLE`

# 		# Are samples specified multiple times?
# 		if containsElement $SAMPLE "${SAMPLES[@]}"
# 		then
# 			echo "$SAMPLE defined multiple times"
# 			exit
# 		else
# 			SAMPLES+=($SAMPLE)
# 		fi

# 		# Better safe than sorry, ensure the path is real
# 		SAMPLEFULLPATH=$( realpath $SAMPLEPATH )
# 		# Perhaps cd to file dir to enable using relative paths?

# 		# Did the user define the right path anyway?
# 		if [[ ! -f $SAMPLEFULLPATH ]]
# 		then
# 			echo "File for $SAMPLE could not be found here: $SAMPLEPATH"
# 			exit
# 		fi

# 		# The -g functionality may  have limited support, maybe move this to another script and source instead
# 		declare -g "INPUT_${SAMPLE}=${SAMPLEFULLPATH} `arrayGet INPUT $SAMPLE`"
# 		#echo "$SAMPLE at $SAMPLEPATH"
# 	done < "$1"
# }

# A function I need over different submission scripts but I have no idea where to put atm
# Implementation of partial wide should (partly) happen here as well
getHoldIds() {
	local HOLDFOR=""
	if [ ${#REQS} -ne "0" ]
	then
		for REQ in ${REQS[@]}
		do
			REQNODE=`arrayGet PROVIDES $REQ`
			# If REQNODE is wide, add this widenode to hold list
			if [ `arrayGet WIDENODES ${REQNODE}` ]
			then
				#HOLDFOR+=(`arrayGet JOBIDS_WIDE ${REQNODE}`)
				HOLDID=`arrayGet JOBIDS_wide ${REQNODE}`
				HOLDFOR="$HOLDFOR;$HOLDID"
			# If REQNODE is not wide
			else
				# Test if we are wide ourselves and add all preceding sample jobs if so
				if [ `arrayGet WIDENODES ${NODENAME}` ]
				then
					for DEPSAMPLE in ${SAMPLES[@]}
					do
						#HOLDFOR+=(`arrayGet JOBIDS_${DEPSAMPLE} ${REQNODE}`)
						HOLDID=`arrayGet JOBIDS_${DEPSAMPLE} ${REQNODE}`
						HOLDFOR="$HOLDFOR;$HOLDID"
					done
				# And if we are not, just add one sample dependency
				else
					HOLDFOR+=(`arrayGet JOBIDS_${SAMPLE} ${REQNODE}`)
					HOLDID=`arrayGet JOBIDS_${SAMPLE} ${REQNODE}`
					HOLDFOR="$HOLDFOR;$HOLDID"
				fi
			fi
		done
	fi

	echo $HOLDFOR
}