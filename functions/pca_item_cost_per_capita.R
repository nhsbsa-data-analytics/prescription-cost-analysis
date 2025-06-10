pca_item_cost_per_capita <- function(con) {
  #extract raw data
  
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY"),!YEAR_DESC %in% c("2013/2014", "2014/2015")) |>
    dplyr::select(
      "YEAR_DESC",
      "ITEM_COUNT",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC) |>
    dplyr::summarise(
      TOTAL_ITEMS = sum(ITEM_COUNT),
      TOTAL_NIC = sum(ITEM_PAY_DR_NIC) / 100) |>
    dplyr:: ungroup() |>
    dplyr::mutate(JOIN_YEAR = as.numeric(substr(YEAR_DESC,1,4)))
  
  #pull data from warehouse
  data <- raw_data |>
    collect()
  
  
  return(data)
  
  
}
