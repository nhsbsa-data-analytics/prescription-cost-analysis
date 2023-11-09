pca_item_generic_bnf <- function(con) {
  #extract raw data
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY"),YEAR_DESC != "2013/2014") |>
    dplyr::filter(!BNF_CHAPTER %in% c("20","21","22","23")) |>
    dplyr::select(
      "YEAR_DESC",
      "BNF_CHAPTER",
      "CHAPTER_DESCR",
      "PRESC_PREP_CLASS",
      "DISP_PREP_CLASS",
      "ITEM_COUNT"
    ) |>
    dplyr::group_by(YEAR_DESC,BNF_CHAPTER,CHAPTER_DESCR) |>
    dplyr::summarise(
      # ITEMS
      PRESC_GEN_ITEMS = sum(ITEM_COUNT[PRESC_PREP_CLASS %in% c("01","02","05")]),
      DISP_GEN_ITEMS = sum(ITEM_COUNT[DISP_PREP_CLASS %in% c("01","05")]),
      TOTAL_ITEMS = sum(ITEM_COUNT)
    ) |>
    dplyr::mutate(PRESC_GEN_ITEMS_PER = PRESC_GEN_ITEMS/TOTAL_ITEMS*100,
                  DISP_GEN_ITEMS_PER = DISP_GEN_ITEMS/TOTAL_ITEMS*100) |>
    dplyr:: ungroup() |>
    dplyr::arrange(YEAR_DESC,BNF_CHAPTER)
  
  #pull data from warehouse
  data <- raw_data |>
    collect()
  
  return(data)
  
}
