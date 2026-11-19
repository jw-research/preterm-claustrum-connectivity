#!/bin/bash
#
# Extract claustrum-cortex tractography metrics into a csv
#
# Usage: edit COHORT (PT or FT), then run ./get_tract_metrics.sh

COHORT=PT          # PT or FT

# paths
PROJECT_PT=/path/to/project_PT
PROJECT_FT=/path/to/project_FT
DERIV_DIR=/path/to/derivatives
ANALYSIS_DIR=/path/to/analyses

if [[ "${COHORT}" == "PT" ]]; then

    PROJECT=${PROJECT_PT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/BEST_subjects_PT
    TRACT_DIR_L=${DERIV_DIR}/Probtrackx_v6-0-1_PT
    TRACT_DIR_R=${DERIV_DIR}/Probtrackx_v6-0-1_PT
    CONTROL_TRACT_DIR=${DERIV_DIR}/Probtrackx_v6-0-1_PT
    GROUP=PT
    OUT_CSV=${ANALYSIS_DIR}/tract_metrics/metrics_long_PT.csv

elif [[ "${COHORT}" == "FT" ]]; then

    PROJECT=${PROJECT_FT}
    SUBJECTS_DIR=${PROJECT}/1_Subjects/Claustrum_Connectivity_BEST_Adults
    TRACT_DIR_L=${DERIV_DIR}/Probtrackx_v6-0-1_FT
    TRACT_DIR_R=${DERIV_DIR}/Probtrackx_v6-0-1_FT
    CONTROL_TRACT_DIR=${DERIV_DIR}/Probtrackx_v6-0-1_FT
    GROUP=FT
    OUT_CSV=${ANALYSIS_DIR}/tract_metrics/metrics_long_FT.csv

else
    echo "ERROR: COHORT must be PT or FT" >&2; exit 1
fi

CONTROL_MASK_DIR=Masks          # subfolder inside each subject dir

SEEDS=(claustrum putamen insula)

SEEDS_PER_VOX=5000
SCALE=8

TARGETS=(AC_Occ AC_Temp AC_Par AC_PFC C_ant C_pos PC_mot PC_sens PC_vis PC_aud SC_Hip)

# =============================================================================

echo "COHORT      : ${COHORT}"
echo "SUBJECTS_DIR: ${SUBJECTS_DIR}"
echo "TRACT_DIR_L : ${TRACT_DIR_L}"
echo "TRACT_DIR_R : ${TRACT_DIR_R}"
echo "CONTROL_DIR : ${CONTROL_TRACT_DIR}"
echo "SEEDS       : ${SEEDS[*]}"
echo "OUT_CSV     : ${OUT_CSV}"
echo ""

echo "subject_id,group,seed_region,seed_hemi,target,target_hemi,tract_type,waytotal,seed_vox,seed_vol,target_vol,total_vol,CP,CD" > "${OUT_CSV}"

n_missing=0

for SUBJ_PATH in "${SUBJECTS_DIR}"/*/ ; do
    ID=$(basename "${SUBJ_PATH}")
    echo "${ID}"

    for SEED in "${SEEDS[@]}"; do

        for SEED_HEMI in L R; do

            if [[ "${SEED_HEMI}" == "L" ]]; then
                CLA_TRACT_DIR="${TRACT_DIR_L}"
            else
                CLA_TRACT_DIR="${TRACT_DIR_R}"
            fi

            case "${SEED}" in
                claustrum)
                    SEED_MASK="${SUBJ_PATH}/Claustrum/${SEED_HEMI}_claustrum_rem.nii.gz"
                    REGION_PREFIX="${SEED_HEMI}_Claustrum_2_"
                    SEED_TRACT_DIR="${CLA_TRACT_DIR}"
                    ;;
                putamen)
                    SEED_MASK="${SUBJ_PATH}/${CONTROL_MASK_DIR}/SC_BG_Str_put_${SEED_HEMI}.nii.gz"
                    REGION_PREFIX="${SEED_HEMI}_Putamen_2_"
                    SEED_TRACT_DIR="${CONTROL_TRACT_DIR}"
                    ;;
                insula)
                    SEED_MASK="${SUBJ_PATH}/${CONTROL_MASK_DIR}/Ins_${SEED_HEMI}.nii.gz"
                    REGION_PREFIX="${SEED_HEMI}_Insula_2_"
                    SEED_TRACT_DIR="${CONTROL_TRACT_DIR}"
                    ;;
                *)
                    echo "  ERROR: unknown seed ${SEED}" >&2; exit 1 ;;
            esac

            [[ -f "${SEED_MASK}" ]] || { echo "  WARN no ${SEED} seed ${SEED_HEMI}"; continue; }

            seed_out=$(fslstats "${SEED_MASK}" -V)
            seed_vox=$(cut -d ' ' -f1 <<<"${seed_out}")
            seed_vol=$(cut -d ' ' -f2 <<<"${seed_out}" | cut -d '.' -f1)
            seeded=$(( SEEDS_PER_VOX * seed_vox ))

            for TARGET_HEMI in L R; do
                [[ "${TARGET_HEMI}" == "${SEED_HEMI}" ]] || continue  # ipsilateral only
                TYPE=ipsi

                for TARGET in "${TARGETS[@]}"; do

                    REGION="${REGION_PREFIX}${TARGET}_${TARGET_HEMI}"
                    WAYFILE="${SEED_TRACT_DIR}/${REGION}/${ID}/waytotal"
                    TARGET_MASK="${SUBJ_PATH}/Masks/${TARGET}_${TARGET_HEMI}.nii.gz"

                    if [[ ! -f "${WAYFILE}" || ! -f "${TARGET_MASK}" ]]; then
                        n_missing=$(( n_missing + 1 ))
                        continue
                    fi

                    waytotal=$(tr -d '[:space:]' < "${WAYFILE}")

                    target_out=$(fslstats "${TARGET_MASK}" -V)
                    target_vol=$(cut -d ' ' -f2 <<<"${target_out}" | cut -d '.' -f1)

                    total_vol=$(( target_vol + seed_vol ))
                    CP=$(bc <<<"scale=${SCALE};${waytotal}/${seeded}")
                    CD=$(bc <<<"scale=${SCALE};${waytotal}/${total_vol}")

                    echo "${ID},${GROUP},${SEED},${SEED_HEMI},${TARGET},${TARGET_HEMI},${TYPE},${waytotal},${seed_vox},${seed_vol},${target_vol},${total_vol},${CP},${CD}" >> "${OUT_CSV}"
                done
            done
        done
    done
done