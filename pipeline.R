### Pipeline to run PCA annual publication
# clear environment
rm(list = ls())

# source functions
# this is only a temporary step until all functions are built into packages
source("./functions/functions.R")

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
    "nhsbsa-data-analytics/accessibleTables",
    "nhsbsa-data-analytics/nhsbsaDataExtract",
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
con <- nhsbsaR::con_nhsbsa(dsn = "FBS_8192k",
                           driver = "Oracle in OraClient19Home1",
                           "DWCP")

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
lsoa_population_overall <-
  nhsbsaExternalData::lsoa_population(group = "Overall")
en_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = c(2014:as.numeric(max_dw_cy)), area = "ENPOP")
sc_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "SCPOP")
ni_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "NIPOP")
wa_ons_national_pop <-
  nhsbsaExternalData::ons_national_pop(year = (2014:as.numeric(max_dw_cy)), area = "WAPOP")

# build ibc population lookup
icb_pop <- icb_lsoa_lookup |>
  dplyr::left_join(lsoa_population_overall,
                   by = c("LSOA_CODE" = "LSOA_CODE")) |>
  dplyr::group_by(ICB_CODE, ICB_NAME, ICB_LONG_CODE) |>
  dplyr::summarise(POP = sum(POP, na.rm = TRUE),
                   .groups = "drop")

log_print("Population data loaded", hide_notes = TRUE)

#pca data
sc_pca <-
  nhsbsaExternalData::scottish_pca_extraction(link = config$scotland_pca)
ni_pca <-
  nhsbsaExternalData::northern_irish_pca_extraction(link = config$ni_pca)
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
  nhsbsaDataExtract::pca_item_cost_per_capita(con = con) |>
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
    add_anl_1 %>%
      filter(YEAR_DESC == max_data_fy_minus_1) %>%
      select(TOTAL_ITEMS) %>%
      pull(),
    wa_pca %>%
      select(TOTAL_ITEMS) %>%
      pull(),
    sc_pca %>%
      select(TOTAL_ITEMS) %>%
      pull(),
    ni_pca %>%
      select(TOTAL_ITEMS) %>%
      pull()
  ),
  "TOTAL_COSTS" = c(
    add_anl_1 %>%
      filter(YEAR_DESC == max_data_fy_minus_1) %>%
      select(TOTAL_NIC) %>%
      pull(),
    wa_pca %>%
      select(TOTAL_COST) %>%
      pull(),
    sc_pca %>%
      select(TOTAL_COST) %>%
      pull(),
    ni_pca %>%
      select(TOTAL_COST) %>%
      pull()
  ),
  "POP" = c(
    en_ons_national_pop %>%
      filter(YEAR == max(YEAR)) %>%
      select(ENPOP) %>%
      pull(),
    wa_ons_national_pop %>%
      filter(YEAR == max(YEAR)) %>%
      select(WAPOP) %>%
      pull(),
    sc_ons_national_pop %>%
      filter(YEAR == max(YEAR)) %>%
      select(SCPOP) %>%
      pull(),
    ni_ons_national_pop %>%
      filter(YEAR == max(YEAR)) %>%
      select(NIPOP) %>%
      pull()
  )
) %>%
  mutate(
    ITEMS_PER_CAPITA = round(TOTAL_ITEMS / POP, 1),
    COSTS_PER_CAPITA = round(TOTAL_COSTS / POP, 2)
  )

add_anl_2 <- nhsbsaDataExtract::pca_top_drug_cost(con = con)
add_anl_3 <- nhsbsaDataExtract::pca_top_item_cost(con = con)
add_anl_4 <- nhsbsaDataExtract::pca_top_items_status(con = con)
add_anl_5 <- nhsbsaDataExtract::pca_item_cost_class(con = con)
add_anl_6 <- nhsbsaDataExtract::pca_item_generic_bnf(con = con)
add_anl_7 <- nhsbsaDataExtract::pca_item_cost_BNF(con = con)
add_anl_8 <- nhsbsaDataExtract::pca_item_cost_BNF_sect(con = con)
add_anl_9 <-
  nhsbsaDataExtract::pca_item_cost_BNF_sect_increase(con = con)
add_anl_10 <-
  nhsbsaDataExtract::pca_item_cost_BNF_sect_decrease(con = con)
add_anl_11 <-
  nhsbsaDataExtract::pca_top_percentage_change(con = con)
add_anl_12 <-
  nhsbsaDataExtract::pca_bottom_percentage_change(con = con)
add_anl_13 <-
  nhsbsaDataExtract::pca_top_total_cost_change(con = con)
add_anl_14 <-
  nhsbsaDataExtract::pca_bottom_total_cost_change(con = con)

log_print("Data pulled for additional analysis", hide_notes = TRUE)

pca_exemption_categories <- pca_exemption_categories(con = con)
log_print("Data pulled for exemption categories", hide_notes = TRUE)



# 9. create chart and data for them ----------

#figure 1
figure_1_data <- add_anl_1 |>
  select(YEAR_DESC, TOTAL_NIC)

figure_1 <- nhsbsaVis::basic_chart_hc(
  figure_1_data,
  x = YEAR_DESC,
  y = TOTAL_NIC,
  type = "line",
  xLab = "Financial year",
  yLab = "Total cost (GBP)",
  title = "",
  currency = TRUE
)

figure_1$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 2
figure_2_data <- add_anl_1 |>
  select(YEAR_DESC, TOTAL_ITEMS)

figure_2 <- nhsbsaVis::basic_chart_hc(
  figure_2_data,
  x = YEAR_DESC,
  y = TOTAL_ITEMS,
  type = "line",
  xLab = "Financial year",
  yLab = "Number of items dispensed",
  title = ""
)

figure_2$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 3
figure_3_data <- nat_data_fy |>
  group_by(BNF_CHAPTER, CHAPTER_DESCR) |>
  summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS)) |>
  ungroup()


figure_3 <-  nhsbsaVis::basic_chart_hc(
  figure_3_data,
  x = BNF_CHAPTER,
  y = TOTAL_ITEMS,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Number of items dispensed",
  title = ""
)

figure_3$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
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

# figure 4
figure_4_data <- nat_data_fy |>
  group_by(BNF_CHAPTER, CHAPTER_DESCR) |>
  summarise(TOTAL_NIC = sum(TOTAL_NIC)) |>
  ungroup()

figure_4 <- nhsbsaVis::basic_chart_hc(
  figure_4_data,
  x = BNF_CHAPTER,
  y = TOTAL_NIC,
  type = "column",
  xLab = "BNF chapter",
  yLab = "Cost of items dispensed (GBP)",
  title = ""
)

figure_4$x$hc_opts$series[[1]]$dataLabels$formatter <- JS(
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

figure_4$x$hc_opts$series[[1]]$dataLabels$allowOverlap <- TRUE

# figure 5
figure_5_data <- add_anl_5 |>
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


figure_5 <- nhsbsaVis::group_chart_hc(
  figure_5_data,
  x = YEAR_DESC,
  y = VALUE,
  group = MEASURE,
  type = "line",
  xLab = "Financial year",
  yLab = "Proportion (%)",
  title = ""
)

# figure 6
figure_6_df <- add_anl_5 |>
  filter(YEAR_DESC == max(YEAR_DESC))


figure_6_data <- data.frame(
  from = c(
    "Total<br>items",
    "Total<br>items",
    "Total<br>items",
    "Prescribed<br>generically",
    "Prescribed<br>generically",
    "Prescribed<br>propietory"
  ),
  to = c(
    "Dressings<br>and appliances",
    "Prescribed<br>generically",
    "Prescribed<br>propietory",
    "Dispensed<br>generically",
    "Dispensed<br>propietory",
    "Dispensed<br>propietory"
  ),
  weight = c(
    figure_6_df$APPLIANCE_ITEMS[1],
    figure_6_df$PRESC_GEN_ITEMS[1],
    figure_6_df$PRESC_DISP_PROP_ITEMS[1],
    figure_6_df$PRESC_DISP_GEN_ITEMS[1],
    figure_6_df$PRESC_GEN_DISP_PROP_ITEMS[1],
    figure_6_df$PRESC_DISP_PROP_ITEMS[1]
  )
)

figure_6 <- highchart() |>
  hc_chart(type = "sankey",
           style = list(fontFamily = "Arial")) |>
  hc_add_series(
    data = figure_6_data,
    nodes = unique(c(figure_6_data$from, figure_6_data$to))
  ) |>
  hc_plotOptions(sankey = list(
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
  series = list(
    allowPointSelect = FALSE,
    states = list(
      hover = list(
        enabled = FALSE
      )
    )
  )) |>
  hc_colors(c("#005EB8", "#ED8B00", "#006747", "#330072",  "#009639", "#AE2573")) |>
  hc_tooltip(enabled = F)


# figure 7
figure_7_data <- add_anl_3 |>
  group_by(CHEMICAL_SUBSTANCE_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE) |>
  rename(TOTAL_ITEMS = 5) |>
  summarise(TOTAL_ITEMS = sum(TOTAL_ITEMS)) |>
  ungroup() |>
  mutate(RANK = row_number(desc(TOTAL_ITEMS))) |>
  filter(RANK <= 10) |>
  arrange(RANK)

figure_7 <- nhsbsaVis::basic_chart_hc(
  figure_7_data,
  x = CHEMICAL_SUBSTANCE_BNF_DESCR,
  y = TOTAL_ITEMS,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Number of items dispensed",
  title = ""
)

# figure 8
figure_8_data <- add_anl_2 |>
  group_by(CHEMICAL_SUBSTANCE_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE) |>
  rename(TOTAL_NIC = 5) |>
  summarise(TOTAL_NIC = sum(TOTAL_NIC)) |>
  ungroup() |>
  mutate(RANK = row_number(desc(TOTAL_NIC))) |>
  filter(RANK <= 10) |>
  arrange(RANK)

figure_8 <- nhsbsaVis::basic_chart_hc(
  figure_8_data,
  x = CHEMICAL_SUBSTANCE_BNF_DESCR,
  y = TOTAL_NIC,
  type = "bar",
  xLab = "Chemical substance",
  yLab = "Cost of items dispensed (GBP)",
  title = "",
  currency = TRUE
)

# figure 9
figure_9_data <-  stp_data_fy_agg$National |>
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

figure_9 <- nhsbsaVis::icb_map(
  data = stp_data_fy_agg$National,
  icb_code_column = "ICB Code",
  value_column = "Total Items",
  geo_data = icb_geo_data,
  icb_lsoa_lookup = icb_lsoa_lookup,
  lsoa_population = lsoa_population_overall,
  currency = FALSE,
  scale_rounding = 10
)

# figure 10
figure_10_data <-  stp_data_fy_agg$National |>
  dplyr::select(`ICB Code`,
                `Total Cost (GBP)`) |>
  dplyr::rename(ICB_CODE = 1,
                TOTAL_NIC = 2) |>
  dplyr::group_by(ICB_CODE) |>
  dplyr::summarise(TOTAL_NIC = sum(TOTAL_NIC, na.rm = T),
                   .groups = "drop") |>
  dplyr::left_join(icb_pop,
                   by = c("ICB_CODE" = "ICB_CODE")) |>
  dplyr::mutate("TOTAL_NIC_PER_POP" = TOTAL_NIC / POP)

figure_10 <- nhsbsaVis::icb_map(
  data = stp_data_fy_agg$National,
  icb_code_column = "ICB Code",
  value_column = "Total Cost (GBP)",
  geo_data = icb_geo_data,
  icb_lsoa_lookup = icb_lsoa_lookup,
  lsoa_population = lsoa_population_overall,
  currency = TRUE,
  scale_rounding = 100
)

# figure 11
figure_11_data <- add_anl_11 |>
  rename(UNIT_COST_CHANGE = 24,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_max(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         UNIT_COST_CHANGE)

figure_11 <- nhsbsaVis::basic_chart_hc(
  figure_11_data,
  x = DISP_PRESEN_BNF_DESCR,
  y = UNIT_COST_CHANGE,
  type = "bar",
  xLab = "BNF presentation",
  yLab = "Unit cost percentage increase (%)",
  title = ""
)

# figure 12
figure_12_data <- add_anl_12 |>
  rename(UNIT_COST_CHANGE = 24,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_min(UNIT_COST_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         UNIT_COST_CHANGE)

figure_12 <- figure_12_data |>
  mutate(UNIT_COST_CHANGE = UNIT_COST_CHANGE * -1) |>
  nhsbsaVis::basic_chart_hc(
    x = DISP_PRESEN_BNF_DESCR,
    y = UNIT_COST_CHANGE,
    type = "bar",
    xLab = "BNF presentation",
    yLab = "Unit cost percentage decrease (%)",
    title = ""
  )

# figure 13
figure_13_data <- add_anl_13 |>
  rename(NIC_CHANGE = 18,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_max(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         NIC_CHANGE)

figure_13 <- nhsbsaVis::basic_chart_hc(
  figure_13_data,
  x = DISP_PRESEN_BNF_DESCR,
  y = NIC_CHANGE,
  type = "bar",
  xLab = "BNF presentation",
  yLab = "Total cost absolute increase (GBP)",
  title = "",
  currency = TRUE
)

# figure 14
figure_14_data <- add_anl_14 |>
  rename(NIC_CHANGE = 18,
         DISP_PRESEN_BNF_DESCR = 2) |>
  slice_min(NIC_CHANGE, n = 10) |>
  select(DISP_PRESEN_BNF,
         DISP_PRESEN_BNF_DESCR,
         VMPP_UOM,
         NIC_CHANGE)

figure_14 <- figure_14_data |>
  mutate(NIC_CHANGE = NIC_CHANGE * -1) |>
  nhsbsaVis::basic_chart_hc(
    x = DISP_PRESEN_BNF_DESCR,
    y = NIC_CHANGE,
    type = "bar",
    xLab = "BNF presentation",
    yLab = "Total cost absolute decrease (GBP)",
    title = "",
    currency = TRUE
  )

# figure 15
figure_15_data <- dev_nations_data |>
  arrange(desc(ITEMS_PER_CAPITA)) |>
  select(Country,
         POP,
         TOTAL_ITEMS,
         ITEMS_PER_CAPITA
         )

figure_15 <-
  basic_chart_hc(
    figure_15_data,
    x = Country,
    y = ITEMS_PER_CAPITA,
    type = "column",
    xLab = "Country",
    yLab = "Items per capita",
    title = ""
  )

# figure 16
figure_16_data <- dev_nations_data |>
  arrange(desc(COSTS_PER_CAPITA)) |>
  select(Country,
         POP,
         TOTAL_COSTS,
         COSTS_PER_CAPITA
  )

figure_16 <-
  basic_chart_hc(
    figure_16_data,
    x = Country,
    y = COSTS_PER_CAPITA,
    type = "column",
    xLab = "Country",
    yLab = "Cost per capita (GBP)",
    title = ""
  )


log_print("Charts and chart data created", hide_notes = TRUE)

# 10. create Excel outputs if required ------
if (makeSheet == 1) {
  print("Generating Excel outputs")
  source("./functions/excelOutputs.R")
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
                  output_file = "outputs/pca_summary_narrative_2022_23_v001.html")

rmarkdown::render("pca-narrative-markdown.Rmd",
                  output_format = "word_document",
                  output_file = "outputs/pca_summary_narrative_2022_23_v001.docx")

log_print("Narrative markdown generated", hide_notes = TRUE)


# 13. disconnect from DWH  ---------
DBI::dbDisconnect(con)
log_print("Disconnected from DWH", hide_notes = TRUE)

#close log
logr::log_close()
