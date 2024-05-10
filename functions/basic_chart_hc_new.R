basic_chart_hc_new <- function(
    data,
    x, 
    y,
    type = "line",
    xLab = NULL,
    yLab = NULL,
    title = NULL,
    seriesName = "Series 1",
    color = "#005EB8",
    dlOn = TRUE,
    currency = FALSE,
    alt_text = NULL
) {
  
  x <- rlang::enexpr(x)
  y <- rlang::enexpr(y)
  
  font <- "Arial"
  # check currency argument to set symbol
  dlFormatter <- highcharter::JS(
    paste0("function() {
    var ynum = this.point.y;
    var options = { maximumSignificantDigits: 3, minimumSignificantDigits: 3 };
      if (",tolower(as.character(currency)),") {
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
  }")
  )
  
  # check chart type to set grid lines
  #gridlineColor <- ifelse(type == "line", "#e6e6e6", "transparent")
  
  tickColor <- ifelse(type == "line", "#768692", "transparent")
  
  gridlineColor <- "#E8EDEE"
  
  # check chart type to turn on y axis labels
  #yLabels <- ifelse(type == "line", TRUE, FALSE)
  
  chart <- highcharter::highchart() |> 
    highcharter::hc_chart(style = list(fontFamily = font)) |> 
    # add only series
    highcharter::hc_add_series(data = data,
                               name = seriesName,
                               color = color,
                               type = type,
                               highcharter::hcaes(x = !!x,
                                                  y = !!y),
                               groupPadding = 0.1,
                               pointPadding = 0.05,
                               dataLabels = list(enabled = dlOn,
                                                 formatter = dlFormatter,
                                                 style = list(textOutline = "none"))) |> 
    highcharter::hc_xAxis(type = "category",
                          title = list(text = xLab),
                          tickmarkPlacement = "on",
                          tickWidth = 1,
                          tickColor = tickColor,
                          lineWidth = 1,
                          lineColor = "#768692") |> 
    # turn off y axis and grid lines
    highcharter::hc_yAxis(title = list(text = yLab),
                          labels = list(enabled = TRUE),
                          gridLineColor = gridlineColor,
                          lineWidth = 1,
                          lineColor = "#768692") |> 
    highcharter::hc_title(text = title,
                          style = list(fontSize = "16px",
                                       fontWeight = "bold")) |> 
    highcharter::hc_legend(enabled = FALSE) |> 
    highcharter::hc_tooltip(enabled = FALSE) |> 
    highcharter::hc_credits(enabled = TRUE) 
  return(chart)
  
}
