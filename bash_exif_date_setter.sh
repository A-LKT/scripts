#!/bin/bash

# =========================================================================
# The purpose of this script is to run through directories recursivelly
# and find files that do not have exif data set.
# Any file matching this criteria will be attempted to set create date
# based on filename.
#
# The date parsing mechanism is internal to exiftool. For details 
# consult the source code at https://exiftool.org/
# =========================================================================

### OPTIONS
PIC_DIR='/mnt/d/temp/small/test2_exif'
ELIGIBLE_PIC_EXTENSIONS='PNG JPG JPEG png jpg jpeg'     
ELIGIBLE_PIC_EXTENSIONS_REGEX='PNG\|JPG\|JPEG\|png\|jpg\|jpeg' # MUST BE THE SAME AS ABOVE!     
EXIFTOOL_PATH="/mnt/d/temp/exiftool"



### DO NOT CHANGE ANYTHING BELOW
TOTAL_FILES_PROCESSED=0
SKIPPED_FILES_COUNT=0

welcome_prompt() {
    echo "Batch EXIF date setter v0.1"
    echo "========================"
    echo 
    echo "Attempting to set 'create date' on all images found in"
    echo "  $PIC_DIR"
    echo "and it's sub-directories based on the file name."
    echo
    echo "Only files matching the following extensions will be resized:"
    for ext in $ELIGIBLE_PIC_EXTENSIONS
    do
        echo " *.$ext"
    done
    read -n 1 -r -s -p $'Press any key to continue...\n'
}

main() {
    TOTAL_FILES_PROCESSED=0
    TOTAL_FILES_SKIPPED=0

    clear
    cd $PIC_DIR
    echo "all dirs:"
    ALL_DIRS=`find . -mindepth 1 -type d -printf '%p\n'`
    echo "$ALL_DIRS"
    echo "----------"
    echo

    OIFS="$IFS"
    IFS=$'\n'
    for dir in $ALL_DIRS; do

        echo
        # echo "find '$PIC_DIR/$dir' -type f -regex '.*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)' -printf x \; | wc -c"
        ELIGIBLE_FILE_COUNT_CURRENT_DIR=`find "$PIC_DIR/$dir" -maxdepth 1 -type f -regex ".*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)" -printf x | wc -c`
        TOTAL_FILE_COUNT_CURRENT_DIR=`find "$PIC_DIR/$dir" -maxdepth 1 -type f -printf x | wc -c`
        ELIGIBLE_FILES_CURRENT_DIR=`find "$PIC_DIR/$dir" -maxdepth 1 -type f -regex ".*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)" -printf '%f\n'`
        echo ">> $dir ($ELIGIBLE_FILE_COUNT_CURRENT_DIR/$TOTAL_FILE_COUNT_CURRENT_DIR)"
            for filename in $ELIGIBLE_FILES_CURRENT_DIR; do
                RELATIVE_FILE_PATH="$dir/$filename"
                echo -ne "   $RELATIVE_FILE_PATH\t\t| "
                EXIF_CREATED_DATE=`$EXIFTOOL_PATH/exiftool "$PIC_DIR/$RELATIVE_FILE_PATH" | grep "Create Date" | head -1 | cut -f2- -d':'`
                if [ -z "${EXIF_CREATED_DATE}" ]; then
                    echo -n "exif: no date set. Processing | "
                    $EXIFTOOL_PATH/exiftool "-alldates<filename" "$PIC_DIR/$RELATIVE_FILE_PATH"
                    TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED+1))
                else
                    echo "exif: $EXIF_CREATED_DATE"
                    TOTAL_FILES_SKIPPED=$((TOTAL_FILES_SKIPPED+1))
                fi
            done
    done
    IFS="$OIFS"
    echo "----------"
}


finish() {
    echo "Process finished"
    echo "Total files updated: $TOTAL_FILES_PROCESSED"
    echo "Total files skipped: $TOTAL_FILES_SKIPPED"
}


# MAIN RUN
welcome_prompt
main
finish
