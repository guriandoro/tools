#!/bin/bash

DO_NOT_STOP_CONTAINER_LABEL="do_not_stop_this_instance"

# Print to STDOUT ID, Name and Labels of the containers that will be stopped
echo "Stopping the following containers:"
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Labels}}" | grep -v "${DO_NOT_STOP_CONTAINER_LABEL}"

echo

# Execute the `docker stop` command on all containers that don't have the appropriate label set
# TODO: change `echo` for appropriate stop command
docker ps --format "{{.ID}}\t{{.Labels}}" | grep -v "${DO_NOT_STOP_CONTAINER_LABEL}" | awk '{print $1}' | xargs -I{} echo "## Will remove: {}"

exit

