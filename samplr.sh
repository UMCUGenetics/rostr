while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
	SAMPLEPATH=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $2}'`
	SAMPLE=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $1}'`
	SAMPLE=`replaceDots $SAMPLE`

	# Are samples specified multiple times?
	if containsElement $SAMPLE "${SAMPLES[@]}"
	then
		echo "$SAMPLE defined multiple times"
		exit
	else
		SAMPLES+=($SAMPLE)
	fi

	# Better safe than sorry, ensure the path is real
	SAMPLEFULLPATH=$( realpath $SAMPLEPATH )
	# Perhaps cd to file dir to enable using relative paths?

	# Did the user define the right path anyway?
	if [[ ! -f $SAMPLEFULLPATH ]]
	then
		echo "File for $SAMPLE could not be found here: $SAMPLEPATH"
		exit
	fi

	# The -g functionality may  have limited support, maybe move this to another script and source instead
	declare "INPUT_${SAMPLE}=${SAMPLEFULLPATH} `arrayGet INPUT $SAMPLE`"
	#echo "$SAMPLE at $SAMPLEPATH"
done < "$FILE_SAMPLES"