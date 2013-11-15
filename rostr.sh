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

DIR_BASE=$(dirname $0) # Dir script resides in
DIR_BASE=$(readlink -f $DIR_BASE) # Obtain the full path, otherwise nodes go crazy
DIR_CUR=${PWD} # Dir script is called from

FILE_CONFIG=$3
source $DIR_BASE/propr.sh
source $FILE_CONFIG
source $DIR_BASE/submit/$SCHEDULER.sh
			
STAMP=`date +%s`

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

export DIR_OUTPUT=$(readlink -f $2)
# Let's fix the folders
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
set -e

# Call the plumber to check for defects and shortcuts in our pipeline
source plumbr.sh

# Prepare scheduler
preSubmit

# Work your way through the pipeline that is left
for NODENAME in ${PIPELINE[@]}
do
	echo ""
	echo "X" $NODENAME
	#export NODE=./nodes/$NODENAME.sh
	export NODE=$( readlink -f $DIR_NODES/$NODENAME.sh )
	REQS=(`grep '#RS requires' $NODE | cut -d\  -f3-`)
	PROS=(`grep '#RS provides' $NODE | cut -d\  -f3-`)
	#ARGS=`grep '#RS argument' $NODE | cut -d\  -f3-`
	ARGS=(`arrayGet ARGUMENTS $NODENAME`)
	ADDS=(`grep '#RS addition' $NODE | cut -d\  -f3-`)
	TYPE=(`grep '#RS widenode' $NODE | cut -d\  -f2-`)

	# Node is run specific: wide over (all) samples
	if [ "$TYPE" = 'widenode' ]
	then {
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
			echo Full width detected: ${SAMPLES[@]}
			export FILE_OUTPUT=$DIR_OUTPUT/runwide/runwide
			export DIR_LOG=$DIR_OUTPUT/runwide/log
			export FILE_LOG_ERR=$DIR_LOG/${NODENAME}.e${STAMP}
			export FILE_LOG_OUT=$DIR_LOG/${NODENAME}.o${STAMP}
			export JOB_NAME=RoStr_WIDE_${NODENAME}
			JOBID=$RANDOM
			declare "WIDE_JOBIDS_${NODENAME}=${JOBID}"
		fi
	}
	# Node is sample specific: single sample
	else {
		for SAMPLE in ${SAMPLES[@]}
		do
			echo "|\ "$SAMPLE
			export FILE_INPUT=`arrayGet INPUT $SAMPLE`
			export FILE_OUTPUT=$DIR_OUTPUT/$SAMPLE/$SAMPLE
			export DIR_LOG=$DIR_OUTPUT/$SAMPLE/log
			export FILE_LOG_ERR=$DIR_LOG/${NODENAME}.e${STAMP}
			export FILE_LOG_OUT=$DIR_LOG/${NODENAME}.o${STAMP}
			export JOB_NAME=RoStr_${SAMPLE}_${NODENAME}
			export SUBARGS=""
			submit
			declare "${SAMPLE}_JOBIDS_${NODENAME}=${JOBID}"
			echo "| \ "Job added as `arrayGet ${SAMPLE}_JOBIDS ${NODENAME}`
		done
	} fi
done

# Finish scheduler
postSubmit
