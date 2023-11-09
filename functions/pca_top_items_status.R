pca_top_items_status <- function(con) {
  #extract raw data and sum by exempt status
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY"),YEAR_DESC != "2013/2014") |>
    dplyr::select(
      "YEAR_DESC",
      "PFEA_CHARGE_STATUS",
      "ITEM_COUNT",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC) |>
    dplyr::summarise(EXEMPT_ITEMS = sum(ITEM_COUNT[PFEA_CHARGE_STATUS == "E"]),
                     CHARGE_ITEMS = sum(ITEM_COUNT[PFEA_CHARGE_STATUS %in% c("C","O")]),
                     EXEMPT_ITEMS_PER = sum(ITEM_COUNT[PFEA_CHARGE_STATUS == "E"])/sum(ITEM_COUNT)*100,
                     EXEMPT_NIC = sum(ITEM_PAY_DR_NIC[PFEA_CHARGE_STATUS == "E"]) / 100,
                     CHARGE_NIC = sum(ITEM_PAY_DR_NIC[PFEA_CHARGE_STATUS %in% c("C","O")]) / 100,
                     EXEMPT_NIC_PER = sum(ITEM_PAY_DR_NIC[PFEA_CHARGE_STATUS == "E"])/sum(ITEM_PAY_DR_NIC)*100
    ) |>
    dplyr::ungroup()  |>
    dplyr::arrange(YEAR_DESC)
  #pull data from warehouse
  data <- raw_data |>
    collect()
  
  return(data)
  
}