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

#check if Excel outputs are required
makeSheet <- menu(c("Yes", "No"),
                  title = "Do you wish to generate the Excel outputs?")

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
    "magrittr",
    "tcltk",
    "DT",
    "nhsbsa-data-analytics/nhsbsaR",
    "nhsbsa-data-analytics/nhsbsaExternalData",
    "nhsbsa-data-analytics/accessibleTables"
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
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
  dplyr::filter(MONTH_TYPE %in% c("FY")) |>
  dplyr::select(YEAR_DESC) |>
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
  distinct() |>
  collect() |>
  pull()

log_print("Max DWH FY pulled", hide_notes = TRUE)
log_print(max_dw_fy, hide_notes = TRUE)


#get max cy from pca table
max_dw_cy <- dplyr::tbl(con,
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
  dplyr::filter(MONTH_TYPE %in% c("CY")) |>
  dplyr::select(YEAR_DESC) |>
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
  distinct() |>
  collect() |>
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

# 5. pull data from warehouse if more recent data is available ------
#check max DWH fy against max data fy and pull data if different
#get max fy from latest data
max_data_fy <- recent_file_nat_fy |>
  dplyr::select(YEAR_DESC) |>
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
  distinct() |>
  pull()

if (max_dw_fy <= max_data_fy) {
  #read most recent data to use
  print("No new data in DWH, using most recent saved data")
  
  #national data by fy
  nat_data_fy <- rownames(file.info(
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
  nat_data_fy <- vroom::vroom(nat_data_fy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))
  
  #national data by cy
  nat_data_cy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "nat_data_cy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "nat_data_cy"
    )
  )$mtime)]
  
  #read recent data
  nat_data_cy <- vroom::vroom(nat_data_cy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))
  
  #stp data by fy
  stp_data_fy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "stp_data_fy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "stp_data_fy"
    )
  )$mtime)]
  
  #read recent data
  stp_data_fy <- vroom::vroom(stp_data_fy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))
  
  #stp data by cy
  stp_data_cy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "stp_data_cy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "stp_data_cy"
    )
  )$mtime)]
  
  #read recent data
  stp_data_cy <- vroom::vroom(stp_data_cy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))
  
  log_print("Data pulled from most recent saved data", hide_notes = TRUE)
} else {
  # Pull data from DWH and save to Y drive
  nat_data_fy <-
    extract_nat_data(con, year_type = "financial", year = max_dw_fy)
  nat_data_cy <-
    extract_nat_data(con, year_type = "calendar", year = max_dw_cy)
  
  stp_data_fy <-
    extract_stp_data(con, year_type = "financial", year = max_dw_fy)
  stp_data_cy <-
    extract_stp_data(con, year_type = "calendar", year = max_dw_cy)
  
  #save new extracts to Y drive
  save_data(nat_data_cy,
            dir = "Y:/Official Stats/PCA",
            filename = "nat_data_cy",
            quote = TRUE)
  
  save_data(nat_data_fy,
            dir = "Y:/Official Stats/PCA",
            filename = "nat_data_fy",
            quote = TRUE)
  
  save_data(stp_data_cy,
            dir = "Y:/Official Stats/PCA",
            filename = "stp_data_cy",
            quote = TRUE)
  
  save_data(stp_data_fy,
            dir = "Y:/Official Stats/PCA",
            filename = "stp_data_fy",
            quote = TRUE)
  
  log_print("New data pulled from warehouse and saved to Y drive", hide_notes = TRUE)
}

# 6. build variable for max and prev fy to use in headers ------
#get max fy from latest data
max_data_fy <- nat_data_fy |>
  dplyr::filter(MONTH_TYPE %in% c("FY")) |>
  dplyr::select(YEAR_DESC) |>
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
  distinct() |>
  pull()

log_print(paste0("max_data_fy built as: ", max_data_fy), hide_notes = TRUE)

#get max fy minus 1 from latest data
max_data_fy_minus_1 <-
  paste0(as.numeric(substr(max_data_fy, 1, 4)) - 1,
         "/",
         as.numeric(substr(max_data_fy, 6, 9)) - 1)

log_print(paste0("max_data_fy_minus_1 built as: ", max_data_fy_minus_1), hide_notes = TRUE)


#get max cy from latest data
max_data_cy <- nat_data_cy |>
  dplyr::filter(MONTH_TYPE %in% c("CY")) |>
  dplyr::select(YEAR_DESC) |>
  dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
  distinct() |>
  pull()

log_print(paste0("max_data_cy built as: ", max_data_cy), hide_notes = TRUE)

# 7. create aggregate data for main tables ------

#national data
nat_data_fy_agg <- pca_aggregations(nat_data_fy, area = "national")
log_print("national FY data aggregated", hide_notes = TRUE)
nat_data_cy_agg <- pca_aggregations(nat_data_cy, area = "national")
log_print("national CY data aggregated", hide_notes = TRUE)

#ICB data
stp_data_fy_agg <- pca_aggregations(stp_data_fy, area = "ICB")
log_print("ICB FY data aggregated", hide_notes = TRUE)
stp_data_cy_agg <- pca_aggregations(stp_data_cy, area = "ICB")
log_print("ICB CY data aggregated", hide_notes = TRUE)


# 8. create Excel outputs if required ------
if(makeSheet == 1) {
  print("Generating Excel outputs")
  source("./functions/excelOutputs.R")
  log_print("Excel outputs generated", hide_notes = TRUE)
} else {
  print("Excel outputs will not be generated")
  log_print("Excel outputs not generated", hide_notes = TRUE)
}

# xxx. disconnect from DWH  ---------
DBI::dbDisconnect(con)
log_print("Disconnected from DWH", hide_notes = TRUE)

#close log
logr::log_close()
