group_chart_hc_new <- function(data,
                           x,
                           y,
                           type = "line",
                           group,
                           xLab = NULL,
                           yLab = NULL,
                           title = NULL,
                           dlOn = TRUE,
                           currency = FALSE,
                           marker = TRUE) {
  # this function creates a group bar chart with NHSBSA data vis standards
  # applied. includes datalabel formatter to include "£" if needed.
  
  x <- rlang::enexpr(x)
  y <- rlang::enexpr(y)
  
  group <- rlang::enexpr(group)
  
  # set font to arial
  font <- "Arial"
  
  # get number of groups. max number of groups is 9 for unique colors
  num_groups <- length(unique(data[[group]]))
  
  # define a set of colors
  colors <- c("#005eb8", "#ed8b00", "#009639", "#8a1538", "#00a499")
  
  # if there are more groups than colors, recycle the colors
  if (num_groups > length(colors)) {
    colors <- rep(colors, length.out = num_groups)
  }
  
  
  #if there is a 'Total' groups ensure this takes the color black
  if ("Total" %in% unique(data[[group]])) {
    #identify index of "total" group
    total_index <- which(sort(unique(data[[group]])) == "Total")
    
    # add black to location of total_index
    colors <-
      c(colors[1:total_index - 1], "#000000", colors[total_index:length(colors)])
  }
  
  # subset the colors to the number of groups
  #colors <- ifelse(unique(data[[group]]) == "Total", "black", colors[1:num_groups])
  
  # check currency argument to set symbol
  dlFormatter <- highcharter::JS(
    paste0(
      "function() {
    var ynum = this.point.y;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
      if (",
    tolower(as.character(currency)),
    ") {
      options.style = 'currency';
      options.currency = 'GBP';
      }
      if (ynum >= 1000000000) {
        options.maximumSignificantDigits = 4;
        options.minimumSignificantDigits = 4;
      }else {
       options.maximumSignificantDigits = 3;
        options.minimumSignificantDigits = 3;
      }
    return ynum.toLocaleString('en-GB', options);
  }"
    )
  )
  
  
  # ifelse(is.na(str_extract(!!y, "(?<=\\().*(?=,)")),!!y,str_extract(!!y, "(?<=\\().*(?=,)")),
  
  # check chart type to set grid lines
  # gridlineColor <- if (type == "line")
  #   "#e6e6e6"
  # else
  #   "transparent"
  
  # check chart type to turn on y axis labels
  yLabels <- if (type == "line")
    TRUE
  else
    FALSE
  
  tickColor <- ifelse(type == "line", "#768692", "transparent")
  
  gridlineColor <- "#E8EDEE"
  
  # highchart creation
  chart <- highcharter::highchart() |>
    highcharter::hc_chart(style = list(fontFamily = font)) |>
    highcharter::hc_colors(colors) |>
    # add only series
    highcharter::hc_add_series(
      data = data,
      type = type,
      marker = list(enabled = marker),
      highcharter::hcaes(
        x = !!x,
        y = !!y,
        group = !!group
      ),
      groupPadding = 0.1,
      pointPadding = 0.05,
      dataLabels = list(
        enabled = dlOn,
        formatter = dlFormatter,
        style = list(textOutline = "none")
      )
    ) |>
    highcharter::hc_xAxis(type = "category",
                          title = list(text = xLab),
                          tickmarkPlacement = "on",
                          tickWidth = 1,
                          tickColor = tickColor,
                          lineWidth = 1.5,
                          lineColor = tickColor) |>
    # turn off y axis and grid lines
    highcharter::hc_yAxis(
      title = list(text = yLab),
      labels = list(enabled = yLabels),
      gridLineColor = gridlineColor,
      min = 0#,
      #lineWidth = 1,
      #lineColor = tickColor
    ) |>
    highcharter::hc_title(text = title,
                          style = list(fontSize = "16px",
                                       fontWeight = "bold")) |>
    highcharter::hc_legend(enabled = TRUE) |>
    highcharter::hc_tooltip(enabled = FALSE) |>
    highcharter::hc_credits(enabled = TRUE)
  
  # explicit return
  return(chart)
}
