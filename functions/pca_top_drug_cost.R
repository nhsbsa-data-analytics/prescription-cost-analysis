pca_top_drug_cost <- function(con) {
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
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC,
                    CHEMICAL_SUBSTANCE_BNF_DESCR,
                    BNF_CHEMICAL_SUBSTANCE) |>
    dplyr::summarise(
      TOTAL_NIC = sum(ITEM_PAY_DR_NIC) / 100
    ) |>
    dplyr::ungroup()   |>
    dplyr::group_by(YEAR_DESC)   |>
    dplyr::collect()
  
  raw_data <- raw_data |>
    dplyr::mutate(RANK= row_number(desc(TOTAL_NIC)),FILTER_YEAR = as.numeric(substr(YEAR_DESC,1,4))) |>
    dplyr::ungroup()	  |>
    dplyr::filter(
      FILTER_YEAR == min(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) - 1
    ) |>
    
    dplyr::select(-FILTER_YEAR)
  
  
  #pull data from warehouse
  data <- raw_data |>
    collect () |>
    arrange(YEAR_DESC)
  
  #build column names based on max year
  filter_col <- sym(paste0("RANK_",max(data$YEAR_DESC)))
  mutate_col <- sym(paste0("TOTAL_NIC_",max(data$YEAR_DESC)))
  select_col <- paste0(max(data$YEAR_DESC),"_")
  #manipulate data as needed
  table <- data |>
    tidyr::pivot_wider(
      names_from = YEAR_DESC,
      values_from = c(TOTAL_NIC,RANK)
    ) |>
    dplyr::slice_max(desc(!!filter_col), n = 20) |>
    dplyr::mutate(
      dplyr::across(
        starts_with("TOTAL_NIC"),
        .fns = ~!!mutate_col - .x,
        .names = "{.col}_DIFF"),
      dplyr::across(
        matches("TOTAL_NIC.*/{1}\\d{4}$"),
        .fns = ~ (!!mutate_col - .x) / .x * 100,
        .names = "{.col}_CHANGE"
      )
    )|>
    dplyr::select(-contains(select_col))
  
  return(table)
  
}

