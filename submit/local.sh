# Local translator
# Do the actual work
submitForReal() {
	source $NODE
	JOBID="N/A: Local run"
}

# Dump the output and errors to files as if you were the real thing
submit() {
	submitForReal > $FILE_LOG_OUT 2> $FILE_LOG_ERR
}
