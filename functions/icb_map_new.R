icb_map_new <- function(data,
                    icb_code_column,
                    value_column,
                    geo_data,
                    icb_lsoa_lookup,
                    lsoa_population,
                    currency,
                    scale_rounding) {
  # include round any function to calculate min and max values to use in scales
  round_any <-
    function(x, accuracy, f = round) {
      f(x / accuracy) * accuracy
    }
  
  # build ibc population lookup
  icb_pop <- icb_lsoa_lookup |>
    dplyr::left_join(lsoa_population,
                     by = c("LSOA_CODE" = "LSOA_CODE")) |>
    dplyr::group_by(ICB_CODE, ICB_NAME, ICB_LONG_CODE) |>
    dplyr::summarise(POP = sum(POP, na.rm = TRUE),
                     .groups = "drop")
  
  # build raw data needed
  data_df <- data |>
    dplyr::select(glue::glue_collapse(icb_code_column),
                  glue::glue_collapse(value_column)) |>
    dplyr::rename(ICB_CODE = 1,
                  VALUE = 2) |>
    dplyr::group_by(ICB_CODE) |>
    dplyr::summarise(VALUE = sum(VALUE, na.rm = T),
                     .groups = "drop") |>
    dplyr::left_join(icb_pop,
                     by = c("ICB_CODE" = "ICB_CODE")) |>
    dplyr::mutate("TOTAL_ITEMS_PER_POP" = VALUE / POP)
  
  if (currency) {
    # calculate national mean
    mean <- paste0("£",round(sum(data_df$VALUE) / sum(data_df$POP), 2))
    prefix <- "£"
    legend_title <- "NIC (£)"
  } else {
    mean <- round(sum(data_df$VALUE) / sum(data_df$POP), 1)
    prefix <- ""
    legend_title <- "Items"
  }
  
  map <- highcharter::highchart() %>%
    highcharter::hc_title(text = "") %>%
    highcharter::hc_subtitle(text = paste0("National mean: ", mean)) %>%
    highcharter::hc_add_series_map(
      map = geo_data,
      df = data_df,
      name = "",
      value = "TOTAL_ITEMS_PER_POP",
      joinBy = c("SUB_GEOGRAPHY_CODE", "ICB_LONG_CODE"),
      tooltip = list(
        headerFormat = "",
        pointFormat = paste0(
          "<b>{point.properties.SUB_GEOGRAPHY_NAME}:<br><b>{point.value}"
        )
      )
    ) %>%
    highcharter:: hc_colorAxis(
      minColor = "#fff",
      maxColor = "#330072",
      min = round_any(min(data_df$TOTAL_ITEMS_PER_POP), scale_rounding, floor),
      max = round_any(max(data_df$TOTAL_ITEMS_PER_POP), scale_rounding, ceiling)
    ) %>%
    highcharter::hc_legend(verticalAlign = "bottom",
                           title = list(text = legend_title)) %>%
    highcharter::hc_tooltip(valueDecimals = 0,
                            valuePrefix = prefix) %>%
    highcharter::hc_mapNavigation(
      enabled = TRUE,
      enableMouseWheelZoom = TRUE,
      enableDoubleClickZoom = TRUE
    )|>
    highcharter::hc_credits(enabled = TRUE)
  
  return(map)
}
