#!/bin/bash

DO_NOT_STOP_SANDBOX_FILE="do_not_stop_this_sandbox"

# Generate temp file for storing status_all outputs
# Try until the generated name doesn't collide with another existing file
TMP_FILE=""

until [ ! -f ${TMP_FILE} ]; do
  TMP_FILE=`date|md5sum`
  TMP_FILE="/tmp/stop_sandboxes".${TMP_FILE:1:10}."tmp"
done

date
echo
echo -e "USER\t\t\t\t\tSTARTED_NODES\tSTOPPED_NODES\tFLAGGED_DIRECTORIES"

# First pass to gather and print information
for SANDBOX_DIR in `find /home/ -maxdepth 2 -type d -name "sandboxes"`; do
  if [ -d "${SANDBOX_DIR}" ]; then
    echo -e -n "${SANDBOX_DIR}" "\t\t"

    cd "${SANDBOX_DIR}"

    ./status_all 2>/dev/null 1> ${TMP_FILE}

    STARTED_SANDBOXES=`cat ${TMP_FILE} | egrep " on$" | wc -l`
    echo -e -n "${STARTED_SANDBOXES}" "\t\t"

    STOPPED_SANDBOXES=`cat ${TMP_FILE} | egrep " off$" | wc -l`
    echo -e -n "${STOPPED_SANDBOXES}" "\t\t"

    FLAGGED_DIRECTORIES=`find . -name ${DO_NOT_STOP_SANDBOX_FILE} | wc -l`
    echo -e -n "${FLAGGED_DIRECTORIES}" "\t"

    echo
  fi
done


# Second pass to stop sandboxes
echo -e "\nSTOPPING SANDBOXES...\n"

# We don't check if the instances are running, we try to stop all the ones that
# don't have the sentinel file, and have stop* scripts

for SANDBOX_DIR in `find /home/ -maxdepth 2 -type d -name "sandboxes"`; do
  if [ -d "${SANDBOX_DIR}" ]; then
    # We use '-mindepth 1' to avoid executing stop_all from sandboxes main directory
    for SANDBOX in `find ${SANDBOX_DIR} -mindepth 1 -maxdepth 1 -type d`; do
      cd "${SANDBOX}"

      # We check for the sentinel file to flag skipping stop[_all] on this sandbox
      if [ -f ${DO_NOT_STOP_SANDBOX_FILE} ]; then
        echo "#  SKIPPING STOP! " ${SANDBOX}
        continue
      fi

      # If the stop_all script is available, we execute it
      if [ -f stop_all ]; then
        # TODO: change `echo` for actual stop command
        echo -e "--> EXECUTING STOP_ALL\t" ${SANDBOX}
      # If not, if the stop script is available, we execute it
      elif [ -f stop ]; then
        # TODO: change `echo` for actual stop command
        echo -e "--> EXECUTING STOP\t" ${SANDBOX}
      fi
    
    done

    echo
  fi
done

rm -f ${TMP_FILE}

exit 0

