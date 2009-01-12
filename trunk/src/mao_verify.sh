#!/bin/bash

# input is the benchmark we want to try (and optionally the number of lines in the assembly to test)
# Simple verification script written by martint

# Input is either .c, .cpp, cc, or .s file.

#  Some of the more important variables used below
#  
#    MAO_ROOT      = Environment variable must be set before running this script
#    BIN_DIR       = Directory for mao-related binaries
#    CC            = Compiler to use for source files.
#    WORKDIR       = Directory used for holding all files used in the verification
#    IN_FILE       = Input file
#    INPUT_TYPE    = "SOURCE" or "ASSEMBLY"
#    S_FILE        = name of assembly file inside the WORKDIR
#    SRC_FILE      = If INPUT_TYPE is SOURCE, this holds the src file inside the WORKDIR
#    LINES         = Number of lines to verify in the assembly file (0 means all lines)
#                    0 is the default, but can be overridden from the command line

#Helper function
function isNumeric(){ 
  echo "$@" | grep -q -v "[^0-9]"
}

USAGE="Usage: mao_verify.sh target infile [number of lines to verify]"

# Set the target variable correctly.
if [ "$1x" == "i686x" ]; then
  TARGET=i686
elif [ "$1x" == "x86_64x" ]; then
  TARGET=x86_64
else
  echo "${USAGE}";
  exit 1;
fi

# Check command line parameters
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "${USAGE}";
  exit 1;
fi;
# Get the number of lines to verify
if [ -z $3 ]; then
  LINES=0
else
  if isNumeric "$3"; then
    LINES="$3"
  else
     echo "${USAGE}";
     exit 1;    
  fi
fi

TARGET=$1
IN_FILE=$2

CC=gcc
AS=${MAO_ROOT}/binutils-2.19-obj-${TARGET}/gas/as-new
READELF=${MAO_ROOT}/binutils-2.19-obj-${TARGET}/binutils/readelf
OBJDUMP=${MAO_ROOT}/binutils-2.19-obj-${TARGET}/binutils/objdump
MAO=${MAO_ROOT}/bin/mao-${TARGET}

if [ "${MAO_ROOT}x" == "x" ]; then
  echo "Please set MAO_ROOT to point to the root directory of the mao project"
  exit 1;
fi

if [ ! -d "${MAO_ROOT}" ]; then
  echo "Please set MAO_ROOT to point to a valid directory. Currently its set to ${MAO_ROOT}"
  exit 1;
fi


if [ ! -f "${MAO}" ]; then
  echo "Unable to find executable: ${MAO}"
  exit 1;
fi

if [ ! -f "${AS}" ]; then
  echo "Unable to find assembler: ${AS}"
  exit 1;
fi

if [ ! -f "${OBJDUMP}" ]; then
  echo "Unable to find objdump: ${OBJDUMP}"
  exit 1;
fi


if [ ! -f "${READELF}" ]; then
  echo "Unable to find readelf: ${READELF}"
  exit 1;
fi


# Create a workdir. 
WORKDIR=Verify.${RANDOM}
if [ -d "${WORKDIR}" ]; then
  echo "Directory ${WORKDIR} already exists. Try again:"
  exit;
else
  mkdir "${WORKDIR}"
fi

# Static variables
BIN_DIR=${MAO_ROOT}/bin/
FILENAME=`basename "${IN_FILE}"`
EXTENSION="${FILENAME##*.}"
BENCHMARK="${FILENAME%.*}"
S_FILE="${WORKDIR}/${BENCHMARK}.s"
MAO_FILE="${WORKDIR}/${BENCHMARK}.mao"
TMP_O_FILE="${WORKDIR}/tmp.o"

# Check the type of file
case "${EXTENSION}" in
  "S"|"s"                    ) INPUT_TYPE="ASSEMBLY";;
  "c"|"C"|"cc"|"cpp"|"cxx"   ) INPUT_TYPE="SOURCE";;
  *                          ) echo "Not a valid file type" && exit;;
esac 


if [ ! -f "${IN_FILE}" ]; then
  echo "File does not exist: ${IN_FILE}";
  exit;
fi

if [ ${INPUT_TYPE} == "SOURCE" ]; then
  SRC_FILE="${WORKDIR}/${BENCHMARK}.${EXTENSION}"
  cp "${IN_FILE}" "${SRC_FILE}"
  # Compile the file!
  ${CC} -S "${SRC_FILE}" -o "${S_FILE}"
  
  if [ ${LINES} -gt 0 ]; then
    mv "${S_FILE}" "${S_FILE}.tmp"
    head -n ${LINES} "${S_FILE}.tmp" > "${S_FILE}"
    rm "${S_FILE}.tmp"
  fi;
fi
if [ ${INPUT_TYPE} == "ASSEMBLY" ]; then
# Now create the S_FILE
  if [ ${LINES} -eq 0 ]; then
    cp "${IN_FILE}" "${S_FILE}"
  fi;
  if [ ${LINES} -gt 0 ]; then
    head -n ${LINES} "${IN_FILE}" > "${S_FILE}"
  fi;
fi

echo "Processing: ${IN_FILE}"

# Run it trough mao
# Currently does not use gcc as a wrapper, since I dont have a good way to select
# the target platform in gcc (yet).
# TODO(martint): Find a good way to use a gcc as a wrapper for mao.
#                ${CC} -B"${BIN_DIR}" -c -Wa,"-mao_o,${MAO_FILE}" "${S_FILE}" -o "${TMP_O_FILE}"
${MAO} -mao_o "${MAO_FILE}" "${S_FILE}"

# # Generate object files from both
${AS} -o "${S_FILE}.o"   "${S_FILE}" 
${AS} -o "${MAO_FILE}.o" "${MAO_FILE}" 

DIFF_RESULT=`diff "${S_FILE}".o "${MAO_FILE}".o`

if [ $? -ne 0 ]; then
#   # There was a difference! Print out the disassembly
  echo "Difference found"
  ${READELF} -a "${S_FILE}".o >  "${S_FILE}".o.readelf
  ${READELF} -a "${MAO_FILE}".o >  "${MAO_FILE}".o.readelf
  ${OBJDUMP} -d "${S_FILE}".o > "${S_FILE}".o.diss
  ${OBJDUMP} -d "${MAO_FILE}".o > "${MAO_FILE}".o.diss
  echo " Use the following commands to debug:"
  echo "sdiff -w 200 \"${S_FILE}.o.readelf\" \"${MAO_FILE}.o.readelf\""
  echo "sdiff -w 200 \"${S_FILE}.o.diss\" \"${MAO_FILE}.o.diss\""
else
  echo -n "${BENCHMARK} is OK"
  if [ ${LINES} -gt 0 ]; then
    echo -n " for the first ${LINES} lines"
  fi
  echo  
  rm "${S_FILE}" "${MAO_FILE}" "${S_FILE}.o" "${MAO_FILE}.o"
  if [ ${INPUT_TYPE} == "SOURCE" ]; then
    rm "${SRC_FILE}"
  fi
  rmdir "${WORKDIR}"
fi
