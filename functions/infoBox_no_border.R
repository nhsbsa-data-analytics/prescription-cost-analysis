infoBox_no_border <- function(
    header = "Header here",
    text = "More text here",
    backgroundColour = "#005EB8",
    width = "31%",
    fontColour = "white") {
  
  #set handling for when header is blank
  display <- "block"
  
  if(header == "") {
    display <- "none"
  }
  
  paste(
    "<div class='infobox_no_border',
    style = 'background-color: ",backgroundColour,
    "!important;padding: 10px;
    width: ",width,";
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