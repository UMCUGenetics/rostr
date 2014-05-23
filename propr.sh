# Some proper settings and stubs to run rostr without errors by default

# Local qsub stub for testing
#qsub() {
#	echo $RANDOM
#}

# Stubs for submission steps, override in submission scripts where needed
preSubmit() {
	return
}
submit() {
	return
}
postSubmit() {
	return
}

# Stub for retrieving a sample name from a path
getSampleName() {
	echo $1 | awk -F"/"  '{ print  $NF }' | cut -d. -f1 | cut -d\_ -f1
}

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
				HOLDID=`arrayGet JOBIDS_WIDE ${REQNODE}`
				HOLDFOR="$HOLDFOR;$HOLDID"
			# If REQNODE is not wide
			else
				# Test if we are wide ourselves and add all preceding sample jobs if so
				if [ `arrayGet WIDENODES ${NODENAME}` ]
				then
					for DEPSAMPLE in ${SAMPLES[@]}
					do
						HOLDID=`arrayGet JOBIDS_${DEPSAMPLE} ${REQNODE}`
						HOLDFOR="$HOLDFOR;$HOLDID"
					done
				# And if we are not, just add one sample dependency
				else
					HOLDFOR+=(`arrayGet JOBIDS_${SAMPLE} ${REQNODE}`)
					HOLDID=`arrayGet JOBIDS_${SAMPLE} ${REQNODE}`
					HOLDFOR="$HOLDFOR};$HOLDID"
				fi
			fi
		done
	fi
	
	echo $HOLDFOR
}

# Stub values to work with
SCHEDULER='dry'
SGE_PE='singlenode'
DIR_NODES=$DIR_BASE/nodes
ARG_SUBBASE=""
