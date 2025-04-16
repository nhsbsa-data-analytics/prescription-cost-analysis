### Pipeline to run PCA annual publication
# clear environment
rm(list = ls())

# source functions
# get all .R files in the functions sub-folder
function_files <- list.files(path = "functions", pattern = "\\.R$")

# loop over function_files to source them all
for (file in function_files) {
  source(file.path("functions", file))
}

# 1. Setup --------------------------------------------
# load GITHUB_KEY if available in environment or enter if not

if (Sys.getenv("GITHUB_PAT") == "") {
  usethis::edit_r_environ()
  stop(
    "You need to set your GITHUB_PAT = YOUR PAT KEY in the .Renviron file which pops up. Please restart your R Studio after this and re-run the pipeline."
  )
}

# load GITHUB_KEY if available in environment or enter if not

if (Sys.getenv("DB_DWCP_USERNAME") == "") {
  usethis::edit_r_environ()
  stop(
    "You need to set your DB_DWCP_USERNAME = YOUR DWCP USERNAME and  DB_DWCP_PASSWORD = YOUR DWCP PASSWORD in the .Renviron file which pops up. Please restart your R Studio after this and re-run the pipeline."
  )
}

#check if Excel outputs are required
makeSheet <- menu(c("Yes", "No"),
                  title = "Do you wish to generate the Excel outputs?")

# install and library devtools
install.packages("devtools")
library(devtools)

#install nhsbsaUtils package first as need check_and_install_packages()
devtools::install_github(
  "nhsbsa-data-analytics/nhsbsaUtils",
  auth_token = Sys.getenv("GITHUB_PAT"),
  dependencies = TRUE
)

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
    "htmltools",
    "nhsbsa-data-analytics/nhsbsaR",
    "nhsbsa-data-analytics/nhsbsaExternalData",
    "nhsbsa-data-analytics/accessibleTables",
    "nhsbsa-data-analytics/nhsbsaVis"
  )

#library/install packages as required
nhsbsaUtils::check_and_install_packages(req_pkgs)

# set up logging
lf <-
  logr::log_open(paste0(
    "Y:/Official Stats/PCA/log/pca_log",
    format(Sys.time(), "%d%m%y%H%M%S"),
    ".log"
  ))

# load config
config <- yaml::yaml.load_file("config.yml")
log_print("Config loaded", hide_notes = TRUE)
log_print(config, hide_notes = TRUE)

# load options
nhsbsaUtils::publication_options()
log_print("Options loaded", hide_notes = TRUE)

# 2. connect to DWH and pull max CY/FY  ---------
#build connection to warehouse
con <- nhsbsaR::con_nhsbsa(dsn = NULL,
                           driver = "Oracle in OraClient19Home1",
                           database = "DWCP")

#get max fy from pca table
max_dw_fy <- get_max_dw_fy(con)
log_print("Max DWH FY pulled", hide_notes = TRUE)
log_print(max_dw_fy, hide_notes = TRUE)

#get max cy from pca table
max_dw_cy <- get_max_dw_cy(con)

log_print("Max DWH CY pulled", hide_notes = TRUE)
log_print(max_dw_cy, hide_notes = TRUE)

# 3. load latest data  ---------
#load latest available data
#read most recent monthly file
recent_file_nat_fy <- get_recent_file_nat_fy()

log_print("Latest saved data loaded", hide_notes = TRUE)
log_print(head(recent_file_nat_fy), hide_notes = TRUE)

# 4. load reference data  ---------

#map data
icb_geo_data <-
  nhsbsaExternalData::icb_geo_data(
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Integrated_Care_Boards_April_2023_EN_BSC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson",
    SUB_GEOGRAPHY_CODE = "ICB23CD",
    SUB_GEOGRAPHY_NAME = "ICB23NM"
  )
log_print("Geo data loaded", hide_notes = TRUE)

#icb population
temp1 <- tempfile()
icb_population_raw <-
  utils::download.file(url = "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/clinicalcommissioninggroupmidyearpopulationestimates/mid2021andmid2022/sapehealthgeogstablefinal.xlsx",
                       temp1,
                       mode = "wb")

icb_population <- readxl::read_xlsx(temp1,
                                    sheet = 9,
                                    range = "A4:GG110",
                                    col_names = TRUE) |>
  group_by(`ICB 2023 Name`, `ICB 2023 Code`) |>
  summarise(POP = sum(Total),
            .groups = "drop") |>
  rename("ICB_NAME" = 1,
         "ICB_LONG_CODE" = 2,
         "POP" = 3)

icb_code_lookup <-
  dplyr::bind_rows(
    # ICB
    sf::read_sf(
      "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/ICB_APR_2023_EN_NC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
    ) |>
      dplyr::select(ICB_CODE = "ICB23CDH",
                    ICB_LONG_CODE = "ICB23CD")
  ) |>
  data.frame() |>
  select(-geometry)

icb_pop <- icb_code_lookup |>
  left_join(icb_population)

#national popualtion
en_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = c(2014:as.numeric(max_dw_cy)), area = "ENPOP")
sc_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "SCPOP")
ni_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "NIPOP")
wa_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "WAPOP")

log_print("Population data loaded", hide_notes = TRUE)

#pca data
sc_pca <-
  nhsbsaExternalData::scottish_pca_extraction(link = config$scotland_pca)
ni_pca <-
  northern_irish_pca_extraction_2024(file_path = config$ni_pca)
wa_pca <-
  nhsbsaExternalData::wales_pca_extraction(file_path = config$wa_pca)
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
  #regional data by fy
  region_data_fy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_fy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_fy"
    )
  )$mtime)]
  
  #read recent data
  region_data_fy <- vroom::vroom(region_data_fy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
  #regional data by cy
  region_data_cy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_cy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_cy"
    )
  )$mtime)]
  
  #read recent data
  region_data_cy <- vroom::vroom(region_data_cy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
  log_print("Data pulled from most recent saved data", hide_notes = TRUE)
} else {
  # Pull data from DWH and save to Y drive
  nat_data_fy <-
    extract_nat_data(con, year_type = "financial", year = max_dw_fy)
  nat_data_cy <-
    extract_nat_data(con, year_type = "calendar", year = max_dw_cy)
  
  region_data_fy <-
    extract_region_data(con, year_type = "financial", year = max_dw_fy)
  region_data_cy <-
    extract_region_data(con, year_type = "calendar", year = max_dw_cy)
  
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
  
  save_data(region_data_fy,
            dir = "Y:/Official Stats/PCA",
            filename = "region_data_fy",
            quote = TRUE)
  
  save_data(region_data_cy,
            dir = "Y:/Official Stats/PCA",
            filename = "region_data_cy",
            quote = TRUE)
  
  save_data(stp_data_cy,
            dir = "Y:/Official Stats/PCA",
            filename = "stp_data_cy",
            quote = TRUE)
  
  save_data(stp_data_fy,
            dir = "Y:/Official Stats/PCA",
            filename = "stp_data_fy",
            quote = TRUE)
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
  #regional data by fy
  region_data_fy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_fy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_fy"
    )
  )$mtime)]
  
  #read recent data
  region_data_fy <- vroom::vroom(region_data_fy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
  #national data by cy
  region_data_cy <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_cy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "region_data_cy"
    )
  )$mtime)]
  
  #read recent data
  region_data_cy <- vroom::vroom(region_data_cy,
                              #read snomed code as character
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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
                              col_types = c(DISP_PRESEN_SNOMED_CODE = "c")) |>
    dplyr::mutate(
      MYS_SERVICE_TYPE = case_when(
        MYS_SERVICE_TYPE == "CCS" ~ "Pharmacy First - Clinical Pathway",
        MYS_SERVICE_TYPE == "N" ~ "None",
        TRUE ~ "None"
      )
    )
  
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

log_print(paste0("max_data_fy_minus_1 built as: ", max_data_fy_minus_1),
          hide_notes = TRUE)


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

# 8. Pull data for additional analysis ------------
#dev_nations_data (requires add_anl_1)
add_anl_1 <-
  pca_item_cost_per_capita(con = con) |>
  dplyr::left_join(
    select(en_ons_national_pop, YEAR, ENPOP),
    by = c("JOIN_YEAR" = "YEAR"),
    copy = TRUE
  ) |>
  dplyr::arrange(YEAR_DESC) |>
  dplyr::mutate(
    COST_PER_ITEM = TOTAL_NIC / TOTAL_ITEMS,
    ITEMS_PER_CAPITA = TOTAL_ITEMS / ENPOP,
    NIC_PER_CAPITA = TOTAL_NIC / ENPOP
  ) |>
  dplyr::select(-JOIN_YEAR)

dev_nations_data <- data.frame(
  "Country" = c("England",
                "Wales",
                "Scotland",
                "Northern Ireland"),
  "TOTAL_ITEMS" = c(
    add_anl_1 |>
      filter(YEAR_DESC == max_data_fy_minus_1) |>
      select(TOTAL_ITEMS) |>
      pull(),
    wa_pca |>
      select(TOTAL_ITEMS) |>
      pull(),
    sc_pca |>
      select(TOTAL_ITEMS) |>
      pull(),
    ni_pca |>
      select(TOTAL_ITEMS) |>
      pull()
  ),
  "TOTAL_COSTS" = c(
    add_anl_1 |>
      filter(YEAR_DESC == max_data_fy_minus_1) |>
      select(TOTAL_NIC) |>
      pull(),
    wa_pca |>
      select(TOTAL_COST) |>
      pull(),
    sc_pca |>
      select(TOTAL_COST) |>
      pull(),
    ni_pca |>
      select(TOTAL_COST) |>
      pull()
  ),
  "POP" = c(
    en_ons_national_pop |>
      filter(YEAR == max(YEAR)) |>
      select(ENPOP) |>
      pull(),
    wa_ons_national_pop |>
      filter(YEAR == max(YEAR)) |>
      select(WAPOP) |>
      pull(),
    sc_ons_national_pop |>
      filter(YEAR == max(YEAR)) |>
      select(SCPOP) |>
      pull(),
    ni_ons_national_pop |>
      filter(YEAR == max(YEAR)) |>
      select(NIPOP) |>
      pull()
  )
) |>
  mutate(
    ITEMS_PER_CAPITA = round(TOTAL_ITEMS / POP, 1),
    COSTS_PER_CAPITA = round(TOTAL_COSTS / POP, 2)
  )

add_anl_2 <- pca_top_drug_cost(con = con)
add_anl_3 <- pca_top_item_cost(con = con)
add_anl_4 <- pca_top_items_status(con = con)
add_anl_5 <- pca_item_cost_class(con = con)
add_anl_6 <- pca_item_generic_bnf(con = con)
add_anl_7 <- pca_item_cost_BNF(con = con)
add_anl_8 <- pca_item_cost_BNF_sect(con = con)
add_anl_9 <-
  pca_item_cost_BNF_sect_increase(con = con)
add_anl_10 <-
  pca_item_cost_BNF_sect_decrease(con = con)
add_anl_11 <-
  pca_top_percentage_change(con = con)
add_anl_12 <-
  pca_bottom_percentage_change(con = con)
add_anl_13 <-
  pca_top_total_cost_change(con = con)
add_anl_14 <-
  pca_bottom_total_cost_change(con = con)

log_print("Data pulled for additional analysis", hide_notes = TRUE)

pca_exemption_categories <- pca_exemption_categories(con = con)
log_print("Data pulled for exemption categories", hide_notes = TRUE)

# 9. create chart and data for them ----------

#figure 1
figure_1_data <- add_anl_1 |>
  select(YEAR_DESC, TOTAL_NIC)

table_1 <- figure_1_data |>
  mutate(TOTAL_NIC = format(TOTAL_NIC, big.mark = ",")) |>
  rename("Financial year" = 1,
         "Net ingredient cost (£)" = 2)

figure_1 <- nhsbsaVis::basic_chart_hc(
  figure_1_data,
  x = YEAR_DESC,
  y = TOTAL_NIC,
  type = "line",
  xLab = "Financial year",
  yLab = "Total cost (£)",
  title = "",
  currency = TRUE
) |>
  hc_subtitle(text = "B = Billions",
              align = "left")

figure_1$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_1$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.TOTAL_NIC;

    if (ynum >= 1000000000) {
        var result = ynum / 1000000000;
        if (result >= 1000) { // If the number is >= 1000 billion, keep only one significant digit
            result = result.toPrecision(1);
        } else { // For numbers < 1000 billion, keep three significant digits
            result = result.toPrecision(3);
        }
        result = '£' + result + 'B';
    } else {
        result = ynum / 1000000;
        result = '£' + result.toFixed(2) + 'M';
    }

    return result;
}
"
)

figure_1$x$hc_opts$yAxis$tickPositioner <- JS(
  "function() {
                         var positions = [],
                         tick = Math.floor(this.dataMin / 1000000000) * 1000000000;
                         for (; tick - 1000000000 <= this.dataMax; tick += 1000000000) {
                         positions.push(tick);
                         }
                         return positions;
                         }"
)

figure_1$x$hc_opts$yAxis$labels <- list(formatter = JS("function() {
                    return this.value / 1000000000 + 'B';
                    }"))

figure_1$x$hc_opts$xAxis$lineWidth <- 1
figure_1$x$hc_opts$xAxis$lineColor <- "#E8EDEE"

# figure 2
figure_2_data <- add_anl_1 |>
  select(YEAR_DESC, TOTAL_ITEMS)

table_2 <- figure_2_data |>
  mutate(TOTAL_ITEMS = format(TOTAL_ITEMS, big.mark = ",")) |>
  rename("Financial year" = 1,
         "Items" = 2)

figure_2 <- nhsbsaVis::basic_chart_hc(
  figure_2_data,
  x = YEAR_DESC,
  y = TOTAL_ITEMS,
  type = "line",
  xLab = "Financial year",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions",
              align = "left") |>
  hc_yAxis(min = 1000000000)

figure_2$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_2$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.y/1000000;
    var options = { maximumSignificantDigits: 4, minimumSignificantDigits: 4 };
    return ynum.toLocaleString('en-GB', options) + 'M';
}
"
)

figure_2$x$hc_opts$yAxis$tickPositioner <- JS(
  "function() {
                         var positions = [],
                         tick = Math.floor(1000000000 / 100000000) * 100000000;
                         for (; tick - 100000000 <= this.dataMax; tick += 100000000) {
                         positions.push(tick);
                         }
                         return positions;
                         }"
)

figure_2$x$hc_opts$yAxis$labels <- list(
  formatter = JS(
    "function() {
                    return Highcharts.numberFormat(this.value / 1000000, 0, '.', ',') + 'M';
                    }"
  )
)

figure_2$x$hc_opts$xAxis$lineWidth <- 1
figure_2$x$hc_opts$xAxis$lineColor <- "#E8EDEE"

# figure 3
figure_3_data <- nat_data_fy |>
  group_by(BNF_CHAPTER, CHAPTER_DESCR) |>
  summarise(TOTAL_NIC = sum(TOTAL_NIC)) |>
  ungroup()


table_3 <- figure_3_data |>
  mutate(TOTAL_NIC = format(TOTAL_NIC, big.mark = ",")) |>
  rename(
    "BNF chapter code" = 1,
    "BNF chapter name" = 2,
    "Net ingredient cost (£)" = 3
  )


figure_3 <- nhsbsaVis::basic_chart_hc(
  figure_3_data,
  x = BNF_CHAPTER,
  y = TOTAL_NIC,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Cost of items dispensed (£)",
  title = ""
) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_3$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function(){
                                                       var ynum = this.point.TOTAL_NIC ;

                                                       if(ynum >= 1000000){
                                                       result = ynum/1000000
                                                       result = result.toLocaleString('en-GB', {maximumSignificantDigits: 3, style: 'currency', currency: 'GBP'}) + 'M';
                                                       } else {
                                                       result = ynum/1000000
                                                       result = '£' + result.toFixed(2) + 'M';
                                                       } /*else {
                                                       result = ynum/1000000
                                                       result = result.toLocaleString('en-GB', {maximumSignificantDigits: 3, style: 'currency', currency: 'GBP'}) + 'M';
                                                       }*/
                                                       return result
}"
)

figure_3$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 4
figure_4_data <- pca_bnf_costs_index(con = con)

table_4 <- figure_4_data |>
  mutate(VALUE = format(round(VALUE, 1), big.mark = ",")) |>
  select(-CHAPTER_DESCR) |>
  pivot_wider(names_from = BNF_CHAPTER,
              values_from = VALUE) |>
  rename("Financial year" = 1)


figure_4 <- nhsbsaVis::group_chart_hc(
  figure_4_data,
  x = YEAR_DESC,
  y = VALUE,
  group = BNF_CHAPTER,
  type = "line",
  xLab = "Financial year",
  yLab = "Index",
  title = ""
) |>
  hc_subtitle(text = "Index: 2014/2015 = 100",
              align = "left") |>
  hc_yAxis(plotLines = list(list(
    color = "#768692",
    width = 1.5,
    value = 100,
    zIndex = 100
  )))

figure_4$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 5
figure_5_data <- nat_data_fy |>
  group_by(BNF_CHAPTER, CHAPTER_DESCR) |>
  summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS)) |>
  ungroup()

table_5 <- figure_5_data |>
  mutate(TOTAL_ITEMS = format(TOTAL_ITEMS, big.mark = ",")) |>
  rename(
    "BNF chapter code" = 1,
    "BNF chapter name" = 2,
    "Items" = 3
  )

figure_5 <-  nhsbsaVis::basic_chart_hc(
  figure_5_data,
  x = BNF_CHAPTER,
  y = TOTAL_ITEMS,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_5$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function(){
                                                       var ynum = this.point.TOTAL_ITEMS ;
                                                       if(ynum >= 1000000) {
                                                       result = ynum/1000000
                                                       result = result.toPrecision(3) + 'M'
                                                       } else {
                                                       result = ynum.toLocaleString('en-GB', {maximumSignificantDigits: 3});
                                                       }
                                                       return result
}"
)

figure_5$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 6
figure_6_data <- pca_bnf_items_index(con = con)

table_6 <- figure_6_data |>
  mutate(VALUE = format(round(VALUE, 1), big.mark = ",")) |>
  select(-CHAPTER_DESCR) |>
  pivot_wider(names_from = BNF_CHAPTER,
              values_from = VALUE) |>
  rename("Financial year" = 1)


figure_6 <- nhsbsaVis::group_chart_hc(
  figure_6_data,
  x = YEAR_DESC,
  y = VALUE,
  group = BNF_CHAPTER,
  type = "line",
  xLab = "Financial year",
  yLab = "Index",
  title = ""
) |>
  hc_subtitle(text = "Index: 2014/2015 = 100",
              align = "left") |>
  hc_yAxis(plotLines = list(list(
    color = "#768692",
    width = 1.5,
    value = 100,
    zIndex = 100
  )))

figure_6$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 7
figure_7_data <- add_anl_5 |>
  mutate(
    GEN_ITEMS = PRESC_GEN_ITEMS,
    TOTAL_ITEMS = TOTAL_ITEMS - APPLIANCE_ITEMS,
    GEN_NIC = PRESC_GEN_NIC,
    TOTAL_NIC = TOTAL_NIC - APPLIANCE_NIC
  ) |>
  mutate(Items = GEN_ITEMS / TOTAL_ITEMS * 100,
         `Net ingredient cost` = GEN_NIC / TOTAL_NIC * 100) |>
  select(-(GEN_ITEMS:TOTAL_NIC)) |>
  pivot_longer(
    cols = c(Items, `Net ingredient cost`),
    names_to = "MEASURE",
    values_to = "VALUE"
  ) |>
  select(YEAR_DESC, MEASURE, VALUE)

table_7 <- figure_7_data |>
  mutate(VALUE = format(round(VALUE, 1), big.mark = ",")) |>
  pivot_wider(names_from = MEASURE,
              values_from = VALUE) |>
  rename(
    "Financial year" = 1,
    "Items (%)" = 2,
    "Net ingredient cost (%)" = 3
  )


figure_7 <- nhsbsaVis::group_chart_hc(
  figure_7_data,
  x = YEAR_DESC,
  y = VALUE,
  group = MEASURE,
  type = "line",
  xLab = "Financial year",
  yLab = "Percentage (%)",
  title = ""
) |>
  hc_yAxis(min = 50)

figure_7$x$hc_opts$xAxis$lineWidth <- 1
figure_7$x$hc_opts$xAxis$lineColor <- "#E8EDEE"

# figure 8
figure_8_df <- add_anl_5 |>
  filter(YEAR_DESC == max(YEAR_DESC))


figure_8_data <- data.frame(
  from = c(
    "Total<br>items",
    "Total<br>items",
    "Total<br>items",
    "Prescribed<br>generically",
    "Prescribed<br>generically",
    "Prescribed<br>proprietary"
  ),
  to = c(
    "Dressings<br>and appliances",
    "Prescribed<br>generically",
    "Prescribed<br>proprietary",
    "Dispensed<br>generically",
    "Dispensed<br>proprietary",
    "Dispensed<br>proprietary"
  ),
  weight = c(
    figure_8_df$APPLIANCE_ITEMS[1],
    figure_8_df$PRESC_GEN_ITEMS[1],
    figure_8_df$PRESC_DISP_PROP_ITEMS[1],
    figure_8_df$PRESC_DISP_GEN_ITEMS[1],
    figure_8_df$PRESC_GEN_DISP_PROP_ITEMS[1],
    figure_8_df$PRESC_DISP_PROP_ITEMS[1]
  )
)

table_8 <- figure_8_data |>
  rename("From" = 1,
         "To" = 2,
         "Items" = 3) |>
  mutate(
    Items = format(Items, big.mark = ","),
    From = str_replace_all(From, "<br>", " "),
    To = str_replace_all(To, "<br>", " ")
  )

figure_8 <- highchart() |>
  hc_chart(type = "sankey",
           style = list(fontFamily = "Arial")) |>
  hc_add_series(data = figure_8_data,
                nodes = unique(c(figure_8_data$from, figure_8_data$to))) |>
  hc_plotOptions(
    sankey = list(
      dataLabels = list(
        enabled = T,
        style = list(
          fontSize = "12px",
          color = "black",
          textOutline = "none"
        ),
        backgroundColor = 'rgba(232, 237, 238, 0.5)',
        borderRadius = 2,
        formatter = JS(
          "function() {
        if (this.point.isNode) {
        return this.point.name;
        } else {
        var ynum = this.point.weight / 1000000;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
    return ynum.toLocaleString('en-GB', options) + 'M';
        }
        }"
        )
      ),
    nodeWidth = 15
    ),
    series = list(allowPointSelect = FALSE,
                  states = list(hover = list(enabled = FALSE)))
  ) |>
  hc_colors(c(
    "#005EB8",
    "#ED8B00",
    "#006747",
    "#330072",
    "#009639",
    "#AE2573"
  )) |>
  hc_tooltip(enabled = F)

# figure 9
figure_9_data <- add_anl_2 |>
  group_by(CHEMICAL_SUBSTANCE_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE) |>
  rename(TOTAL_NIC = 5) |>
  summarise(TOTAL_NIC = sum(TOTAL_NIC)) |>
  ungroup() |>
  mutate(RANK = row_number(desc(TOTAL_NIC))) |>
  filter(RANK <= 10) |>
  arrange(RANK)

table_9 <- figure_9_data |>
  select(-RANK) |>
  rename(
    "Chemical substance name" = 1,
    "Chemical substance BNF code" = 2,
    "Net ingredient cost (£)" = 3
  ) |>
  mutate(`Net ingredient cost (£)` = format(`Net ingredient cost (£)`, big.mark = ","))

figure_9 <- nhsbsaVis::basic_chart_hc(
  figure_9_data,
  x = CHEMICAL_SUBSTANCE_BNF_DESCR,
  y = TOTAL_NIC,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Cost of items dispensed (£)",
  title = "",
  currency = TRUE
) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_9$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_9$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.y/1000000;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
    return '£' + ynum.toLocaleString('en-GB', options) + 'M';
}
"
)


# figure 10
figure_10_data <- add_anl_3 |>
  group_by(CHEMICAL_SUBSTANCE_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE) |>
  rename(TOTAL_ITEMS = 5) |>
  summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS)) |>
  ungroup() |>
  mutate(RANK = row_number(desc(TOTAL_ITEMS))) |>
  filter(RANK <= 10) |>
  arrange(RANK)

table_10 <- figure_10_data |>
  select(-RANK) |>
  rename(
    "Chemical substance name" = 1,
    "Chemical substance BNF code" = 2,
    "Items" = 3
  ) |>
  mutate(`Items` = format(`Items`, big.mark = ","))

figure_10 <- nhsbsaVis::basic_chart_hc(
  figure_10_data,
  x = CHEMICAL_SUBSTANCE_BNF_DESCR,
  y = TOTAL_ITEMS,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_10$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_10$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.y/1000000;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
    return ynum.toLocaleString('en-GB', options) + 'M';
}
"
)

# figure 11
figure_11_data <-  stp_data_fy_agg$National |>
  dplyr::select(`ICB Code`,
                `Total Cost (£)`) |>
  dplyr::rename(ICB_CODE = 1,
                TOTAL_NIC = 2) |>
  dplyr::group_by(ICB_CODE) |>
  dplyr::summarise(TOTAL_NIC = sum(TOTAL_NIC, na.rm = T),
                   .groups = "drop") |>
  dplyr::left_join(icb_pop,
                   by = c("ICB_CODE" = "ICB_CODE")) |>
  dplyr::mutate("TOTAL_NIC_PER_POP" = TOTAL_NIC / POP)

table_11 <- figure_11_data |>
  select(ICB_NAME, TOTAL_NIC_PER_POP) |>
  arrange(desc(TOTAL_NIC_PER_POP)) |>
  mutate(TOTAL_NIC_PER_POP = format(round(TOTAL_NIC_PER_POP, 2), big.mark = ",")) |>
  rename("ICB name" = 1,
         "Net ingredient cost (£) per person" = 2)

figure_11 <- nhsbsaVis::icb_map(
  data = stp_data_fy_agg$National,
  icb_code_column = "ICB Code",
  value_column = "Total Cost (£)",
  geo_data = icb_geo_data,
  icb_population = icb_pop,
  currency = TRUE,
  scale_rounding = 100,
  minColor = "#fff",
  maxColor = "#005EB8"
)

# figure 12
figure_12_data <-  stp_data_fy_agg$National |>
  dplyr::select(`ICB Code`,
                `Total Items`) |>
  dplyr::rename(ICB_CODE = 1,
                TOTAL_ITEMS = 2) |>
  dplyr::group_by(ICB_CODE) |>
  dplyr::summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS, na.rm = T),
                   .groups = "drop") |>
  dplyr::left_join(icb_pop,
                   by = c("ICB_CODE" = "ICB_CODE")) |>
  dplyr::mutate("TOTAL_ITEMS_PER_POP" = TOTAL_ITEMS / POP)

table_12 <- figure_12_data |>
  select(ICB_NAME, TOTAL_ITEMS_PER_POP) |>
  arrange(desc(TOTAL_ITEMS_PER_POP)) |>
  mutate(TOTAL_ITEMS_PER_POP = round(TOTAL_ITEMS_PER_POP, 1)) |>
  rename("ICB name" = 1,
         "Items per person" = 2)

figure_12 <- nhsbsaVis::icb_map(
  data = stp_data_fy_agg$National,
  icb_code_column = "ICB Code",
  value_column = "Total Items",
  geo_data = icb_geo_data,
  icb_population = icb_pop,
  currency = FALSE,
  scale_rounding = 10,
  minColor = "#fff",
  maxColor = "#AE2573"
)

# figure 13
figure_13_data <- add_anl_11 |>
  rename(UNIT_COST_CHANGE = 24,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_max(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         UNIT_COST_CHANGE)

table_13 <- figure_13_data |>
  select(-DISP_PRESEN_BNF) |>
  mutate(UNIT_COST_CHANGE = format(round(UNIT_COST_CHANGE), big.mark = ",")) |>
  rename(
    "Presentation name" = 1,
    "Unit of measure" = 2,
    "Unit cost increase (%)" = 3
  )

figure_13 <- nhsbsaVis::basic_chart_hc(
  figure_13_data,
  x = DISP_PRESEN_BNF_DESCR,
  y = UNIT_COST_CHANGE,
  type = "bar",
  xLab = "BNF presentation",
  yLab = "Unit cost percentage increase (%)",
  title = ""
)

# figure 14
figure_14_data <- add_anl_12 |>
  rename(UNIT_COST_CHANGE = 24,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_min(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         UNIT_COST_CHANGE)

table_14 <- figure_14_data |>
  select(-DISP_PRESEN_BNF) |>
  mutate(UNIT_COST_CHANGE = format(round(UNIT_COST_CHANGE, 1), big.mark = ",")) |>
  rename(
    "Presentation name" = 1,
    "Unit of measure" = 2,
    "Unit cost decrease (%)" = 3
  )

figure_14 <- figure_14_data |>
  mutate(UNIT_COST_CHANGE = UNIT_COST_CHANGE * -1) |>
  nhsbsaVis::basic_chart_hc(
    x = DISP_PRESEN_BNF_DESCR,
    y = UNIT_COST_CHANGE,
    type = "bar",
    xLab = "BNF presentation",
    yLab = "Unit cost percentage decrease (%)",
    title = ""
  )

# figure 15
figure_15_data <- add_anl_13 |>
  rename(NIC_CHANGE = 18,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_max(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         NIC_CHANGE)

table_15 <- figure_15_data |>
  select(-DISP_PRESEN_BNF) |>
  mutate(NIC_CHANGE = format(NIC_CHANGE, big.mark = ",")) |>
  rename(
    "Presentation name" = 1,
    "Unit of measure" = 2,
    "Total cost absolute increase (£)" = 3
  )

figure_15 <- nhsbsaVis::basic_chart_hc(
  figure_15_data,
  x = DISP_PRESEN_BNF_DESCR,
  y = NIC_CHANGE,
  type = "bar",
  xLab = "BNF presentation",
  yLab = "Total cost absolute increase (£)",
  title = "",
  currency = TRUE
) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_15$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_15$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.y/1000000;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
    return '£' + ynum.toLocaleString('en-GB', options) + 'M';
}
"
)


# figure 14
figure_16_data <- add_anl_14 |>
  rename(NIC_CHANGE = 18,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_min(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         NIC_CHANGE)

table_16 <- figure_16_data |>
  select(-DISP_PRESEN_BNF) |>
  mutate(NIC_CHANGE = format(NIC_CHANGE, big.mark = ",")) |>
  rename(
    "Presentation name" = 1,
    "Unit of measure" = 2,
    "Total cost absolute decrease (£)" = 3
  )

figure_16 <- figure_16_data |>
  mutate(NIC_CHANGE = NIC_CHANGE * -1) |>
  nhsbsaVis::basic_chart_hc(
    x = DISP_PRESEN_BNF_DESCR,
    y = NIC_CHANGE,
    type = "bar",
    xLab = "BNF presentation",
    yLab = "Total cost absolute decrease (£)",
    title = "",
    currency = TRUE
  ) |>
  hc_subtitle(text = "M = Millions",
              align = "left")

figure_16$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_16$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.y/1000000;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
    return '£' + ynum.toLocaleString('en-GB', options) + 'M';
}
"
)


# figure 17
figure_17_data <- dev_nations_data |>
  arrange(desc(COSTS_PER_CAPITA)) |>
  select(Country,
         POP,
         TOTAL_COSTS,
         COSTS_PER_CAPITA)

table_17 <- figure_17_data |>
  select(Country, COSTS_PER_CAPITA) |>
  mutate(COSTS_PER_CAPITA = format(round(COSTS_PER_CAPITA, 2), big.mark = ",")) |>
  rename("Cost per person (£)" = 2)

figure_17 <-
  nhsbsaVis::basic_chart_hc(
    figure_17_data,
    x = Country,
    y = COSTS_PER_CAPITA,
    type = "column",
    xLab = "Country",
    yLab = "Cost per person (£)",
    title = "",
    currency = TRUE
  )


# figure 16
figure_18_data <- dev_nations_data |>
  arrange(desc(ITEMS_PER_CAPITA)) |>
  select(Country,
         POP,
         TOTAL_ITEMS,
         ITEMS_PER_CAPITA)

table_18 <- figure_18_data |>
  select(Country, ITEMS_PER_CAPITA) |>
  mutate(ITEMS_PER_CAPITA = format(signif(ITEMS_PER_CAPITA, 3), big.mark = ",")) |>
  rename("Items per person" = 2)

figure_18 <-
  nhsbsaVis::basic_chart_hc(
    figure_18_data,
    x = Country,
    y = ITEMS_PER_CAPITA,
    type = "column",
    xLab = "Country",
    yLab = "Items per person",
    title = "",
    color = "#AE2573"
  )

log_print("Charts and chart data created", hide_notes = TRUE)

# 10. create Excel outputs if required ------
if (makeSheet == 1) {
  print("Generating Excel outputs")
  source("./excel_outputs/excel_outputs.R")
  log_print("Excel outputs generated", hide_notes = TRUE)
} else {
  print("Excel outputs will not be generated")
  log_print("Excel outputs not generated", hide_notes = TRUE)
}

# 11. Automate tidy dates -------
#tidy max year to automate title
year <- stp_data_fy |>
  select(YEAR_DESC) |>
  unique() |>
  pull()

year_tidy <- paste0(substr(year, 1, 5), substr(year, 8, 9))

# 12. create markdowns -------

rmarkdown::render("pca-narrative-markdown.Rmd",
                  output_format = "html_document",
                  output_file = "outputs/pca_summary_narrative_2023_24_v001.html")


rmarkdown::render("pca-narrative-markdown.Rmd",
                  output_format = "word_document",
                  output_file = "outputs/pca_summary_narrative_2023_24_v001.docx")

log_print("Narrative markdown generated", hide_notes = TRUE)

rmarkdown::render("pca-background-june-2024.Rmd",
                  output_format = "html_document",
                  output_file = "outputs/pca_background_info_methodology_v001.html")

rmarkdown::render("pca-background-june-2024.Rmd",
                  output_format = "word_document",
                  output_file = "outputs/pca_background_info_methodology_v001.docx")

log_print("Background markdown generated", hide_notes = TRUE)


# 13. disconnect from DWH  ---------
#DBI::dbDisconnect(con)
log_print("Disconnected from DWH", hide_notes = TRUE)

#close log
logr::log_close()
