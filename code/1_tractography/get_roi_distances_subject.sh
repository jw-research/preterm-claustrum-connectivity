#!/bin/bash
#
# Subject-level Euclidean distance between claustrum and target ROI centroids
#
# Usage: edit COHORT (PT or FT), then run ./get_roi_distances_subject.sh

COHORT=PT          # PT or FT

# paths
PROJECT_PT=/path/to/project_PT
PROJECT_FT=/path/to/project_FT
ANALYSIS_DIR=/path/to/analysis

if [[ "${COHORT}" == "PT" ]]; then
    PROJECT=${PROJECT_PT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/BEST_subjects_PT
    GROUP=PT
    OUT_CSV=${ANALYSIS_DIR}/3_1_1_distance/ROI_distances_subj_PT.csv

elif [[ "${COHORT}" == "FT" ]]; then
    PROJECT=${PROJECT_FT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/Claustrum_Connectivity_BEST_Adults
    GROUP=FT
    OUT_CSV=${ANALYSIS_DIR}/3_1_1_distance/ROI_distances_subj_FT.csv

else
    echo "ERROR: COHORT must be PT or FT" >&2; exit 1
fi

TARGETS=(AC_Occ AC_Temp AC_Par AC_PFC C_ant C_pos PC_mot PC_sens PC_vis PC_aud SC_Hip)

# =============================================================================

echo "COHORT      : ${COHORT}"
echo "SUBJECTS_DIR: ${SUBJECTS_DIR}"
echo "OUT_CSV     : ${OUT_CSV}"
echo "Group        : ${GROUP}"
echo ""

echo "subject_id,group,seed_hemi,target,target_hemi,dist_centroid" > "${OUT_CSV}"

for SUBJ_PATH in "${SUBJECTS_DIR}"/*/ ; do
    ID=$(basename "${SUBJ_PATH}")
    for SEED_HEMI in L R; do
        SEED_MASK="${SUBJ_PATH}/Claustrum/${SEED_HEMI}_claustrum_rem.nii.gz"
        [[ -f "${SEED_MASK}" ]] || continue
        read -r sx sy sz <<< "$(fslstats "${SEED_MASK}" -c)"

        for TARGET in "${TARGETS[@]}"; do
            TARGET_MASK="${SUBJ_PATH}/Masks/${TARGET}_${SEED_HEMI}.nii.gz"
            [[ -f "${TARGET_MASK}" ]] || continue
            read -r tx ty tz <<< "$(fslstats "${TARGET_MASK}" -c)"
            dist=$(awk -v x1="$sx" -v y1="$sy" -v z1="$sz" -v x2="$tx" -v y2="$ty" -v z2="$tz" \
                   'BEGIN{printf "%.3f", sqrt((x1-x2)^2+(y1-y2)^2+(z1-z2)^2)}')
            echo "${ID},${GROUP},${SEED_HEMI},${TARGET},${SEED_HEMI},${dist}" >> "${OUT_CSV}"
        done
    done
    echo "${ID}"
done