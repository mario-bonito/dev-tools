#!/bin/bash

SCRIPT_DIR=$(dirname $0)
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
export MSYS_NO_PATHCONV=1

# =================================================================================================================
# Usage:
# -----------------------------------------------------------------------------------------------------------------
usage() {
  cat <<-EOF
  Lists all docker containers and images.

  Usage: ${0} [ -h -i -c]

  OPTIONS:
  ========
    -c only list containers
    -i only list images
    -h prints the usage for the script

EOF
exit
}

# -----------------------------------------------------------------------------------------------------------------
# Initialization:
# -----------------------------------------------------------------------------------------------------------------
while getopts ich FLAG; do
  case $FLAG in
    c ) CONTAINERS=1 ;;
    i ) IMAGES=1 ;;
    h ) usage ;;
    \?) #unrecognized option - show help
      echo -e \\n"Invalid script option"\\n
      usage
      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "${CONTAINERS}" ] && [ -z "${IMAGES}" ]; then
  # Default to displaying all
  CONTAINERS=1
  IMAGES=1
fi
# =================================================================================================================

if [ ! -z "${CONTAINERS}" ]; then
  echo
  echo "Containers:"
  echo "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
  docker ps -a
  echo "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
fi

if [ ! -z "${IMAGES}" ]; then
  echo
  echo "Images:"
  echo "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
  docker images -a
  echo "--------------------------------------------------------------------------------------------------------------------------------------------------------------"
fi