#!/bin/bash
# mainframe_operations.sh
# Set up environment
export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COBOLCHECK_DIR="${SCRIPT_DIR}/../../COBOLcheck"
COBOLCHECK_JAR="${COBOLCHECK_DIR}/bin/cobol-check-0.2.19.jar"
GENERATED_DIR="${COBOLCHECK_DIR}/testruns"

if [[ ! -d "$COBOLCHECK_DIR" ]]; then
  echo "COBOLcheck directory not found: $COBOLCHECK_DIR" >&2
  exit 1
fi

if [[ ! -f "$COBOLCHECK_JAR" ]]; then
  echo "CobolCheck JAR not found: $COBOLCHECK_JAR" >&2
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java is not available on PATH" >&2
  exit 1
fi

# Check Java availability
java -version
# Set ZOWE_USERNAME
ZOWE_USERNAME="Z81114" # Replace with the actual username

if ! chmod +x "$COBOLCHECK_DIR/scripts/linux_gnucobol_run_tests"; then
  echo "Could not make the GnuCOBOL test runner executable" >&2
  exit 1
fi

cd "$COBOLCHECK_DIR" || exit 1
echo "Changed to $(pwd)"
ls -al

if ! mkdir -p "$GENERATED_DIR"; then
  echo "Could not create CobolCheck output directory: $GENERATED_DIR" >&2
  exit 1
fi

# Function to run cobolcheck and copy files
run_cobolcheck() {
  local program=$1
  local source_file="${COBOLCHECK_DIR}/src/main/cobol/${program}.CBL"

  if [ ! -f "$source_file" ]; then
    echo "Source program not found; skipping $program: $source_file"
    return
  fi

  echo "Running CobolCheck for $program"
  java -jar "$COBOLCHECK_JAR" -p "$program"
  echo "CobolCheck execution completed for $program (exceptions may have occurred)"

  if [ -f "$GENERATED_DIR/CC##99.CBL" ]; then
    if cp "$GENERATED_DIR/CC##99.CBL" "//'${ZOWE_USERNAME}.CBL($program)'"; then
      echo "Copied CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
    else
      echo "Failed to copy CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
    fi
  else
    echo "Generated file not found: $GENERATED_DIR/CC##99.CBL"
  fi

  if [ -f "${program}.JCL" ]; then
    if cp "${program}.JCL" "//'${ZOWE_USERNAME}.JCL($program)'"; then
      echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    else
      echo "Failed to copy ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    fi
  else
    echo "${program}.JCL not found in $COBOLCHECK_DIR"
  fi
}

# Run for each program
for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck "$program"
done
echo "Mainframe operations completed"
