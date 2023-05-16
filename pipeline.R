### Pipeline to run PCA annual publication
# clear environment
rm(list = ls())

# source functions
# this is only a temporary step until all functions are built into packages
source("./functions/functions.R")

# 1. Setup --------------------------------------------
# load GITHUB_KEY if available in environment or enter if not

if(Sys.getenv("GITHUB_PAT") == "") {
  usethis::edit_r_environ()
  stop("You need to set your GITHUB_PAT = YOUR PAT KEY in the .Renviron file which pops up. Please restart your R Studio after this and re-run the pipeline.")
}

# load GITHUB_KEY if available in environment or enter if not

if(Sys.getenv("DB_DWCP_USERNAME") == "") {
  usethis::edit_r_environ()
  stop("You need to set your DB_DWCP_USERNAME = YOUR DWCP USERNAME and  DB_DWCP_PASSWORD = YOUR DWCP PASSWORD in the .Renviron file which pops up. Please restart your R Studio after this and re-run the pipeline.")
}

#install nhsbsaUtils package first as need check_and_install_packages()
devtools::install_github("nhsbsa-data-analytics/nhsbsaUtils",
                       auth_token = Sys.getenv("GITHUB_PAT"))

library(nhsbsaUtils)

#install and library packages
req_pkgs <-
  c(
    "dplyr",
    "stringr",
    "data.table",
    "yaml",
    "openxlsx",
    "rmarkdown",
    "logr",
    "highcharter",
    "lubridate",
    "vroom",
    "tidyverse",
    "kableExtra",
    "devtools",
    "yaml",
    "logr",
    "DBI",
    "geojsonsf",
    "sf",
    "nhsbsa-data-analytics/nhsbsaR",
    "nhsbsa-data-analytics/nhsbsaExternalData"
  )

#library/install packages as required
nhsbsaUtils::check_and_install_packages(req_pkgs)

# set up logging
lf <- logr::log_open(paste0("Y:/Official Stats/PCA/log/pca_log", format(Sys.time(), "%d%m%y%H%M%S"), ".log"))

# load config
config <- yaml::yaml.load_file("config.yml")
log_print("Config loaded", hide_notes = TRUE)
log_print(config, hide_notes = TRUE)

# load options
nhsbsaUtils::publication_options()
log_print("Options loaded", hide_notes = TRUE)

# 2. connect to DWH and pull max CY/FY  ---------
#build connection to warehouse
con <- nhsbsaR::con_nhsbsa(
  dsn = "FBS_8192k",
  driver = "Oracle in OraClient19Home1",
  "DWCP"
)

#get max fy from pca table
max_dw_fy <- dplyr::tbl(con,
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) %>%
  dplyr::filter(MONTH_TYPE %in% c("FY")) %>%
  dplyr::select(YEAR_DESC) %>%
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) %>%
  distinct() %>%
  collect %>%
  pull()

log_print("Max DWH FY pulled", hide_notes = TRUE)
log_print(max_dw_fy, hide_notes = TRUE)


#get max cy from pca table
max_dw_cy <- dplyr::tbl(con,
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) %>%
  dplyr::filter(MONTH_TYPE %in% c("CY")) %>%
  dplyr::select(YEAR_DESC) %>%
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) %>%
  distinct() %>%
  collect %>%
  pull()

log_print("Max DWH CY pulled", hide_notes = TRUE)
log_print(max_dw_cy, hide_notes = TRUE)

# 3. load latest data  ---------
#load latest available data
#get most recent monthly file
recent_file_nat_fy <- rownames(file.info(
  list.files(
    "Y:/Official Stats/PCA/data",
    full.names = T,
    pattern = "nat_data_fy"
  )
))[which.max(file.info(
  list.files(
    "Y:/Official Stats/PCA/data",
    full.names = T,
    pattern = "nat_data_fy"
  )
)$mtime)]

#read recent data
recent_file_nat_fy <- vroom::vroom(recent_file_nat_fy,
                                   #read snomed code as character
                                   col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))

log_print("Latest saved data loaded", hide_notes = TRUE)
log_print(head(recent_file_nat_fy), hide_notes = TRUE)

# 4. load reference data  ---------

#map data
icb_geo_data <- nhsbsaExternalData::icb_geo_data()
log_print("Geo data loaded", hide_notes = TRUE)

#lookups
icb_lsoa_lookup <- nhsbsaExternalData::icb_lsoa_lookup()
log_print("Lookup data loaded", hide_notes = TRUE)

#population data
imd_population <- nhsbsaExternalData::imd_population()
lsoa_population_overall <- nhsbsaExternalData::lsoa_population(group = "Overall")
en_ons_national_pop <- nhsbsaExternalData::ons_national_pop(year = c(2014:as.numeric(max_dw_cy)), area = "ENPOP")
sc_ons_national_pop <- nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "SCPOP")
ni_ons_national_pop <- nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "NIPOP")
wa_ons_national_pop <- nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "WAPOP")
log_print("Population data loaded", hide_notes = TRUE)

#pca data
sc_pca <- nhsbsaExternalData::scottish_pca_extraction(link = config$scotland_pca)
ni_pca <- northern_irish_pca_extraction_new(link = config$ni_pca)
wa_pca <- nhsbsaExternalData::wales_pca_extraction(file_path = config$wa_pca)
log_print("Dev nation PCA data loaded", hide_notes = TRUE)

# xxx. disconnect from DWH  ---------
DBI::dbDisconnect(con)
log_print("Disconnected from DWH", hide_notes = TRUE)

#close log
logr::log_close()
