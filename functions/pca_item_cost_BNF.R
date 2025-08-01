pca_item_cost_BNF <- function(con) {
  #extract raw data
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY")) |>
    dplyr::filter(!YEAR_DESC %in% c("2013/2014", "2014/2015")) |>
    dplyr::select(
      "YEAR_DESC",
      "BNF_CHAPTER",
      "CHAPTER_DESCR",
      "ITEM_COUNT",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC,BNF_CHAPTER,CHAPTER_DESCR) |>
    dplyr::summarise(
      TOTAL_ITEMS = sum(ITEM_COUNT),
      TOTAL_NIC = sum(ITEM_PAY_DR_NIC) / 100) |>
    dplyr::mutate(
      NIC_PER_ITEM = TOTAL_NIC/TOTAL_ITEMS
    ) |>
    dplyr::ungroup()  |>
    dplyr::mutate(FILTER_YEAR = as.numeric(substr(YEAR_DESC,1,4))) |>
    dplyr::filter(
      FILTER_YEAR == min(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) |
        FILTER_YEAR == max(FILTER_YEAR, na.rm = TRUE) - 1
    ) |>
    
    dplyr::select(-FILTER_YEAR) |>
    dplyr::arrange(YEAR_DESC,BNF_CHAPTER)
  
  #pull data from warehouse
  data <- raw_data |>
    collect ()|>
    arrange(YEAR_DESC)
  
  #build column names based on max year
  items_col <- sym(paste0("TOTAL_ITEMS_",max(data$YEAR_DESC)))
  nic_col <- sym(paste0("TOTAL_NIC_",max(data$YEAR_DESC)))
  nic_per_item_col <- sym(paste0("NIC_PER_ITEM_",max(data$YEAR_DESC)))
  select_col <- paste0(max(data$YEAR_DESC),"_")
  
  
  
  #manipulate data as needed
  table <- data |>
    tidyr::pivot_wider(
      names_from = YEAR_DESC,
      values_from = c(TOTAL_ITEMS,TOTAL_NIC,NIC_PER_ITEM)
    ) |>
    
    dplyr::mutate(
      dplyr::across(
        starts_with("TOTAL_ITEMS"),
        .fns = ~!!items_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("TOTAL_ITEMS.*/{1}\\d{4}$"),
        .fns = ~(!!items_col - .x)/.x*100,
        .names = "{.col}_CHANGE"
      ),
      dplyr::across(
        starts_with("TOTAL_NIC"),
        .fns = ~!!nic_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("TOTAL_NIC.*/{1}\\d{4}$"),
        .fns = ~(!!nic_col - .x)/.x*100,
        .names = "{.col}_CHANGE"
      ),
      dplyr::across(
        starts_with("NIC_PER_ITEM"),
        .fns = ~!!nic_per_item_col - .x,
        .names = "{.col}_DIFF"
      ),
      dplyr::across(
        matches("NIC_PER_ITEM.*/{1}\\d{4}$"),
        .fns = ~(!!nic_per_item_col - .x)/.x*100,
        .names = "{.col}_CHANGE"
      ),
    )|>
    
    dplyr::select(-contains(select_col))
  return(table)
  
}