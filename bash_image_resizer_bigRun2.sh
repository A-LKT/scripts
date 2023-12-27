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
#   - skips already processed files (toggle)
# =========================================================================

### OPTIONS
OVERWRITE_ORIGINAL_FILE=false
TARGET_RESOLUTION=1920
SOURCE_PIC_DIR='/mnt/f/Pers/Photo'
DESTINATION_PIC_DIR='/mnt/f/Pers/small'
# space separated extensions, case-sensitive. ie "JPG jpg jpeg"
ELIGIBLE_PIC_EXTENSIONS='PNG JPG JPEG png jpg jpeg'     
ELIGIBLE_PIC_EXTENSIONS_REGEX='PNG\|JPG\|JPEG\|png\|jpg\|jpeg' # MUST BE THE SAME AS ABOVE!     
SHOW_UNPROCESSED=false
SKIP_EXISTING=true











### DO NOT CHANGE ANYTHING BELOW
TOTAL_FILES_PROCESSED=0
SKIPPED_FILES_COUNT=0

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
        if [ "$SKIP_EXISTING" = true ]; then
            if [ -d "$DESTINATION_PIC_DIR/$directory" ]; then
                echo "Found an existing target directory $DESTINATION_PIC_DIR/$directory"
                ALREADY_PROCESSED_COUNT=`find $DESTINATION_PIC_DIR/$directory -type f -name "*.$extension" -exec printf x \; | wc -c`
                TO_BE_PROCESSED_COUNT=`find $SOURCE_PIC_DIR/$directory -type f -name "*.$extension" -exec printf x \; | wc -c`
                echo "ALREADY_PROCESSED_COUNT $ALREADY_PROCESSED_COUNT : TO_BE_PROCESSED_COUNT $TO_BE_PROCESSED_COUNT"
                if [ "$ALREADY_PROCESSED_COUNT" -eq "$TO_BE_PROCESSED_COUNT" ]; then
                    echo "Number of files to be processed is equal to number of existing files. Skipping directory."
                    SKIPPED_FILES_COUNT=$((SKIPPED_FILES_COUNT+TO_BE_PROCESSED_COUNT))
                else
                    echo "Number of files to be processed is NOT equal to number of existing files. Reprocessing directory."
                    run_resize "$DESTINATION_PIC_DIR/$directory" "$extension"
                fi
            else
                echo "SKIP_EXISTING is enabled but $DESTINATION_PIC_DIR/$directory does not exist. Proceeding with resize"
                run_resize "$DESTINATION_PIC_DIR/$directory" "$extension"
            fi
        else
            run_resize "$DESTINATION_PIC_DIR/$directory" "$extension"
        fi
    fi
    cd $SOURCE_PIC_DIR
}

run_resize() {
    DESTINATION_DIR=$1
    EXTENSION=$2
    echo "mogrify -resize ${TARGET_RESOLUTION}x -path '$DESTINATION_DIR' ./*.$EXTENSION"
    mkdir -p "$DESTINATION_DIR"
    mogrify -resize ${TARGET_RESOLUTION}x -path "$DESTINATION_DIR" ./*.$EXTENSION
    FILES_PROCESSED_IN_CURRENT_DIR=`find $DESTINATION_PIC_DIR/$directory -type f -name "*.$extension" -exec printf x \; | wc -c`
    TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED+FILES_PROCESSED_IN_CURRENT_DIR))
}

finish() {
    TOTAL_FILES_IN_SOURCE=`find . -type f -regex ".*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)" -exec printf x \; | wc -c`
    UNHANDLED_FILES_COUNT=`find . -type f -not -regex ".*\.\($ELIGIBLE_PIC_EXTENSIONS_REGEX\)" | wc -l`
    echo
    echo "========================"
    echo "Finished processing."
    echo "Total images in source: $TOTAL_FILES_IN_SOURCE"
    echo "Total images skipped: $SKIPPED_FILES_COUNT"
    echo "Total unhandled files: $UNHANDLED_FILES_COUNT"
    echo "Total images processed: $TOTAL_FILES_PROCESSED"
}


# MAIN RUN
welcome_prompt
main
finish