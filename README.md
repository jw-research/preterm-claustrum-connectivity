# Aberrant claustrum connectivity in preterm-born neonates and adults

Analysis code and result tables for *Aberrant claustrum connectivity in preterm-born neonates and adults* by Wendt & Ayyildiz et al., 2026, under revision.

This code documents the analyses reported in the paper and is shared for transparency and reproducibility. It is not a maintained, general-purpose pipeline; scripts assume the input file structure and variable names of our datasets and may need adapting for other data.


## Structure
- `code/1_tractography/` - probabilistic claustrum tractography and connectivity metrics (FSL)
- `code/2_harmonization/` - ComBat harmonization across scanners (BLS cohort)
- `code/3_main_analyses/` - sample characteristics, group comparisons, GLMs, effect sizes and figures
- `code/4_control_analyses/` - supplementary control and robustness analyses
- `results/` - complete result tables (CSV). Each script header lists its output files and the corresponding manuscript tables and figures.

## Basic Requirements
- FSL 6.0.1 (bedpostX, probtrackx2 with GPU support)
- Python 3
- R 4.2.0
- Some scripts use outputs of others; required inputs are listed in each script header
- Project paths need to be set at the top of the shell and Python scripts before running

## Data
Input files are expected in `data/` (not included). Neonatal data are from the second data release of the Developing Human Connectome Project (dHCP; restricted access via the NIMH Data Archive). Adult data from the Bavarian Longitudinal Study (BLS) are not publicly available due to data privacy regulations; processed data can be made available upon reasonable request. dHCP claustrum masks (native T2-weighted structural space) are also available on request to researchers with a dHCP data use agreement.

## License and citation
Code: MIT License (see `LICENSE`). Result tables: CC BY 4.0. If you use this code, please cite the paper above.

## Acknowledgements
dHCP data were provided by the developing Human Connectome Project, KCL-Imperial-Oxford Consortium funded by the European Research Council under the European Union Seventh Framework Programme (FP/2007-2013) / ERC Grant Agreement no. [319456]. We are grateful to all dHCP investigators, participants and families generously supported this trial. We also thank all participants and families of the Bavarian Longitudinal Study and all current and former members of the BLS group who contributed to study organization, recruitment, data collection and data management.
