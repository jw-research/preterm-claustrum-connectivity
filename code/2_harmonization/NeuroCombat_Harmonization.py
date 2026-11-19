# -*- coding: utf-8 -*-
"""
ComBat harmonization (neuroCombat) of claustrum connectivity across scanners (BLS cohort).
Batch = scanner; sex and group (categorical) and age at scan (continuous) are preserved.

Author: Jil Wendt
"""

from neuroCombat import neuroCombat
import pandas as pd

IN_CSV = 'path/to/analysis_CP_ipsi_unharmonized.csv'
OUT_CSV = 'path/to/analysis_CP_ipsi_harmonized.csv'

# 1. Load data
data = pd.read_csv(IN_CSV, delimiter=';', decimal = ',', skipinitialspace=True)

# 2. Specify covariate and metadata columns
covariate_columns = ['ScannerID', 'Sex', 'Age_at_scan', 'Groupcode']
metadata_columns = ['Subject', 'ID']

# 3. Identify outcome/feature columns (all that start with 'CP_')
feature_columns = [col for col in data.columns if col.startswith('CP_')]

# 4. Extract feature data, covariates and metadata
data_array = data[feature_columns].values
covars = data[covariate_columns]
metadata = data[metadata_columns]

assert data_array.shape[0] == covars.shape[0], "Mismatch in rows between data and covariates!"

# 5. Prepare covariates DataFrame for neuroCombat
covars_df = pd.DataFrame({
    'batch': covars['ScannerID'].values,
    'sex': covars['Sex'].values,
    'age': covars['Age_at_scan'].values,
    'groupcode': covars['Groupcode'].values
})

# 6. Run ComBat harmonization
combat_result = neuroCombat(
    dat=data_array.T,  # neuroCombat expects features as rows, subjects as columns
    covars=covars_df,
    batch_col='batch',
    categorical_cols=['sex', 'groupcode'],
    continuous_cols=['age']
)

# 7. Get harmonized data and transpose back
harmonized_data = combat_result["data"].T  # transpose back to samples as rows

# 8. Create a DataFrame with harmonized data and add metadata/covariates back
harmonized_df = pd.DataFrame(harmonized_data, columns=feature_columns)

for col in metadata_columns + covariate_columns:
    harmonized_df.insert(0, col, data[col].values)

# 9. Save to CSV
harmonized_df.to_csv(OUT_CSV, index=False, sep=';')
