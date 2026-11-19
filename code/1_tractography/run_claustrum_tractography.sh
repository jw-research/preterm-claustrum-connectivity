#!/bin/bash
#
# Run seed-cortex probabilistic tractography using FSL probtrackx2; seed is set below via SEED_REGION: claustrum (for main analysis) or
# insula / putamen (for control analyses).
#
# Usage: use launcher script (start_claustrum_tractography.sh) to run for multiple subjects from a defined subject list
#
# Author: Jil Wendt | 2026-09-04
# Adapted from previous start_probtrackx scripts by Jil Wendt and Aurore Menegaux (2023-09)

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
ID="${1:?Usage: $0 <SUBJECT_ID>}"

PROJECT=/path/to/project
INPATH="${PROJECT}/1_Subjects/BEST_subjects_PT"
OUTPATH="${PROJECT}/1_Tractography/3_Tractography_Outputs"

PROBTRACKX="${FSLDIR}/bin/probtrackx2"   # FSL 6.0.1

SEED_REGION=claustrum        # claustrum | insula | putamen
SEED_LABEL="claustrum_rem"   # claustrum seed file: <hemi>_claustrum_rem.nii.gz
RUN_CONTRA="false"

# Probtrackx2 tracking parameters
CURV_THRESH=0.2         # -c
N_STEPS=2000            # -S
STEP_LENGTH=0.5         # --steplength
N_SAMPLES=5000          # -P  (streamlines per seed voxel)
FIB_THRESH=0.01         # --fibthresh
DIST_THRESH=0.0         # --distthresh
SAMPVOX=0.0             # --sampvox

TARGETS=(AC_Occ AC_Temp AC_Par AC_PFC C_ant C_pos PC_mot PC_sens PC_vis PC_aud SC_Hip)

# ----------------------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------------------
for SEED_SIDE in L R; do

    case "${SEED_REGION}" in
        claustrum) SEED_MASK="${SUBJ_DIR}/Claustrum/${SEED_SIDE}_${SEED_LABEL}.nii.gz" ;;
        insula)    SEED_MASK="${SUBJ_DIR}/Masks/Ins_${SEED_SIDE}.nii.gz" ;;
        putamen)   SEED_MASK="${SUBJ_DIR}/Masks/SC_BG_Str_put_${SEED_SIDE}.nii.gz" ;;
    esac
    [[ -f "${SEED_MASK}" ]] || { echo "ERROR: missing seed ${SEED_MASK}" >&2; exit 1; }

    if [[ "${SEED_SIDE}" == "L" ]]; then OTHER_HEMI=R; else OTHER_HEMI=L; fi

    for TARGET_SIDE in L R; do

        if [[ "${TARGET_SIDE}" != "${SEED_SIDE}" && "${RUN_CONTRA}" != "true" ]]; then
            continue
        fi

        for TARGET in "${TARGETS[@]}"; do

            REGION="${SEED_SIDE}_${SEED_NAME}_2_${TARGET}_${TARGET_SIDE}"
            TARGET_MASK="${SUBJ_DIR}/Masks/${TARGET}_${TARGET_SIDE}.nii.gz"
            DIR="${OUTPATH}/${REGION}/${ID}"

            [[ -f "${TARGET_MASK}" ]] || {
                echo "WARNING: missing target mask ${TARGET_MASK} - skipping" >&2
                continue; }

            mkdir -p "${DIR}"
            LOG="${DIR}/logfile.log"
            echo "Calculate ${REGION} for ${ID}" > "${LOG}"
            echo "Seed:   ${SEED_MASK}"          >> "${LOG}"
            echo "Target: ${TARGET_MASK}"        >> "${LOG}"

            # exclusion mask only for ipsilateral tracts
            AVOID_ARG=()
            if [[ "${TARGET_SIDE}" == "${SEED_SIDE}" ]]; then
                AVOID_ARG=(--avoid="${SUBJ_DIR}/Masks/${OTHER_HEMI}_hemi.nii.gz")
                echo "Avoid:  ${OTHER_HEMI}_hemi" >> "${LOG}"
            fi

            begin=$(date +%s)

            "${PROBTRACKX}" \
                -x "${SEED_MASK}" \
                -l --onewaycondition \
                -c "${CURV_THRESH}" \
                -S "${N_STEPS}" \
                --steplength="${STEP_LENGTH}" \
                -P "${N_SAMPLES}" \
                --fibthresh="${FIB_THRESH}" \
                --distthresh="${DIST_THRESH}" \
                --sampvox="${SAMPVOX}" \
                "${AVOID_ARG[@]}" \
                --wtstop="${TARGET_MASK}" \
                --waypoints="${TARGET_MASK}" \
                --waycond=AND \
                --forcedir --opd \
                -s "${BEDPOST}/merged" \
                -m "${BEDPOST}/nodif_brain_mask" \
                --dir="${DIR}" \
                >> "${LOG}" 2>&1

            after=$(date +%s)
            echo "duration: $((after - begin)) s" >> "${LOG}"
            echo "  ${REGION}  ($((after - begin)) s)"

        done
    done
done

echo "Finished ${ID}"
