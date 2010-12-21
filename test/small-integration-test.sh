#!/bin/bash -e
COMMON=integration-test-common.sh
source $COMMON

# Require root
REQUIRE_ROOT=require-root.sh
source $REQUIRE_ROOT

# Configuration
TEST_TEXT="HELLO WORLD"
TEST_TEXT_FILE=test-s3fs.txt
ALT_TEST_TEXT_FILE=test-s3fs-ALT.txt
TEST_TEXT_FILE_LENGTH=15

# Mount the bucket
if [ ! -d $TEST_BUCKET_MOUNT_POINT_1 ]
then
	mkdir -p $TEST_BUCKET_MOUNT_POINT_1
fi
$S3FS $TEST_BUCKET_1 $TEST_BUCKET_MOUNT_POINT_1 -o passwd_file=$S3FS_CREDENTIALS_FILE
CUR_DIR=`pwd`
cd $TEST_BUCKET_MOUNT_POINT_1

if [ -e $TEST_TEXT_FILE ]
then
  rm -f $TEST_TEXT_FILE
fi

# Write a small test file
for x in `seq 1 $TEST_TEXT_FILE_LENGTH`
do
	echo $TEST_TEXT >> $TEST_TEXT_FILE
done

# Verify contents of file
FILE_LENGTH=`wc -l $TEST_TEXT_FILE | awk '{print $1}'`
if [ "$FILE_LENGTH" -ne "$TEST_TEXT_FILE_LENGTH" ]
then
	exit 1
fi

# Delete the test file
rm $TEST_TEXT_FILE
if [ -e $TEST_TEXT_FILE ]
then
   echo "Could not delete file, it still exists"
   exit 1
fi

##########################################################
# Rename test (individual file)
##########################################################
echo "Testing mv file function ..."


# if the rename file exists, delete it
if [ -e $ALT_TEST_TEXT_FILE ]
then
   rm $ALT_TEST_TEXT_FILE
fi

if [ -e $ALT_TEST_TEXT_FILE ]
then
   echo "Could not delete file ${ALT_TEST_TEXT_FILE}, it still exists"
   exit 1
fi

# create the test file again
echo $TEST_TEXT > $TEST_TEXT_FILE
if [ ! -e $TEST_TEXT_FILE ]
then
   echo "Could not create file ${TEST_TEXT_FILE}, it does not exist"
   exit 1
fi

#rename the test file
mv $TEST_TEXT_FILE $ALT_TEST_TEXT_FILE
if [ ! -e $ALT_TEST_TEXT_FILE ]
then
   echo "Could not move file"
   exit 1
fi

# Check the contents of the alt file
ALT_TEXT_LENGTH=`echo $TEST_TEXT | wc -c | awk '{print $1}'`
ALT_FILE_LENGTH=`wc -c $ALT_TEST_TEXT_FILE | awk '{print $1}'`
if [ "$ALT_FILE_LENGTH" -ne "$ALT_TEXT_LENGTH" ]
then
   echo "moved file length is not as expected expected: $ALT_TEXT_LENGTH  got: $ALT_FILE_LENGTH"
   exit 1
fi

# clean up
rm $ALT_TEST_TEXT_FILE

if [ -e $ALT_TEST_TEXT_FILE ]
then
   echo "Could not cleanup file ${ALT_TEST_TEXT_FILE}, it still exists"
   exit 1
fi


#####################################################################
# Tests are finished
#####################################################################

# Unmount the bucket
cd $CUR_DIR
umount $TEST_BUCKET_MOUNT_POINT_1

echo "All tests complete."