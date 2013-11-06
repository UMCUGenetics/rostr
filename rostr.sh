set -e

DIR_BASE=$(dirname $0) # Dir script resides in
DIR_BASE=$(readlink -f $DIR_BASE) # Obtain the full path, otherwise nodes go crazy
DIR_CUR=${PWD} # Dir script is called from

# Local qsub stub for testing
qsub() {
	echo $RANDOM
}

# Get value from map by key:
arrayGet() { 
	local ARRAY=$1 INDEX=$2
	local i="${ARRAY}_$INDEX"
	printf '%s' "${!i}"
}

SCHEDULER='dry'
SGE_PE='singlenode'
source $3

if [ ! $SCHEDULER ]
then
	echo "No scheduler set, please set env variable: export SCHEDULER=... (sge,pbs,local,dry,...)"
	exit
fi

STAMP=`date +%s`

# Find our samples and extract their names
SAMPLEPATHS=`find $1 -name $INPUTEXT`
SAMPLES=()
for SAMPLEPATH in ${SAMPLEPATHS[@]}
do {
	#SAMPLE=basename $PATH
	SAMPLE=`echo $SAMPLEPATH | awk -F"/"  '{ print  $NF }'`
	SAMPLE=`echo $SAMPLE | cut -d. -f1`
	#echo $SAMPLE
	SAMPLES+=($SAMPLE)
	SAMPLEFULLPATH=$( readlink -f $SAMPLEPATH )
	declare "INPUT_${SAMPLE}=${SAMPLEFULLPATH}"
} done
echo "Using samples:" ${SAMPLES[@]}

# Let's fix the folders
set +e
mkdir $2
mkdir $2/log
for SAMPLE in ${SAMPLES[@]}
do
	mkdir $2/$SAMPLE
	mkdir $2/$SAMPLE/log
done
set -e
DIR_LOG=$( readlink -f $2/log )

# Call the plumber to check for defects and shortcuts in our pipeline
source plumbr.sh

# Work your way through the pipeline that is left
for NODENAME in ${PIPELINE[@]}
do
	echo -----
	echo "> >" $NODENAME
	export NODE=./nodes/$NODENAME.sh
	REQS=`grep '#RS requires' $NODE | cut -d\  -f3-`
	PROS=`grep '#RS provides' $NODE | cut -d\  -f3-`
	#ARGS=`grep '#RS argument' $NODE | cut -d\  -f3-`
	ARGS=`arrayGet ARGUMENTS $NODENAME`
	ADDS=`grep '#RS addition' $NODE | cut -d\  -f3-`
	TYPE=`grep '#RS widenode' $NODE | cut -d\  -f2-`

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
			JOBID=$RANDOM
			declare "WIDE_JOBIDS_${NODENAME}=${JOBID}"
		fi
	}
	# Node is sample specific: single sample
	else {
		for SAMPLE in ${SAMPLES[@]}
		do
			echo ">" $SAMPLE
			export FILE_OUTPUT=$2/$SAMPLE/$SAMPLE
			export DIR_LOG=$2/$SAMPLE/log
			SUBARGS=""
			source ./submit/$SCHEDULER.sh
			declare "${SAMPLE}_JOBIDS_${NODENAME}=${JOBID}"
			echo `arrayGet ${SAMPLE}_JOBIDS ${NODENAME}`
		done
	} fi
done
