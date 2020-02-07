#!/bin/sh

set -e

PROG_NAME=$0
GTAGS_EXE=gtags
GTAGS_ARGS=
GTAGS_OPT_FILE=
PROJECT_ROOT=
FILE_LIST_CMD=


ShowUsage() {
    echo "Usage:"
    echo "    $PROG_NAME <options>"
    echo ""
    echo "    -e [exe=gtags]: The ctags executable to run"
    echo "    -p [dir=]:      The path to the project root"
    echo "    -L [cmd=]:      The file list command to run"
    echo "    -o [options=]:  An options file to read additional options from"
    echo ""
}

while getopts "h?e:p:L:o:" opt; do
    case $opt in
        h|\?)
            ShowUsage
            exit 0
            ;;
        e)
            GTAGS_EXE="$OPTARG"
            ;;
        p)
            PROJECT_ROOT="$OPTARG"
            ;;
        L)
            FILE_LIST_CMD="$OPTARG"
            ;;
        o)
            GTAGS_OPT_FILE="$OPTARG"
            ;;
    esac
done

shift $((OPTIND - 1))

if [ "$1" != "" ]; then
    echo "Invalid Argument: $1"
    exit 1
fi

mkdir -p "${PROJECT_ROOT}"
TAGS_FILE="${PROJECT_ROOT}/.gtags"

echo "Locking gtags DB files..."
echo $$ > "${TAGS_FILE}.lock"

# Remove lock and temp file if script is stopped unexpectedly.
trap 'errorcode=$?; rm -f "${TAGS_FILE}.lock" "${TAGS_FILE}.files"; exit $errorcode' INT QUIT TERM EXIT

if [ -n "${FILE_LIST_CMD}" ]; then
    echo "Running file list command"
    echo "eval $FILE_LIST_CMD > \"${TAGS_FILE}.files\""
    eval "$FILE_LIST_CMD" > "${TAGS_FILE}.files"
    GTAGS_ARGS="${GTAGS_ARGS} -f \"${TAGS_FILE}.files\""
fi

if [ -f "${GTAGS_OPT_FILE}" ]; then
    GTAGS_ARGS="${GTAGS_ARGS} $(cat ${GTAGS_OPT_FILE})"
fi

echo "Running gtags"
echo "${GTAGS_EXE} ${GTAGS_ARGS} --incremental \"${PROJECT_ROOT}\""
"${GTAGS_EXE}" ${GTAGS_ARGS} --incremental "${PROJECT_ROOT}"

echo "Unlocking gtags DB files..."
rm -f "${TAGS_FILE}.lock"

echo "Done."
