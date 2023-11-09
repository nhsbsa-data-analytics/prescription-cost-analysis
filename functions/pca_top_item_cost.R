pca_top_item_cost <- function(con) {
  #extract raw data
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY")) |>
    dplyr::filter(YEAR_DESC != "2013/2014") |>
    dplyr::filter(!BNF_CHAPTER %in% c("20","21","22","23")) |>
    dplyr::select(
      "YEAR_DESC",
      "CHEMICAL_SUBSTANCE_BNF_DESCR",
      "BNF_CHEMICAL_SUBSTANCE",
      "ITEM_COUNT"
    ) |>
    dplyr::group_by(YEAR_DESC,
                    CHEMICAL_SUBSTANCE_BNF_DESCR,
                    BNF_CHEMICAL_SUBSTANCE) |>
    dplyr::summarise(
      TOTAL_ITEMS = sum(ITEM_COUNT, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(YEAR_DESC)  |>
    dplyr::collect()
  
  raw_data <- raw_data |>
    dplyr::mutate(RANK= dplyr::row_number(dplyr::desc(TOTAL_ITEMS)),FILTER_YEAR = as.numeric(substr(YEAR_DESC,1,4))) |>
    dplyr::ungroup()	  |>
    dplyr::filter(
      FILTER_YEAR == min(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) - 1
    ) |>
    dplyr::select(-FILTER_YEAR)
  
  
  #pull data from warehouse
  data <- raw_data |>
    dplyr::arrange(YEAR_DESC)
  
  #build column names based on max year
  filter_col <- rlang::sym(paste0("RANK_",max(data$YEAR_DESC)))
  mutate_col <- rlang::sym(paste0("TOTAL_ITEMS_",max(data$YEAR_DESC)))
  select_col <- paste0(max(data$YEAR_DESC),"_")
  #manipulate data as needed
  table <- data |>
    tidyr::pivot_wider(
      names_from = YEAR_DESC,
      values_from = c(TOTAL_ITEMS,RANK)
    ) |>
    dplyr::slice_max(dplyr::desc(!!filter_col), n = 20) |>
    dplyr::mutate(
      dplyr::across(
        starts_with("TOTAL_ITEMS"),
        .fns = ~!!mutate_col - .x,
        .names = "{.col}_DIFF"),
      dplyr::across(
        matches("TOTAL_ITEMS.*/{1}\\d{4}$"),
        .fns = ~ (!!mutate_col - .x) / .x * 100,
        .names = "{.col}_CHANGE"
      )
    )|>
    dplyr::select(-contains(select_col))
  
  return(table)
  
}
