pca_top_percentage_change <- function(con) {
  #extract raw data
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY")) |>
    dplyr::filter(!YEAR_DESC %in% c("2013/2014", "2014/2015")) |>
    dplyr::select(
      "YEAR_DESC",
      #"DISP_PRESEN_BNF",
      "DISP_PRESEN_BNF_DESCR",
      "VMPP_UOM",
      "ITEM_COUNT",
      "ITEM_CALC_PAY_QTY",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC,
                    #DISP_PRESEN_BNF,
                    DISP_PRESEN_BNF_DESCR,
                    VMPP_UOM) |>
    dplyr::summarise(
      TOTAL_ITEMS = sum(ITEM_COUNT),
      TOTAL_QUANTITY = sum(ITEM_CALC_PAY_QTY),
      TOTAL_NIC = sum(ITEM_PAY_DR_NIC) / 100
    ) |>
    dplyr::filter(TOTAL_QUANTITY > 0) |>
    dplyr::mutate(UNIT_COST = sum(TOTAL_NIC, na.rm = TRUE) / sum(TOTAL_QUANTITY, na.rm = TRUE)) |>
    dplyr::select(-TOTAL_QUANTITY) |>
    dplyr::ungroup() |>
    dplyr::mutate(FILTER_YEAR = as.numeric(substr(YEAR_DESC, 1, 4))) |>
    dplyr::filter(
      FILTER_YEAR == min(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) - 1
    ) |>
    dplyr::select(-FILTER_YEAR)
  
  #create list of unique years
  years <- raw_data |>
    dplyr::select("YEAR_DESC") |>
    distinct() |>
    collect ()
  
  #build column names based on max year
  items_col <- sym(paste0("TOTAL_ITEMS_", max(years$YEAR_DESC)))
  nic_col <- sym(paste0("TOTAL_NIC_", max(years$YEAR_DESC)))
  unit_cost_col <- sym(paste0("UNIT_COST_", max(years$YEAR_DESC)))
  select_col <- paste0(max(years$YEAR_DESC), "_")
  prev_year <-
    paste0(as.numeric(substr(max(years$YEAR_DESC), 1, 4)) - 1, "/", substr(max(years$YEAR_DESC), 1, 4))
  rank_col <- sym(paste0("UNIT_COST_", prev_year, "_CHANGE"))
  
  #pull data from warehouse
  data <- raw_data |>
    collect ()|>
    arrange(YEAR_DESC)
  
  #manipulate data as needed
  table <- data |>
    tidyr::pivot_wider(
      names_from = YEAR_DESC,
      values_from = c(TOTAL_NIC, TOTAL_ITEMS, UNIT_COST)
    ) |>
    dplyr::filter(!!nic_col > 1000000) |>
    dplyr::mutate(
      dplyr::across(
        starts_with("TOTAL_ITEMS"),
        .fns = ~ !!items_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("TOTAL_ITEMS.*/{1}\\d{4}$"),
        .fns = ~ (!!items_col - .x) / .x * 100,
        .names = "{.col}_CHANGE"
      ),
      dplyr::across(
        starts_with("TOTAL_NIC"),
        .fns = ~ !!nic_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("TOTAL_NIC.*/{1}\\d{4}$"),
        .fns = ~ (!!nic_col - .x) / .x * 100,
        .names = "{.col}_CHANGE"
      ),
      dplyr::across(
        starts_with("UNIT_COST"),
        .fns = ~ !!unit_cost_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("UNIT_COST.*/{1}\\d{4}$"),
        .fns = ~ (!!unit_cost_col - .x) / .x * 100,
        .names = "{.col}_CHANGE"
      )
    ) |>
    dplyr::select(-contains(select_col)) |>
    dplyr::slice_max(!!rank_col, n = 20)
  
  return(table)
  
}