#!/bin/bash
#
# Extract claustrum volumes in structural space (as originally segmented)
#
# The segmentation is bilateral; volumes per side are obtained by intersecting it with the left/right hemisphere masks.
#
# Usage: edit COHORT (PT or FT), then run ./get_struct_claustrum_volumes.sh

COHORT=PT          # PT or FT

# paths (set before running)
PROJECT_PT=/path/to/project_PT
PROJECT_FT=/path/to/project_FT
ANALYSIS_DIR=/path/to/analysis

if [[ "${COHORT}" == "PT" ]]; then
    PROJECT=${PROJECT_PT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/BEST_subjects_PT
    GROUP=PT
    OUT_CSV=${ANALYSIS_DIR}/tract_metrics/claustrum_struct_vol_PT.csv

elif [[ "${COHORT}" == "FT" ]]; then
    PROJECT=${PROJECT_FT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/Claustrum_Connectivity_BEST_Adults
    GROUP=FT
    OUT_CSV=${ANALYSIS_DIR}/tract_metrics/claustrum_struct_vol_FT.csv

else
    echo "ERROR: COHORT must be PT or FT" >&2; exit 1
fi

SEG_REL=Claustrum/intermediaries/claustrum.nii.gz   # bilateral segmentation
HEMI_REL=Masks/structural                           # contains L_hemi / R_hemi

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

# =============================================================================

echo "COHORT      : ${COHORT}"
echo "SUBJECTS_DIR: ${SUBJECTS_DIR}"
echo "OUT_CSV     : ${OUT_CSV}"
echo ""

echo "subject_id,group,hemi,struct_vox,struct_vol,vox_size_mm3,seg_min,seg_max" > "${OUT_CSV}"

n_missing=0

for SUBJ_PATH in "${SUBJECTS_DIR}"/*/ ; do
    ID=$(basename "${SUBJ_PATH}")

    SEG="${SUBJ_PATH}/${SEG_REL}"
    if [[ ! -f "${SEG}" ]]; then
        echo "  WARN no segmentation: ${ID}"
        n_missing=$(( n_missing + 1 )); continue
    fi

    read -r seg_min seg_max <<< "$(fslstats "${SEG}" -R)"

    for HEMI in L R; do

        HEMI_MASK="${SUBJ_PATH}/${HEMI_REL}/${HEMI}_hemi_str.nii.gz"
        if [[ ! -f "${HEMI_MASK}" ]]; then
            echo "  WARN no ${HEMI}_hemi mask: ${ID}"
            n_missing=$(( n_missing + 1 )); continue
        fi

        SIDE="${TMP}/${ID}_${HEMI}"
        fslmaths "${SEG}" -mas "${HEMI_MASK}" -bin "${SIDE}" 2>/dev/null || {
            echo "  WARN fslmaths failed (grid mismatch?): ${ID} ${HEMI}"
            n_missing=$(( n_missing + 1 )); continue
        }

        read -r vox vol <<< "$(fslstats "${SIDE}" -V)"
        voxsize=$(awk -v v="${vox}" -v V="${vol}" 'BEGIN{ if (v>0) printf "%.4f", V/v; else print "NA" }')

        echo "${ID},${GROUP},${HEMI},${vox},${vol},${voxsize},${seg_min},${seg_max}" >> "${OUT_CSV}"
        rm -f "${SIDE}".nii.gz
    done

    echo "${ID}"
done