get_max_dw_cy <- function(con) {
  dplyr::tbl(con,
             from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("CY")) |>
    dplyr::select(YEAR_DESC) |>
    dplyr::filter(YEAR_DESC == max(YEAR_DESC, na.rm = TRUE)) |>
    distinct() |>
    collect() |>
    pull()
}