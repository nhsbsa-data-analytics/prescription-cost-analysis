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

# quick fix for Wales PCA
wales_pca_extraction_2324 <- function(file_path = NULL) {
  items <- readxl::read_excel(file_path,
                              sheet = 1,
                              range = "A3",
                              col_names = "TOTAL_ITEMS")
  
  cost <- readxl::read_excel(file_path,
                             sheet = 1,
                             range = "A2",
                             col_names = "TOTAL_COST")
  
  wales_pca <- cbind(items, cost)
  
  #presenting the data
  return(wales_pca)
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

if (Sys.getenv("FABRIC_PASSWORD") == "") {
  usethis::edit_r_environ()
  stop(
    "You need to set your FABRIC_USERNAME = YOUR Fabric USERNAME and  FABRIC_PASSWORD = YOUR Fabric PASSWORD in the .Renviron file which pops up. Please restart your R Studio after this and re-run the pipeline."
  )
}

#check if Excel outputs are required
makeSheet <- menu(c("Yes", "No"), title = "Do you wish to generate the Excel outputs?")

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
    "highcharter",
    "lubridate",
    "vroom",
    "tidyverse",
    "kableExtra",
    "devtools",
    "yaml",
    "DBI",
    "geojsonsf",
    "sf",
    "magrittr",
    "tcltk",
    "DT",
    "htmltools",
    "odbc",
    "dbplyr",
    "nhsbsa-data-analytics/nhsbsaR",
    "nhsbsa-data-analytics/nhsbsaExternalData",
    "nhsbsa-data-analytics/accessibleTables",
    "nhsbsa-data-analytics/nhsbsaVis"
  )

#library/install packages as required
nhsbsaUtils::check_and_install_packages(req_pkgs)

# load config
config <- yaml::yaml.load_file("config.yml")

# load options
nhsbsaUtils::publication_options()

# 2. connect to Fabric ---------
# build Fabric connection
con <- nhsbsaR::con_nhsbsa_fabric(
  sql_analytics_endpoint = Sys.getenv("FABRIC_PCA_CONN_STRING"),
  lakehouse_name = "dsaas_prescription_cost_analysis_gold"
)

# 3. load reference data  ---------
#map data
icb_geo_data <-
  nhsbsaExternalData::icb_geo_data(
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Integrated_Care_Boards_April_2023_EN_BSC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson",
    SUB_GEOGRAPHY_CODE = "ICB23CD",
    SUB_GEOGRAPHY_NAME = "ICB23NM"
  )

#icb population
temp1 <- tempfile()
icb_population_raw <-
  utils::download.file(url = "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/clinicalcommissioninggroupmidyearpopulationestimates/mid2022revisednov2025tomid2024integratedcareboards2024geography/sapeicb20222024.xlsx", temp1, mode = "wb")

icb_population <- readxl::read_xlsx(temp1,
                                    sheet = 7,
                                    range = "A4:GG110",
                                    col_names = TRUE) |>
  group_by(`ICB 2024 Name`, `ICB 2024 Code`) |>
  summarise(POP = sum(Total), .groups = "drop") |>
  rename("ICB_NAME" = 1,
         "ICB_LONG_CODE" = 2,
         "POP" = 3)

icb_code_lookup <-
  dplyr::bind_rows(
    # ICB
    sf::read_sf(
      "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/ICB_APR_2023_EN_NC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
    ) |>
      dplyr::select(ICB_CODE = "ICB23CDH", ICB_LONG_CODE = "ICB23CD")
  ) |>
  data.frame() |>
  select(-geometry)

icb_pop <- icb_code_lookup |>
  left_join(icb_population)

region_population <- readxl::read_xlsx(temp1,
                                       sheet = 7,
                                       range = "A4:GG110",
                                       col_names = TRUE) |>
  group_by(`NHSER 2024 Name`, `NHSER 2024 Code`) |>
  summarise(POP = sum(Total), .groups = "drop") |>
  rename(
    "REGION_NAME" = 1,
    "REGION_LONG_CODE" = 2,
    "POP" = 3
  ) |>
  mutate(REGION_NAME = toupper(REGION_NAME)) |>
  select(-REGION_LONG_CODE)

# national population
en_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = c(2014:as.numeric(config$cy_suffix)), area = "ENPOP")
sc_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(config$cy_suffix)), area = "SCPOP")
ni_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(config$cy_suffix)), area = "NIPOP")
wa_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(config$cy_suffix)), area = "WAPOP")

#pca data
sc_pca <-
  nhsbsaExternalData::scottish_pca_extraction(link = config$scotland_pca)
ni_pca <-
  northern_irish_pca_extraction_2024(file_path = config$ni_pca)
wa_pca <-
  wales_pca_extraction_2324(file_path = config$wa_pca)

# 4. pull data from Fabric ------
# fy national data
nat_data_fy_agg <- list()
nat_data_fy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].national_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].chapter_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].section_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].paragraph_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].chem_sub_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].presentation_total_fy_", as.character(config$fy_suffix)))
nat_data_fy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].snomed_total_fy_", as.character(config$fy_suffix)))

#replace NA with blanks
nat_data_fy_agg$National[is.na(nat_data_fy_agg$National)] <- ""
nat_data_fy_agg$BNF_Chapters[is.na(nat_data_fy_agg$BNF_Chapters)] <- ""
nat_data_fy_agg$BNF_Sections[is.na(nat_data_fy_agg$BNF_Sections)] <- ""
nat_data_fy_agg$BNF_Paragraphs[is.na(nat_data_fy_agg$BNF_Paragraphs)] <- ""
nat_data_fy_agg$Chemical_Substances[is.na(nat_data_fy_agg$Chemical_Substances)] <- ""
nat_data_fy_agg$Presentations[is.na(nat_data_fy_agg$Presentations)] <- ""
nat_data_fy_agg$SNOMED_Code[is.na(nat_data_fy_agg$SNOMED_Code)] <- ""

# cy national data
nat_data_cy_agg <- list()
nat_data_cy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].national_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].chapter_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].section_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].paragraph_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].chem_sub_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].presentation_total_cy_", as.character(config$cy_suffix)))
nat_data_cy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [national].snomed_total_cy_", as.character(config$cy_suffix)))
#replace NA with blanks
nat_data_cy_agg$National[is.na(nat_data_cy_agg$National)] <- ""
nat_data_cy_agg$BNF_Chapters[is.na(nat_data_cy_agg$BNF_Chapters)] <- ""
nat_data_cy_agg$BNF_Sections[is.na(nat_data_cy_agg$BNF_Sections)] <- ""
nat_data_cy_agg$BNF_Paragraphs[is.na(nat_data_cy_agg$BNF_Paragraphs)] <- ""
nat_data_cy_agg$Chemical_Substances[is.na(nat_data_cy_agg$Chemical_Substances)] <- ""
nat_data_cy_agg$Presentations[is.na(nat_data_cy_agg$Presentations)] <- ""
nat_data_cy_agg$SNOMED_Code[is.na(nat_data_cy_agg$SNOMED_Code)] <- ""

# fy region data
region_data_fy_agg <- list()
region_data_fy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_chapter_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_section_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_paragraph_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_chem_sub_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_presentation_total_fy_", as.character(config$fy_suffix)))
region_data_fy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_snomed_total_fy_", as.character(config$fy_suffix)))
#replace NA with blanks
region_data_fy_agg$National[is.na(region_data_fy_agg$National)] <- ""
region_data_fy_agg$BNF_Chapters[is.na(region_data_fy_agg$BNF_Chapters)] <- ""
region_data_fy_agg$BNF_Sections[is.na(region_data_fy_agg$BNF_Sections)] <- ""
region_data_fy_agg$BNF_Paragraphs[is.na(region_data_fy_agg$BNF_Paragraphs)] <- ""
region_data_fy_agg$Chemical_Substances[is.na(region_data_fy_agg$Chemical_Substances)] <- ""
region_data_fy_agg$Presentations[is.na(region_data_fy_agg$Presentations)] <- ""
region_data_fy_agg$SNOMED_Code[is.na(region_data_fy_agg$SNOMED_Code)] <- ""

# cy region data
region_data_cy_agg <- list()
region_data_cy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_chapter_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_section_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_paragraph_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_chem_sub_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_presentation_total_cy_", as.character(config$cy_suffix)))
region_data_cy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [region].region_snomed_total_cy_", as.character(config$cy_suffix)))
#replace NA with blanks
region_data_cy_agg$National[is.na(region_data_cy_agg$National)] <- ""
region_data_cy_agg$BNF_Chapters[is.na(region_data_cy_agg$BNF_Chapters)] <- ""
region_data_cy_agg$BNF_Sections[is.na(region_data_cy_agg$BNF_Sections)] <- ""
region_data_cy_agg$BNF_Paragraphs[is.na(region_data_cy_agg$BNF_Paragraphs)] <- ""
region_data_cy_agg$Chemical_Substances[is.na(region_data_cy_agg$Chemical_Substances)] <- ""
region_data_cy_agg$Presentations[is.na(region_data_cy_agg$Presentations)] <- ""
region_data_cy_agg$SNOMED_Code[is.na(region_data_cy_agg$SNOMED_Code)] <- ""

# fy ICB data
icb_data_fy_agg <- list()
icb_data_fy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_chapter_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_section_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_paragraph_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_chem_sub_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_presentation_total_fy_", as.character(config$fy_suffix)))
icb_data_fy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_snomed_total_fy_", as.character(config$fy_suffix)))

#replace NA with blanks
icb_data_fy_agg$National[is.na(icb_data_fy_agg$National)] <- ""
icb_data_fy_agg$BNF_Chapters[is.na(icb_data_fy_agg$BNF_Chapters)] <- ""
icb_data_fy_agg$BNF_Sections[is.na(icb_data_fy_agg$BNF_Sections)] <- ""
icb_data_fy_agg$BNF_Paragraphs[is.na(icb_data_fy_agg$BNF_Paragraphs)] <- ""
icb_data_fy_agg$Chemical_Substances[is.na(icb_data_fy_agg$Chemical_Substances)] <- ""
icb_data_fy_agg$Presentations[is.na(icb_data_fy_agg$Presentations)] <- ""
icb_data_fy_agg$SNOMED_Code[is.na(icb_data_fy_agg$SNOMED_Code)] <- ""

# cy ICB data
icb_data_cy_agg <- list()
icb_data_cy_agg$National <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$BNF_Chapters <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_chapter_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$BNF_Sections <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_section_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$BNF_Paragraphs <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_paragraph_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$Chemical_Substances <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_chem_sub_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$Presentations <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_presentation_total_cy_", as.character(config$cy_suffix)))
icb_data_cy_agg$SNOMED_Code <- DBI::dbGetQuery(con, paste0("SELECT * FROM [icb].icb_snomed_total_cy_", as.character(config$cy_suffix)))
#replace NA with blanks
icb_data_cy_agg$National[is.na(icb_data_cy_agg$National)] <- ""
icb_data_cy_agg$BNF_Chapters[is.na(icb_data_cy_agg$BNF_Chapters)] <- ""
icb_data_cy_agg$BNF_Sections[is.na(icb_data_cy_agg$BNF_Sections)] <- ""
icb_data_cy_agg$BNF_Paragraphs[is.na(icb_data_cy_agg$BNF_Paragraphs)] <- ""
icb_data_cy_agg$Chemical_Substances[is.na(icb_data_cy_agg$Chemical_Substances)] <- ""
icb_data_cy_agg$Presentations[is.na(icb_data_cy_agg$Presentations)] <- ""
icb_data_cy_agg$SNOMED_Code[is.na(icb_data_cy_agg$SNOMED_Code)] <- ""

# 5. build variable for max and prev fy to use in headers ------
#get max fy from latest data
max_data_fy <- nat_data_fy_agg$National |>
  dplyr::select(year_desc) |>
  dplyr::filter(year_desc == max(year_desc, na.rm = TRUE)) |>
  distinct() |>
  pull()

#get max fy minus 1 from latest data
max_data_fy_minus_1 <-
  paste0(as.numeric(substr(max_data_fy, 1, 4)) - 1, "/", as.numeric(substr(max_data_fy, 6, 9)) - 1)

#get max cy from latest data
max_data_cy <- nat_data_cy_agg$National |>
  dplyr::select(year_desc) |>
  dplyr::filter(year_desc == max(year_desc, na.rm = TRUE)) |>
  distinct() |>
  pull()

# 6. Pull data for additional analysis ------------
#dev_nations_data (requires add_anl_1)
add_anl_1 <-
  DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].year_summary_", as.character(config$fy_suffix))) |>
  mutate(join_year = as.numeric(join_year)) |>
  dplyr::left_join(
    select(en_ons_national_pop, YEAR, ENPOP),
    by = c("join_year" = "YEAR"),
    copy = TRUE
  ) |>
  dplyr::arrange(year_desc) |>
  dplyr::mutate(
    cost_per_item = total_nic / total_items,
    items_per_capita = total_items / ENPOP,
    nic_per_capita = total_nic / ENPOP
  ) |>
  dplyr::select(-join_year)

dev_nations_data <- data.frame(
  "Country" = c("England", "Wales", "Scotland", "Northern Ireland"),
  "total_items" = c(
    add_anl_1 |>
      filter(year_desc == max_data_fy_minus_1) |>
      select(total_items) |>
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
  "total_costs" = c(
    add_anl_1 |>
      filter(year_desc == max_data_fy_minus_1) |>
      select(total_nic) |>
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
  "pop" = c(
    en_ons_national_pop |>
      filter(!is.na(ENPOP)) |>
      filter(YEAR == max(YEAR)) |>
      select(ENPOP) |>
      pull(),
    wa_ons_national_pop |>
      filter(!is.na(WAPOP)) |>
      filter(YEAR == max(YEAR)) |>
      select(WAPOP) |>
      pull(),
    sc_ons_national_pop |>
      filter(!is.na(SCPOP)) |>
      filter(YEAR == max(YEAR)) |>
      select(SCPOP) |>
      pull(),
    ni_ons_national_pop |>
      filter(!is.na(NIPOP)) |>
      filter(YEAR == max(YEAR)) |>
      select(NIPOP) |>
      pull()
  )
) |>
  mutate(
    items_per_capita = round(total_items / pop, 1),
    costs_per_capita = round(total_costs / pop, 2)
  )

add_anl_2 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].top_chem_sub_costs_", as.character(config$fy_suffix)))
add_anl_3 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].top_chem_sub_items_", as.character(config$fy_suffix)))
add_anl_4 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].items_costs_charge_status_", as.character(config$fy_suffix)))
add_anl_5 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].gen_presc_disp_prep_class_", as.character(config$fy_suffix)))
add_anl_6 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].gen_presc_disp_bnf_chapter_", as.character(config$fy_suffix)))
add_anl_7 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].items_costs_bnf_chapter_", as.character(config$fy_suffix)))
add_anl_8 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].top_bnf_section_costs_", as.character(config$fy_suffix)))
add_anl_9 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].top_bnf_section_cost_increase_", as.character(config$fy_suffix)))
add_anl_10 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].top_bnf_section_cost_decrease_", as.character(config$fy_suffix)))
add_anl_11 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].unit_costs_bnf_presentation_increase_", as.character(config$fy_suffix)))
add_anl_12 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].unit_costs_bnf_presentation_decrease_", as.character(config$fy_suffix)))
add_anl_13 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].total_costs_bnf_presentation_increase_", as.character(config$fy_suffix)))
add_anl_14 <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].total_costs_bnf_presentation_decrease_", as.character(config$fy_suffix)))

# 7. Exemption categories -------------------------------------------------
pca_exemption_categories <- DBI::dbGetQuery(con, paste0("SELECT * FROM [exemption_categories].pca_exemption_categories_", as.character(config$fy_suffix)))
pca_rtec_charges <- DBI::dbGetQuery(con, paste0("SELECT * FROM [exemption_categories].pca_rtec_charges_", as.character(config$fy_suffix)))

# 8. create chart and data for them ----------

#figure 1
figure_1_data <- add_anl_1 |>
  select(year_desc, total_nic)

table_1 <- figure_1_data |>
  mutate(total_nic = format(total_nic, big.mark = ",")) |>
  rename("Financial year" = 1,
         "Net ingredient cost (£)" = 2)

figure_1 <- nhsbsaVis::basic_chart_hc(
  figure_1_data,
  x = year_desc,
  y = total_nic,
  type = "line",
  xLab = "Financial year",
  yLab = "Total cost (£)",
  title = "",
  currency = TRUE
) |>
  hc_subtitle(text = "B = Billions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

figure_1$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

figure_1$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function formatCurrency() {
    var ynum = this.point.total_nic;

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
  select(year_desc, total_items)

table_2 <- figure_2_data |>
  mutate(total_items = format(total_items, big.mark = ",")) |>
  rename("Financial year" = 1, "Items" = 2)

figure_2 <- nhsbsaVis::basic_chart_hc(
  figure_2_data,
  x = year_desc,
  y = total_items,
  type = "line",
  xLab = "Financial year",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions", align = "left") |>
  hc_yAxis(min = 1000000000) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

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
figure_3_data <- nat_data_fy_agg$SNOMED_Code |>
  group_by(bnf_chapter, chapter_descr) |>
  summarise(total_nic = sum(item_pay_dr_nic)) |>
  ungroup()


table_3 <- figure_3_data |>
  mutate(total_nic = format(
    total_nic,
    big.mark = ",",
    nsmall = 2,
    digits = 2,
    trim = TRUE
  )) |>
  rename(
    "BNF chapter code" = 1,
    "BNF chapter name" = 2,
    "Net ingredient cost (£)" = 3
  )


figure_3 <- nhsbsaVis::basic_chart_hc(
  figure_3_data,
  x = bnf_chapter,
  y = total_nic,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Cost of items dispensed (£)",
  title = ""
) |>
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

figure_3$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function(){
                                                       var ynum = this.point.total_nic ;

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
figure_4_data <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].pca_bnf_costs_index_", as.character(config$fy_suffix)))

table_4 <- figure_4_data |>
  mutate(value = format(round(value, 1), big.mark = ",")) |>
  select(-chapter_descr) |>
  pivot_wider(names_from = bnf_chapter, values_from = value) |>
  rename("Financial year" = 1)


figure_4 <- nhsbsaVis::group_chart_hc(
  figure_4_data,
  x = year_desc,
  y = value,
  group = bnf_chapter,
  type = "line",
  xLab = "Financial year",
  yLab = "Index",
  title = ""
) |>
  hc_subtitle(text = "Index: 2016/2017 = 100", align = "left") |>
  hc_yAxis(plotLines = list(list(
    color = "#768692",
    width = 1.5,
    value = 100,
    zIndex = 100
  )))

figure_4$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 5
figure_5_data <- nat_data_fy_agg$SNOMED_Code |>
  group_by(bnf_chapter, chapter_descr) |>
  summarise(total_items = sum(item_count)) |>
  ungroup()

table_5 <- figure_5_data |>
  mutate(total_items = format(total_items, big.mark = ",")) |>
  rename(
    "BNF chapter code" = 1,
    "BNF chapter name" = 2,
    "Items" = 3
  )

figure_5 <-  nhsbsaVis::basic_chart_hc(
  figure_5_data,
  x = bnf_chapter,
  y = total_items,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

figure_5$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
  "function(){
                                                       var ynum = this.point.total_items ;
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
figure_6_data <- DBI::dbGetQuery(con, paste0("SELECT * FROM [additional_analysis].pca_bnf_items_index_", as.character(config$fy_suffix)))

table_6 <- figure_6_data |>
  mutate(value = format(round(value, 1), big.mark = ",")) |>
  select(-chapter_descr) |>
  pivot_wider(names_from = bnf_chapter, values_from = value) |>
  rename("Financial year" = 1)


figure_6 <- nhsbsaVis::group_chart_hc(
  figure_6_data,
  x = year_desc,
  y = value,
  group = bnf_chapter,
  type = "line",
  xLab = "Financial year",
  yLab = "Index",
  title = ""
) |>
  hc_subtitle(text = "Index: 2016/2017 = 100", align = "left") |>
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
    gen_items = presc_gen_items,
    total_items = total_items - appliance_items,
    gen_nic = presc_gen_nic,
    total_nic = total_nic - appliance_nic
  ) |>
  mutate(Items = gen_items / total_items * 100,
         `Net ingredient cost` = gen_nic / total_nic * 100) |>
  select(-(gen_items:total_nic)) |>
  pivot_longer(
    cols = c(Items, `Net ingredient cost`),
    names_to = "MEASURE",
    values_to = "VALUE"
  ) |>
  select(year_desc, MEASURE, VALUE)

table_7 <- figure_7_data |>
  mutate(VALUE = format(round(VALUE, 1), big.mark = ",")) |>
  pivot_wider(names_from = MEASURE, values_from = VALUE) |>
  rename(
    "Financial year" = 1,
    "Items (%)" = 2,
    "Net ingredient cost (%)" = 3
  )


figure_7 <- nhsbsaVis::group_chart_hc(
  figure_7_data,
  x = year_desc,
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
  filter(year_desc == max(year_desc))


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
    figure_8_df$appliance_items[1],
    as.numeric(figure_8_df$presc_gen_items[1]),
    figure_8_df$presc_disp_prop_items[1],
    figure_8_df$presc_disp_gen_items[1],
    figure_8_df$presc_gen_disp_prop_items[1],
    figure_8_df$presc_disp_prop_items[1]
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
  hc_chart(type = "sankey", style = list(fontFamily = "Arial")) |>
  hc_add_series(data = figure_8_data, nodes = unique(c(figure_8_data$from, figure_8_data$to))) |>
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
    series = list(allowPointSelect = FALSE, states = list(hover = list(enabled = FALSE)))
  ) |>
  hc_colors(c(
    "#005EB8",
    "#ED8B00",
    "#006747",
    "#330072",
    "#009639",
    "#AE2573"
  )) |>
  hc_tooltip(enabled = F) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

# figure 9
figure_9_data <- add_anl_2 |>
  group_by(chemical_substance_bnf_descr, bnf_chemical_substance) |>
  summarise(total_nic = sum(max_fy_total_nic)) |>
  ungroup() |>
  mutate(rank = row_number(desc(total_nic))) |>
  filter(rank <= 10) |>
  arrange(rank)

table_9 <- figure_9_data |>
  select(-rank) |>
  rename(
    "Chemical substance name" = 1,
    "Chemical substance BNF code" = 2,
    "Net ingredient cost (£)" = 3
  ) |>
  mutate(`Net ingredient cost (£)` = format(`Net ingredient cost (£)`, big.mark = ","))

figure_9 <- nhsbsaVis::basic_chart_hc(
  figure_9_data,
  x = chemical_substance_bnf_descr,
  y = total_nic,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Cost of items dispensed (£)",
  title = "",
  currency = TRUE
) |>
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

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
  group_by(chemical_substance_bnf_descr, bnf_chemical_substance) |>
  summarise(total_items = sum(max_fy_total_items)) |>
  ungroup() |>
  mutate(rank = row_number(desc(total_items))) |>
  filter(rank <= 10) |>
  arrange(rank)

table_10 <- figure_10_data |>
  select(-rank) |>
  rename(
    "Chemical substance name" = 1,
    "Chemical substance BNF code" = 2,
    "Items" = 3
  ) |>
  mutate(`Items` = format(`Items`, big.mark = ","))

figure_10 <- nhsbsaVis::basic_chart_hc(
  figure_10_data,
  x = chemical_substance_bnf_descr,
  y = total_items,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Number of items dispensed",
  title = "",
  color = "#AE2573"
) |>
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

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
figure_11_data <-  icb_data_fy_agg$National |>
  dplyr::select(stp_code, item_pay_dr_nic) |>
  dplyr::rename(ICB_CODE = 1, TOTAL_NIC = 2) |>
  dplyr::group_by(ICB_CODE) |>
  dplyr::summarise(TOTAL_NIC = sum(TOTAL_NIC, na.rm = T), .groups = "drop") |>
  dplyr::left_join(icb_pop, by = c("ICB_CODE" = "ICB_CODE")) |>
  dplyr::mutate("TOTAL_NIC_PER_POP" = TOTAL_NIC / POP)

table_11 <- figure_11_data |>
  select(ICB_NAME, TOTAL_NIC_PER_POP) |>
  arrange(desc(TOTAL_NIC_PER_POP)) |>
  mutate(TOTAL_NIC_PER_POP = format(round(TOTAL_NIC_PER_POP, 2), big.mark = ",")) |>
  rename("ICB name" = 1,
         "Net ingredient cost (£) per person" = 2)

figure_11 <- nhsbsaVis::icb_map(
  data = icb_data_fy_agg$National,
  icb_code_column = "stp_code",
  value_column = "item_pay_dr_nic",
  geo_data = icb_geo_data,
  icb_population = icb_pop,
  currency = TRUE,
  scale_rounding = 100,
  minColor = "#fff",
  maxColor = "#005EB8"
)

# figure 12
figure_12_data <-  icb_data_fy_agg$National |>
  dplyr::select(stp_code, item_count) |>
  dplyr::rename(ICB_CODE = 1, TOTAL_ITEMS = 2) |>
  dplyr::group_by(ICB_CODE) |>
  dplyr::summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS, na.rm = T),
                   .groups = "drop") |>
  dplyr::left_join(icb_pop, by = c("ICB_CODE" = "ICB_CODE")) |>
  dplyr::mutate("TOTAL_ITEMS_PER_POP" = TOTAL_ITEMS / POP)

table_12 <- figure_12_data |>
  select(ICB_NAME, TOTAL_ITEMS_PER_POP) |>
  arrange(desc(TOTAL_ITEMS_PER_POP)) |>
  mutate(TOTAL_ITEMS_PER_POP = round(TOTAL_ITEMS_PER_POP, 1)) |>
  rename("ICB name" = 1, "Items per person" = 2)

figure_12 <- nhsbsaVis::icb_map(
  data = icb_data_fy_agg$National,
  icb_code_column = "stp_code",
  value_column = "item_count",
  geo_data = icb_geo_data,
  icb_population = icb_pop,
  currency = FALSE,
  scale_rounding = 10,
  minColor = "#fff",
  maxColor = "#AE2573"
)

# figure 13
figure_13_data <- add_anl_11 |>
  rename(UNIT_COST_CHANGE = 23,
         DISP_PRESEN_BNF_DESCR = 1) |>
  slice_max(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF_DESCR, vmpp_uom, UNIT_COST_CHANGE)

table_13 <- figure_13_data |>
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
) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

# figure 14
figure_14_data <- add_anl_12 |>
  rename(UNIT_COST_CHANGE = 23,
         DISP_PRESEN_BNF_DESCR = 1) |>
  slice_min(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF_DESCR, vmpp_uom, UNIT_COST_CHANGE)

table_14 <- figure_14_data |>
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
  ) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

# figure 15
figure_15_data <- add_anl_13 |>
  rename(NIC_CHANGE = 17, DISP_PRESEN_BNF_DESCR = 1) |>
  slice_max(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF_DESCR, vmpp_uom, NIC_CHANGE)

table_15 <- figure_15_data |>
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
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

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
  rename(NIC_CHANGE = 17, DISP_PRESEN_BNF_DESCR = 1) |>
  slice_min(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF_DESCR, vmpp_uom, NIC_CHANGE)

table_16 <- figure_16_data |>
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
  hc_subtitle(text = "M = Millions", align = "left") |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))

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
  arrange(desc(costs_per_capita)) |>
  select(Country, pop, total_costs, costs_per_capita)

table_17 <- figure_17_data |>
  select(Country, costs_per_capita) |>
  mutate(costs_per_capita = format(round(costs_per_capita, 2), big.mark = ",")) |>
  rename("Cost per person (£)" = 2)

figure_17 <-
  nhsbsaVis::basic_chart_hc(
    figure_17_data,
    x = Country,
    y = costs_per_capita,
    type = "column",
    xLab = "Country",
    yLab = "Cost per person (£)",
    title = "",
    currency = TRUE
  ) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))


# figure 16
figure_18_data <- dev_nations_data |>
  arrange(desc(items_per_capita)) |>
  select(Country, pop, total_items, items_per_capita)

table_18 <- figure_18_data |>
  select(Country, items_per_capita) |>
  mutate(items_per_capita = format(signif(items_per_capita, 3), big.mark = ",")) |>
  rename("Items per person" = 2)

figure_18 <-
  nhsbsaVis::basic_chart_hc(
    figure_18_data,
    x = Country,
    y = items_per_capita,
    type = "column",
    xLab = "Country",
    yLab = "Items per person",
    title = "",
    color = "#AE2573"
  ) |>
  highcharter::hc_plotOptions(series = list(enableMouseTracking = FALSE))


# 9. Rename columns in main data accordingly ------------------------------

# rename function
rename_if_present <- function(df, year_type = c("FY", "CY")) {
  year_type <- match.arg(year_type)
  
  # Base rename map
  rename_map <- c(
    region_name = "Region Name",
    region_code = "Region Code",                 
    stp_name = "ICB Name",
    stp_code = "ICB Code",
    disp_presen_bnf = "BNF Presentation Code",             
    disp_presen_bnf_descr = "BNF Presentation Name",
    disp_presen_snomed_code = "SNOMED Code",
    disp_supplier_name = "Supplier Name",
    vmpp_uom = "Unit of Measure",
    generic_bnf_code = "Generic BNF Presentation Code",
    gen_presentation_bnf_descr = "Generic BNF Presentation Name",  
    bnf_chemical_substance = "BNF Chemical Substance Code",
    chemical_substance_bnf_descr = "BNF Chemical Substance Name",
    bnf_paragraph = "BNF Paragraph Code",               
    paragraph_descr = "BNF Paragraph Name",
    bnf_section = "BNF Section Code",
    section_descr = "BNF Section Name",
    bnf_chapter = "BNF Chapter Code",
    chapter_descr = "BNF Chapter Name",
    disp_prep_class = "Preparation Class",             
    presc_prep_class = "Prescribed Preparation Class",
    mys_service_type = "Advanced Service Type",
    item_count = "Total Items",                  
    item_calc_pay_qty = "Total Quantity",
    item_pay_dr_nic = "Total Cost (£)",
    cost_per_item = "Cost Per Item (£)",               
    cost_per_quantity = "Cost Per Quantity (£)",
    quantity_per_item  = "Quantity Per Item"
  )

  # Add conditional rename for year_desc
  if ("year_desc" %in% names(df)) {
    rename_map["year_desc"] <- if (year_type == "FY") {
      "Financial Year"
    } else {
      "Calendar Year"
    }
  }
  
  # Apply renames only where columns exist
  present <- names(rename_map)[names(rename_map) %in% names(df)]
  
  for (old in present) {
    names(df)[names(df) == old] <- rename_map[[old]]
  }
  
  df
}

nat_data_fy_agg$National <- rename_if_present(nat_data_fy_agg$National, "FY")
nat_data_fy_agg$BNF_Chapters <- rename_if_present(nat_data_fy_agg$BNF_Chapters, "FY")
nat_data_fy_agg$BNF_Sections <- rename_if_present(nat_data_fy_agg$BNF_Sections, "FY")
nat_data_fy_agg$BNF_Paragraphs <- rename_if_present(nat_data_fy_agg$BNF_Paragraphs, "FY")
nat_data_fy_agg$Chemical_Substances <- rename_if_present(nat_data_fy_agg$Chemical_Substances, "FY")
nat_data_fy_agg$Presentations <- rename_if_present(nat_data_fy_agg$Presentations, "FY")
nat_data_fy_agg$SNOMED_Code <- rename_if_present(nat_data_fy_agg$SNOMED_Code, "FY")

nat_data_cy_agg$National <- rename_if_present(nat_data_cy_agg$National, "CY")
nat_data_cy_agg$BNF_Chapters <- rename_if_present(nat_data_cy_agg$BNF_Chapters, "CY")
nat_data_cy_agg$BNF_Sections <- rename_if_present(nat_data_cy_agg$BNF_Sections, "CY")
nat_data_cy_agg$BNF_Paragraphs <- rename_if_present(nat_data_cy_agg$BNF_Paragraphs, "CY")
nat_data_cy_agg$Chemical_Substances <- rename_if_present(nat_data_cy_agg$Chemical_Substances, "CY")
nat_data_cy_agg$Presentations <- rename_if_present(nat_data_cy_agg$Presentations, "CY")
nat_data_cy_agg$SNOMED_Code <- rename_if_present(nat_data_cy_agg$SNOMED_Code, "CY")

region_data_fy_agg$National <- rename_if_present(region_data_fy_agg$National, "FY")
region_data_fy_agg$BNF_Chapters <- rename_if_present(region_data_fy_agg$BNF_Chapters, "FY")
region_data_fy_agg$BNF_Sections <- rename_if_present(region_data_fy_agg$BNF_Sections, "FY")
region_data_fy_agg$BNF_Paragraphs <- rename_if_present(region_data_fy_agg$BNF_Paragraphs, "FY")
region_data_fy_agg$Chemical_Substances <- rename_if_present(region_data_fy_agg$Chemical_Substances, "FY")
region_data_fy_agg$Presentations <- rename_if_present(region_data_fy_agg$Presentations, "FY")
region_data_fy_agg$SNOMED_Code <- rename_if_present(region_data_fy_agg$SNOMED_Code, "FY")

region_data_cy_agg$National <- rename_if_present(region_data_cy_agg$National, "CY")
region_data_cy_agg$BNF_Chapters <- rename_if_present(region_data_cy_agg$BNF_Chapters, "CY")
region_data_cy_agg$BNF_Sections <- rename_if_present(region_data_cy_agg$BNF_Sections, "CY")
region_data_cy_agg$BNF_Paragraphs <- rename_if_present(region_data_cy_agg$BNF_Paragraphs, "CY")
region_data_cy_agg$Chemical_Substances <- rename_if_present(region_data_cy_agg$Chemical_Substances, "CY")
region_data_cy_agg$Presentations <- rename_if_present(region_data_cy_agg$Presentations, "CY")
region_data_cy_agg$SNOMED_Code <- rename_if_present(region_data_cy_agg$SNOMED_Code, "CY")

icb_data_fy_agg$National <- rename_if_present(icb_data_fy_agg$National, "FY")
icb_data_fy_agg$BNF_Chapters <- rename_if_present(icb_data_fy_agg$BNF_Chapters, "FY")
icb_data_fy_agg$BNF_Sections <- rename_if_present(icb_data_fy_agg$BNF_Sections, "FY")
icb_data_fy_agg$BNF_Paragraphs <- rename_if_present(icb_data_fy_agg$BNF_Paragraphs, "FY")
icb_data_fy_agg$Chemical_Substances <- rename_if_present(icb_data_fy_agg$Chemical_Substances, "FY")
icb_data_fy_agg$Presentations <- rename_if_present(icb_data_fy_agg$Presentations, "FY")
icb_data_fy_agg$SNOMED_Code <- rename_if_present(icb_data_fy_agg$SNOMED_Code, "FY")

icb_data_cy_agg$National <- rename_if_present(icb_data_cy_agg$National, "CY")
icb_data_cy_agg$BNF_Chapters <- rename_if_present(icb_data_cy_agg$BNF_Chapters, "CY")
icb_data_cy_agg$BNF_Sections <- rename_if_present(icb_data_cy_agg$BNF_Sections, "CY")
icb_data_cy_agg$BNF_Paragraphs <- rename_if_present(icb_data_cy_agg$BNF_Paragraphs, "CY")
icb_data_cy_agg$Chemical_Substances <- rename_if_present(icb_data_cy_agg$Chemical_Substances, "CY")
icb_data_cy_agg$Presentations <- rename_if_present(icb_data_cy_agg$Presentations, "CY")
icb_data_cy_agg$SNOMED_Code <- rename_if_present(icb_data_cy_agg$SNOMED_Code, "CY")

# 10. join population data to all levels ------
england_pop <- en_ons_national_pop |>
  filter(!is.na(ENPOP)) |>
  filter(YEAR == max(YEAR)) |>
  select(ENPOP) |>
  pull()

england_pop_year <- en_ons_national_pop |>
  filter(!is.na(ENPOP)) |>
  filter(YEAR == max(YEAR)) |>
  select(YEAR) |>
  pull()

nat_data_fy_agg <- lapply(nat_data_fy_agg, function(df) {
  df$`Population Year` <- england_pop_year
  df$`Population` <- england_pop
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$`Population`) * 1000
  df
})

nat_data_cy_agg <- lapply(nat_data_cy_agg, function(df) {
  df$`Population Year` <- england_pop_year
  df$`Population` <- england_pop
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$`Population`) * 1000
  df
})

region_pop_year <- 2024

region_data_fy_agg <- lapply(region_data_fy_agg, function(df) {
  df$`Population Year` <- region_pop_year
  df <- df |>
    left_join(region_population, by = c("Region Name" = "REGION_NAME")) |>
    rename(Population = POP)
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$Population) * 1000
  df
})

region_data_cy_agg <- lapply(region_data_cy_agg, function(df) {
  df$`Population Year` <- region_pop_year
  df <- df |>
    left_join(region_population, by = c("Region Name" = "REGION_NAME")) |>
    rename(Population = POP)
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$Population) * 1000
  df
})

icb_pop_year <- 2024

icb_pop_for_join <- icb_pop |>
  select(ICB_CODE, POP)

icb_data_fy_agg <- lapply(icb_data_fy_agg, function(df) {
  df$`Population Year` <- icb_pop_year
  df <- df |>
    left_join(icb_pop_for_join, by = c("ICB Code" = "ICB_CODE")) |>
    rename(Population = POP)
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$Population) * 1000
  df
})

icb_data_cy_agg <- lapply(icb_data_cy_agg, function(df) {
  df$`Population Year` <- icb_pop_year
  df <- df |>
    left_join(icb_pop_for_join, by = c("ICB Code" = "ICB_CODE")) |>
    rename(Population = POP)
  df$`Items Per 1,000 Population` <- (df$`Total Items` / df$Population) * 1000
  df
})


# 11. create Excel outputs if required ------
if (makeSheet == 1) {
  print("Generating Excel outputs")
  source("./excel_outputs/excel_outputs.R")
} else {
  print("Excel outputs will not be generated")
}

# 12. Automate tidy dates -------
#tidy max year to automate title
year <- nat_data_fy_agg$National |>
  select(`Financial Year`) |>
  unique() |>
  pull()

year_tidy <- paste0(substr(year, 1, 5), substr(year, 8, 9))

# 13. create markdowns -------

rmarkdown::render("pca-narrative-markdown.Rmd",
                  output_format = "html_document",
                  output_file = "outputs/pca_summary_narrative_2025_26_v001.html")


rmarkdown::render("pca-narrative-markdown.Rmd",
                  output_format = "word_document",
                  output_file = "outputs/pca_summary_narrative_2025_26_v001.docx")


rmarkdown::render("pca-background-june-2026.Rmd",
                  output_format = "html_document",
                  output_file = "outputs/pca_background_info_methodology_june2026_v001.html")

rmarkdown::render("pca-background-june-2026.Rmd",
                  output_format = "word_document",
                  output_file = "outputs/pca_background_info_methodology_june2025_v001.docx")

