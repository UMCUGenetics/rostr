#!/bin/bash
set -e

# Hack to get around the hashmap versus dot fight in bash
replaceDots() {
	INSTRING=$1
	INSTRING=${INSTRING//\./___DOT___}
	echo ${INSTRING//\-/___HYPHEN___}
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

# Load basic config files
source $DIR_BASE/propr.sh
# Load main config file
#FILE_CONFIG=$3
#source $FILE_CONFIG
STAMP=`date +%s`

# Load additional config files and set variables
ROSTRLOG=~/rostr.$STAMP.conf

LOG_REV=$(git --git-dir $DIR_BASE/pipelines/.git/ log --oneline | head -n 1 | tr -s ' ' | cut -d ' ' -f 1 )
LOG_VERTMP=`grep -Po "No tags" <<< $(git $DIR_BASE/pipelines/.git/ describe --tags 2>&1)`
if [ -z "$LOG_VERTMP" ]; then
	LOG_VER=$(git --git-dir $DIR_BASE/pipelines/.git/ describe --tags)
else
	LOG_VER="devel"
fi
echo '# RoDa '$LOG_VER'-'$LOG_REV >> $ROSTRLOG
export RODA_VERSION=$LOG_VER'-'$LOG_REV

LOG_RREV=$(git log --oneline | head -n 1 | tr -s ' ' | cut -d ' ' -f 1 )
LOG_RVERTMP=`grep -Po "No tags" <<< $(git describe --tags 2>&1)`
if [ -z "$LOG_VERTMP" ]; then
	LOG_RVER=$(git describe --tags)
else
	LOG_RVER="devel"
fi
echo '# RoStr '$LOG_RVER'-'$LOG_RREV >> $ROSTRLOG
export ROSTR_VERSION=$LOG_RVER'-'$LOG_RREV

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
		cat "$ADDITIONAL_ARG">>$ROSTRLOG
	else
		echo Declaring: $ADDITIONAL_ARG
		declare $ADDITIONAL_ARG
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

# Find our samples and extract their names
SAMPLEPATHS=`find $1 -name $INPUTEXT`
SAMPLES=()
#export FILE_SAMPLES=()
for SAMPLEPATH in ${SAMPLEPATHS[@]}
do {
	SAMPLE=`getSampleName $SAMPLEPATH`
    SAMPLE=`replaceDots $SAMPLE`
    if containsElement $SAMPLE "${SAMPLES[@]}"
    then
        echo $SAMPLE multiple files found
	else
        SAMPLES+=($SAMPLE)
    fi
    SAMPLEFULLPATH=$( readlink -f $SAMPLEPATH )
	#FILE_SAMPLES+=($SAMPLEFULLPATH)
	declare "INPUT_${SAMPLE}=${SAMPLEFULLPATH} `arrayGet INPUT $SAMPLE`"
} done

echo "Using samples:" ${SAMPLES[@]}

TEST=`arrayGet INPUT s2`
echo ${TEST[@]//R1/R2}

# Bash can't export arrays, just export another variable with the array info
export SAMPLELIST=${SAMPLES[@]}

# Let's fix the folders
DIR_INPUT=$1
DIR_OUTPUT=$2
set +e
mkdir $DIR_OUTPUT
#mkdir $DIR_OUTPUT/log
mkdir $DIR_OUTPUT/wide
mkdir $DIR_OUTPUT/wide/log
for SAMPLE in ${SAMPLES[@]}
do
	mkdir $DIR_OUTPUT/$SAMPLE
	mkdir $DIR_OUTPUT/$SAMPLE/log
	NAME_MULTISAMPLE="${NAME_MULTISAMPLE}_${SAMPLE}"
done
export DIR_OUTPUT=$(readlink -f $DIR_OUTPUT)
set -e
mv $ROSTRLOG $DIR_OUTPUT

if [[ ! -z $NAME_MULTISAMPLE ]] && [[ ${#NAME_MULTISAMPLE} -lt 150 ]]; then
	export NAME_MULTISAMPLE=${NAME_MULTISAMPLE}
else
	export NAME_MULTISAMPLE="_MULT"
fi
echo 'Multisample file name used: ' $NAME_MULTISAMPLE

# Call the plumber to check for defects and shortcuts in our pipeline
source $DIR_BASE/plumbr.sh

# Prepare scheduler
preSubmit

# Simplification for RoStr submits
submitNode() {
	export SAMPLE=$SAMPLE
	export FILE_INPUT=`arrayGet INPUT $SAMPLE`
	export DIR_INPUT=$DIR_INPUT
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
	else
		echo "- $SAMPLE"
	fi
}

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
