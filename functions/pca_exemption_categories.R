pca_exemption_categories <- function(con) {
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY"),YEAR_DESC != "2013/2014") |>
    dplyr::select(
      "YEAR_DESC",
      "PFEA_EXEMPT_CAT",
      "EXEMPT_CAT",
      "ITEM_COUNT",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC, PFEA_EXEMPT_CAT, EXEMPT_CAT) |>
    dplyr::summarise(ITEM_COUNT = sum(ITEM_COUNT),
                     ITEM_PAY_DR_NIC = sum(ITEM_PAY_DR_NIC) / 100
    ) |>
    dplyr::ungroup()  |>
    dplyr::arrange(YEAR_DESC)
  #pull data from warehouse
  data <- raw_data |>
    collect()
  
  return(data)
}