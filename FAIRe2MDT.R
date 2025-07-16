### FAIRe2MDT.R
# Description: This script converts metabarcoding data in the FAIRe format for submission to GBIF via the Metabarcoding Data Toolkit (MDT) (https://www.gbif.org/metabarcoding).
# Script version: 1.1.0
# Last updated: 2025-07-16
#
# ----------------------------------------------------------
# Script Version History (independent of checklist versions)
# ----------------------------------------------------------
# v1.1.0 - 2025-07-16
# * Removed the assay_name column from the sample metadata sheet, as it was duplicated in both the sample and study sheets. While the assay_name field is necessary in the FAIRe format to support multiple assays within a single dataset, the MDT format assumes each dataset corresponds to a single assay and therefore does not require this field in the sample sheet.
# * Renamed samp_name to id in the sample sheet
# * Renamed seq_id to id in the taxonomy sheet
#
# v1.0.0 - 2025-01-23
# * Initial public release of FAIRe2MDT tool
#
# Note: For projects with multiple assays or sequencing runs, users must execute this script separately for each assay or run. 
# The script generates an Excel file named <project_id>_<assay_name>_<seq_run_id>_MDTfmt.xlsx
#
# The below example input files are provided within the repository (https://github.com/FAIR-eDNA/FAIR-eDNA.github.io/tree/main/docs/examples/metabarcoding/IOT-eDNA). 
# IOT-eDNA.xlsx
# otuFinal_IOT-eDNA_COILeray_Library_2021.xlsx
# taxaFinal_IOT-eDNA_COILeray_Library_2021.xlsx


# Install required packages if not already installed ----------------------------------------------------
packages <- c("readxl", "openxlsx", "dplyr", "tibble") 
# Load in libraries
for (i in packages) {
  if (!require(i, character.only = TRUE)) {
    install.packages(i, dependencies = TRUE)
    library(i, character.only = TRUE)
  }
}

# Defined by a user ----------------------------------------------------

## 1.   set Working directory of your INPUT files
#e.g., 
setwd(".")

## 2. Define assay name and sequencing run ID 
# Note: They must match with assay_name and seq_run_id in your metadata. 
#e.g., 
assay <- "COILeray" 
seq_run <- "Library_2021" 

## 3. Read in INPUT tables
#e.g., 
Project <- read_excel("IOT-eDNA.xlsx", sheet = "projectMetadata", col_names = TRUE) 
Samples <- read_excel("IOT-eDNA.xlsx", sheet = "sampleMetadata", col_names = FALSE) 
expRun <- read_excel("IOT-eDNA.xlsx", sheet = "experimentRunMetadata", col_names = FALSE)
otu <- read_excel("otuFinal_IOT-eDNA_COILeray_Library_2021.xlsx", sheet = "otuFinal", col_names = TRUE)
taxa <- read_excel("taxaFinal_IOT-eDNA_COILeray_Library_2021.xlsx", sheet = "taxaFinal", col_names = FALSE)


# Run the below code ----------------------------------------------------

#### Correct the tables to match with the MDT format
## Project
Project <- Project %>% 
  select(-(1:(which(names(Project) == "term_name") - 1))) # Remove the first few cols (up to term_name)
#change col_names to match with MDT template
Project <- Project %>%
  rename("term" = "term_name", "value" = "project_level")

## Samples
Samples <- Samples %>%
  slice(-(1:(which(Samples[[1]] == "samp_name") - 1))) %>%  # Remove rows above 'sample_name'
  rename_with(~ as.character(Samples[which(Samples[[1]] == "samp_name"), ])) %>%  # Set the 'sample_name' row as column names
  slice(-1)  %>% # Remove the 'sample_name' row now used as column names
  rename("id" = "samp_name")

## expRun
expRun <- expRun %>%
  slice(-(1:(which(expRun[[1]] == "samp_name") - 1))) %>%  
  rename_with(~ as.character(expRun[which(expRun[[1]] == "samp_name"), ])) %>% 
  slice(-1) %>%
  rename("id" = "samp_name")

## otu
otu <- otu %>%
  column_to_rownames(var = "seq_id")

## taxa
taxa <- taxa %>%
  slice(-(1:(which(taxa[[1]] == "seq_id") - 1))) %>%  # Remove rows above 'seq_id'
  rename_with(~ as.character(taxa[which(taxa[[1]] == "seq_id"), ])) %>%  # Set the 'seq_id' row as column names
  slice(-1) %>%
  rename("id" = "seq_id") 

#### Format Project if multiple assays were applied within a project
if (ncol(Project) > 2) {
  assay_col <- which(Project[which(Project$term == 'assay_name'),]==assay)
  Project$value <- ifelse(is.na(Project$value), Project[,assay_col][[1]], Project$value) #Move the entries from assay_col to value
  Project[which(Project$term == 'assay_name'),'value'] = assay 
  Project <- Project[,c('term', 'value')] # remove the assay specific columns
} 

#### Combine Samples and expRun
filtered_expRun <- expRun %>%
  filter(
    grepl(assay, assay_name, ignore.case = TRUE) & 
      grepl(seq_run, seq_run_id, ignore.case = TRUE)
  )
filtered_Samples <- Samples %>% 
  filter(id %in% filtered_expRun$id)
filtered_Samples$assay_name <- NULL #Remove assay_name from here as it's also in expRun

Samples_expRun <- filtered_Samples %>% 
  inner_join(filtered_expRun, by = "id")

unique(Samples_expRun$assay_name)
unique(Samples_expRun$seq_run_id)


##### Remove terms with no entries
Project <- Project %>%
  filter(!is.na(value))
Samples_expRun <- Samples_expRun %>%
  select(where(~ any(!is.na(.))))
expRun <- expRun %>%
  select(where(~ any(!is.na(.))))
taxa <- taxa %>%
  select(where(~ any(!is.na(.))))

##### Remove assay_name from Samples_expRun
# Note: While the assay_name field is necessary in the FAIRe sample/experimentRun metadata format to support multiple assays within a single dataset, 
# the MDT format assumes each dataset corresponds to a single assay and therefore does not require this field in the sample sheet.
Samples_expRun <- Samples_expRun %>%
  select(-"assay_name")

#### Output an Excel file
project_id<- Project[which(Project$term=='project_id'),'value'][[1]]
output_filename <- paste(project_id, assay, seq_run, 'MDTfmt.xlsx', sep='_')
# Create a new workbook
MDT_File <- createWorkbook()

# Add sheet and write data
addWorksheet(MDT_File, "Study")
writeData(MDT_File, "Study", Project)

addWorksheet(MDT_File, "Samples")
writeData(MDT_File, "Samples", Samples_expRun)

addWorksheet(MDT_File, "Taxonomy")
writeData(MDT_File, "Taxonomy", taxa)

addWorksheet(MDT_File, "OTU_table")
writeData(MDT_File, "OTU_table", otu, rowNames = TRUE)

# Save the combined workbook
saveWorkbook(MDT_File, output_filename, overwrite = TRUE)

