set -e

# Hack to get around the hashmap versus dot fight in bash
replaceDots() {
	INSTRING=$1
	echo ${INSTRING//\./___DOT___}
}

# Get value from map by key:
arrayGet() { 
	local ARRAY=$1 INDEX=$2
	INDEX=`replaceDots $INDEX` # Hacky-hacky-hacky-hoo
	local i="${ARRAY}_$INDEX"
	printf '%s' "${!i}"
}

# Determine script location and working location
DIR_BASE=$(dirname $0) # Dir script resides in
DIR_BASE=$(readlink -f $DIR_BASE) # Obtain the full path, otherwise nodes go crazy
DIR_CUR=${PWD} # Dir script is called from

# Load main config file
FILE_CONFIG=$3
source $DIR_BASE/propr.sh
source $FILE_CONFIG

# Load additional config files and set variables
for ADDITIONAL_ARG in "${@:3:$#}"
do {
	if [[ -f $ADDITIONAL_ARG ]]
	then
		echo Loading: $ADDITIONAL_ARG
		source $ADDITIONAL_ARG
	else
		echo Declaring: $ADDITIONAL_ARG "(untested)"
		declare $ADDITIONAL_ARG
	fi
} done

# On to preparing for the run
source $DIR_BASE/submit/$SCHEDULER.sh
STAMP=`date +%s`
WIDENODES=()

# Find our samples and extract their names
SAMPLEPATHS=`find $1 -name $INPUTEXT`
SAMPLES=()
for SAMPLEPATH in ${SAMPLEPATHS[@]}
do {
	SAMPLE=`getSampleName $SAMPLEPATH`
	SAMPLES+=($SAMPLE)
	SAMPLEFULLPATH=$( readlink -f $SAMPLEPATH )
	declare "INPUT_${SAMPLE}=${SAMPLEFULLPATH}"
} done
echo "Using samples:" ${SAMPLES[@]}

# Let's fix the folders
DIR_OUTPUT=$2
set +e
mkdir $DIR_OUTPUT
mkdir $DIR_OUTPUT/log
mkdir $DIR_OUTPUT/runwide
mkdir $DIR_OUTPUT/runwide/log
for SAMPLE in ${SAMPLES[@]}
do
	mkdir $DIR_OUTPUT/$SAMPLE
	mkdir $DIR_OUTPUT/$SAMPLE/log
done
export DIR_OUTPUT=$(readlink -f $DIR_OUTPUT)
set -e

# Call the plumber to check for defects and shortcuts in our pipeline
source plumbr.sh

# Prepare scheduler
preSubmit

# Work your way through the pipeline that is left
for NODENAME in ${PIPELINE[@]}
do
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
			#echo Full width detected: ${SAMPLES[@]}
			export SAMPLE=WIDE
			export FILE_INPUT=`arrayGet INPUT ${SAMPLE}`
			export FILE_OUTPUT=$DIR_OUTPUT/runwide/runwide
			export DIR_LOG=$DIR_OUTPUT/runwide/log
			export FILE_LOG_ERR=$DIR_LOG/${NODENAME}.e${STAMP}
			export FILE_LOG_OUT=$DIR_LOG/${NODENAME}.o${STAMP}
			export JOB_NAME=RoStr_${SAMPLE}_${NODENAME}
			echo "+ Wide"
			submit
			JOBID=$RANDOM
			declare "JOBIDS_${SAMPLE}_${NODENAME}=${JOBID}"
	}
	# Node is sample specific: single sample
	else {
		for SAMPLE in ${SAMPLES[@]}
		do
			export SAMPLE=$SAMPLE
			export FILE_INPUT=`arrayGet INPUT $SAMPLE`
			export FILE_OUTPUT=$DIR_OUTPUT/$SAMPLE/$SAMPLE
			export DIR_LOG=$DIR_OUTPUT/$SAMPLE/log
			export FILE_LOG_ERR=$DIR_LOG/${NODENAME}.e${STAMP}
			export FILE_LOG_OUT=$DIR_LOG/${NODENAME}.o${STAMP}
			export JOB_NAME=RoStr_${SAMPLE}_${NODENAME}
			export SUBARGS=""
			if needsRun;
			then
				echo "+ $SAMPLE"
				submit
				declare "JOBIDS_${SAMPLE}_${NODENAME}=${JOBID}"
			else
				echo "- $SAMPLE"
			fi
		done
	} fi
done

# Finish scheduler
postSubmit
