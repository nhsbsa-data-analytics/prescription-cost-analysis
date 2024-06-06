infoBox_border <- function(
    header = "Header here",
    text = "More text here",
    backgroundColour = "#ccdff1",
    borderColour = "#005EB8",
    width = "31%",
    fontColour = "black") {
  
  #set handling for when header is blank
  display <- "block"
  
  if(header == "") {
    display <- "none"
  }
  
  paste(
    "<div class='infobox_border' style = 'border: 1px solid ", borderColour,"!important;
  border-left: 5px solid ", borderColour,"!important;
  background-color: ", backgroundColour,"!important;
  padding: 10px;
  width: ", width,"!important;
  display: inline-block;
  vertical-align: top;
  flex: 1;
  height: 100%;'>
  <p style = 'color: ", fontColour, ";
  font-weight: bold;
  font-size: 18px;
  margin-top: 0px;
  margin-bottom: 10px;
  display: ", display,";'>", 
  header, "</p>
  <p style = 'color: ", fontColour, ";
  font-size: 16px;
  margin-top: 0px;
  margin-bottom: 0px;'>", text, "</p>
</div>"
  )
}