getSampleName() {
	echo $1 | awk -F"/"  '{ print  $NF }' | cut -d. -f1 | cut -d\_ -f1
}

SAMPLEPATHS=`find $1 -name '*.bam' | sort`
#realpath $SAMPLEPATHS
for SAMPLEPATH in `realpath ${SAMPLEPATHS[@]}`
do {
	SAMPLE=`getSampleName $SAMPLEPATH`
	echo -e "$SAMPLE\t$SAMPLEPATH"
} done > $2

while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
	SAMPLENAME=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $1}'`
	SAMPLEPATH=`echo "$LINE" | awk 'BEGIN {FS="\t"}; {print $2}'`
	echo "$SAMPLENAME at $SAMPLEPATH"
done < "$2"