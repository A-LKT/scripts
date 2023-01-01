#!/bin/bash

# =========================================================================
# The purpose of this script is to enable quick and effortless conversion
#  of multiple images to the same size.
# 
# Features:
#   - uses imagemagick and mogrify for resizing
#   - can either replace original file or write to a sibling directory
#   - traverses sub-directories
#   - supports multiple file formats
# =========================================================================

### OPTIONS
OVERWRITE_ORIGINAL_FILE=false
TARGET_RESOLUTION=1920
SOURCE_PIC_DIR='/mnt/d/temp/company_photos_dump2022.12'
DESTINATION_PIC_DIR='/mnt/d/temp/small/test1'
# space separated extensions, case-sensitive. ie "JPG jpg jpeg"
ELIGIBLE_PIC_EXTENSIONS='PNG JPG JPEG png jpg jpeg'     
ELIGIBLE_PIC_EXTENSIONS_REGEX='PNG\|JPG\|JPEG\|png\|jpg\|jpeg' # MUST BE THE SAME AS ABOVE!     
SHOW_UNPROCESSED=false











### DO NOT CHANGE ANYTHING BELOW
TOTAL_FILES_PROCESSED=0

welcome_prompt() {
    echo "Batch Image resizer v0.1"
    echo "========================"
    echo 
    echo "Attempting to resize all images found in $SOURCE_PIC_DIR and 
    it's sub-directories."
    echo
    echo "Only files matching the following extensions will be resized:"
    for ext in $ELIGIBLE_PIC_EXTENSIONS
    do
        echo " *.$ext"
    done
    read -n 1 -r -s -p $'Press enter to continue...\n'
}

# DEFINITIONS
main() {
    clear
    cd $SOURCE_PIC_DIR
    for ext in $ELIGIBLE_PIC_EXTENSIONS; do
        OIFS="$IFS"
        IFS=$'\n'
        echo
        echo ">> $ext"
        ELIGIBLE_DIRS=`find . -type f -name "*.$ext" -exec dirname {} \; | sort -u`
        for dir in $ELIGIBLE_DIRS; do
            process_single_directory $ext "$dir"
        done
        IFS="$OIFS"
    done
}

# $1 = extension, $2 = dir
process_single_directory() {
    extension=$1
    directory=$2
    cd $directory
    if [ "$OVERWRITE_ORIGINAL_FILE" = true ]; then
        echo "mogrify -resize ${TARGET_RESOLUTION}x ./*.$extension"
        mogrify -resize ${TARGET_RESOLUTION}x ./*.$extension
    else
        echo "mogrify -resize ${TARGET_RESOLUTION}x -path '$DESTINATION_PIC_DIR/$directory' ./*.$extension"
        mkdir -p "$DESTINATION_PIC_DIR/$directory"
        mogrify -resize ${TARGET_RESOLUTION}x -path "$DESTINATION_PIC_DIR/$directory" ./*.$extension
    fi
    FILES_PROCESSED_IN_CURRENT_DIR=`ls $DESTINATION_PIC_DIR/$directory/*.$extension | wc -l`
    TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED+FILES_PROCESSED_IN_CURRENT_DIR))
    cd $SOURCE_PIC_DIR
}

finish() {
    TOTAL_FILES_IN_SOURCE=`find . -type f -regex ".*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)" | wc -l`
    UNHANDLED_FILES=`find . -type f -not -regex '.*\.\(PNG\|JPG\|JPEG\|png\|jpg\|jpeg\)'`
    echo
    echo "========================"
    echo "Finished processing."
    echo "Total images in source: $TOTAL_FILES_IN_SOURCE"
    echo "Total images processed: $TOTAL_FILES_PROCESSED"
    if [ "$SHOW_UNPROCESSED" = true ]; then
        echo "unprocessed files:"
        echo "$UNHANDLED_FILES"
    fi 
}


# MAIN RUN
welcome_prompt
main
finish