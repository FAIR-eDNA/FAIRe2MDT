## Changelog

All notable changes to the FAIRe2MDT.R will be documented in this file.

### [v1.1.0] - 2025-07-16
- Removed the `assay_name` column from the sample metadata sheet, as it was duplicated in both the sample and study sheets. While the `assay_name` field is necessary in the FAIRe format to support multiple assays within a single dataset, the MDT format assumes each dataset corresponds to a single assay and therefore does not require this field in the sample sheet.
- Renamed `samp_name` to `id` in the sample sheet
- Renamed `seq_id` to `id` in the taxonomy sheet

### [v1.0.0] - 2025-01-23
- Initial public release of FAIRe2MDT tool

# Note:
This script is versioned independently from the [FAIRe metadata checklist](https://github.com/FAIR-eDNA/FAIRe_checklist), which uses semantic versions like `v1.0`, `v1.0.2`.  
Refer to this changelog for the script’s own version history.
