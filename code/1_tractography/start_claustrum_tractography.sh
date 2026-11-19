#!/bin/bash
#
# Launch claustrum tractography for a list of subjects. Requires the separate run_claustrum_tractography.sh script to be correctly set up.
#
# Usage:
#   ./start_claustrum_tractography.sh subjects_PT.txt              # all subjects
#   ./start_claustrum_tractography.sh subjects_PT.txt 1 12         # runs subjects 1-12 of the provided list only
#
# Author: Jil Wendt | 2026-09-04
# Adapted from previous start_probtrackx scripts by Jil Wendt and Aurore Menegaux (2023-09)

set -euo pipefail

SUBJECT_LIST="${1:?Usage: $0 <subject_list.txt> [start_index] [end_index]}"
START="${2:-1}"
END="${3:-0}"

SCRIPT_DIR="/path/to/scripts"
TRACT_SCRIPT="${SCRIPT_DIR}/run_claustrum_tractography.sh"

[[ -x "${TRACT_SCRIPT}" ]] || { echo "ERROR: ${TRACT_SCRIPT} not executable" >&2; exit 1; }

mapfile -t ALL < <(grep -vE '^\s*(#|$)' "${SUBJECT_LIST}")
[[ ${END} -eq 0 ]] && END=${#ALL[@]}

SEED_REGION=$(grep -m1 '^SEED_REGION=' "${TRACT_SCRIPT}" | cut -d'=' -f2 | cut -d' ' -f1) \
    || { echo "ERROR: no SEED_REGION line found in ${TRACT_SCRIPT}" >&2; exit 1; }

echo "List      : ${SUBJECT_LIST} (${#ALL[@]} subjects)"
echo "Running   : ${START} to ${END}"
echo "Script    : ${TRACT_SCRIPT}"
echo "Seed      : ${SEED_REGION}"
echo ""

for (( i=START; i<=END; i++ )); do
    ID="${ALL[$((i-1))]}"
    [[ -n "${ID}" ]] || continue
    echo "[${i}/${#ALL[@]}] launching ${ID}"

    screen -d -m -S "${ID}" "${TRACT_SCRIPT}" "${ID}"
done

echo ""
echo "Launched. Monitor with:  screen -ls"
