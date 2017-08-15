#!/bin/bash
set -e

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
#export -f getNodeThreads

# Determine script location and working location
DIR_BASE=$(dirname $0) # Dir script resides in
DIR_BASE=$(readlink -f $DIR_BASE) # Obtain the full path, otherwise nodes go crazy
DIR_CUR=${PWD} # Dir script is called from
export FILE_SAMPLES=$(realpath $1)
export DIR_OUTPUT=$(realpath $2)

# Load basic config files
source $DIR_BASE/propr.sh
# Load main config file
#FILE_CONFIG=$3
#source $FILE_CONFIG
STAMP=`date +%s`

# Load additional config files and set variables
ROSTRLOG=~/config-$STAMP

export ROSTR_VERSION=$(git --git-dir $DIR_BASE/.git describe --tag --always)
echo $ROSTR_VERSION
echo '# RoStr '$ROSTR_VERSION >> $ROSTRLOG
echo '# Run date: '$(date +"%d/%m/%y")' '$(date +"%T") >> $ROSTRLOG
echo '' >> $ROSTRLOG
echo \#"${@}" >> $ROSTRLOG
#mv $ROSTRLOG $ROSTRLOG.old
for ADDITIONAL_ARG in "${@:3:$#}"
do {
	if [[ -f $ADDITIONAL_ARG ]]
	then
		echo Loading: $ADDITIONAL_ARG
		source $ADDITIONAL_ARG
		echo -e "\n\n\n### Loading: --git-dir $ADDITIONAL_ARG/.git ###" >> $ROSTRLOG

		set +e
			git --git-dir `pwd $ADDITIONAL_ARG` describe --tag --always >> $ROSTRLOG
		set -e

		cat "$ADDITIONAL_ARG">>$ROSTRLOG
	else
		echo Declaring: $ADDITIONAL_ARG
		declare $ADDITIONAL_ARG
		echo -e "\n\n\n### Declaring: $ADDITIONAL_ARG ###" >> $ROSTRLOG
		echo "$ADDITIONAL_ARG">>$ROSTRLOG
	fi
} done

# Assume nodes are next to main config file if not specified otherwise
if [[ -z "$DIR_NODES" ]]
then
	DIR_NODES=$(readlink -f $(dirname $3))
fi

# On to preparing for the run
source $DIR_BASE/submit/$SCHEDULER.sh
WIDENODES=()

# Determine sample files and names
#loadSamples $FILE_SAMPLES
# Cannot declare in function and use outside, source to fake call a function
source $DIR_BASE/samplr.sh
echo "Using samples:" ${SAMPLES[@]}

# Bash can't export arrays, just export another variable with the array info
export SAMPLELIST=${SAMPLES[@]}

# Let's fix the folders
mkdir -p $DIR_OUTPUT/wide/log
for SAMPLE in ${SAMPLES[@]}
do
	mkdir -p $DIR_OUTPUT/$SAMPLE/log
done
mv $ROSTRLOG $DIR_OUTPUT

# Call the plumber to check for defects and shortcuts in our pipeline
source $DIR_BASE/plumbr.sh

# Prepare scheduler
preSubmit

# Variables for used for saving submission scripts
NODECOUNT=0
SUBMITCOUNT=0

# Track and enable cancelling of a run
FILE_JOBLIST=$DIR_OUTPUT/jobids-$STAMP

# Simplification for RoStr submits
submitNode() {
	printf -v SUBMITCOUNT "%03d" `echo $SUBMITCOUNT+1 | bc`
	export SAMPLE=$SAMPLE
	export FILE_INPUT=`arrayGet INPUT $SAMPLE`
	export FILE_OUTPUT=$DIR_OUTPUT/$SAMPLE/$SAMPLE
	export DIR_LOG=$DIR_OUTPUT/$SAMPLE/log
	export FILE_LOG_ERR=$DIR_LOG/${NODENAME}.e${STAMP}
	export FILE_LOG_OUT=$DIR_LOG/${NODENAME}.o${STAMP}
	export JOB_NAME=RoStr_${SAMPLE}_${NODENAME}
	export SUBARGS=$ARG_SUBBASE
	export ARG_JOB_CPU=$(getNodeThreads)

	if needsRun;
	then
		echo "+ $SAMPLE"
		submit
		export declare "JOBIDS_${SAMPLE}_${NODENAME}=${JOBID}"
		echo ${JOBID} >> $FILE_JOBLIST
	else
		echo "- $SAMPLE"
	fi
}

# Work your way through the pipeline that is left
for NODENAME in ${PIPELINE[@]}
do
	printf -v NODECOUNT "%02d" `echo $NODECOUNT+1 | bc`
	echo -e "\nNode: $NODENAME"
	export NODE=$( readlink -f $DIR_NODES/$NODENAME.sh )
	export REQS=(`grep '^#RS requires' $NODE | cut -d\  -f3-`)
	export PROS=(`grep '^#RS provides' $NODE | cut -d\  -f3-`)
	export ARGS=(`arrayGet ARGUMENTS $NODENAME`)
	export ADDS=(`grep '^#RS addition' $NODE | cut -d\  -f3-`)
	export TYPE=(`grep '^#RS widenode' $NODE | cut -d\  -f2-`)

	# Node is run specific: wide over (all) samples
	if [ "$TYPE" = 'widenode' ]
	then {
		SAMPLE=wide
		submitNode
	}
	# Node is sample specific: single sample
	else {
		for SAMPLE in ${SAMPLES[@]}
		do
			submitNode
		done
	} fi
done

# Finish scheduler
postSubmit
