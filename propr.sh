# Some proper settings and stubs to run rostr without errors by default

# Local qsub stub for testing
qsub() {
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

# Values to work with
SCHEDULER='dry'
SGE_PE='singlenode'
DIR_NODES=$DIR_BASE/nodes
