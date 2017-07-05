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

# Stub values to work with
SCHEDULER='dry'
QUEUE='defq'
SGE_PE='singlenode'
DIR_NODES=$DIR_BASE/pipelines/
ARG_SUBBASE=""
ARG_JOB_CPU_MAX=99999
