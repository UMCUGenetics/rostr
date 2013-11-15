# Some proper settings and stubs to run rostr without errors by default

# Local qsub stub for testing
noqsub() {
	echo $RANDOM
}

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

# Stub for retrieving a sample name
getSampleName() {
	echo $1 | cut -d. -f1 | cut -d\_ -f1
}

# Values to work with
SCHEDULER='dry'
SGE_PE='singlenode'
DIR_NODES=$DIR_BASE/nodes
