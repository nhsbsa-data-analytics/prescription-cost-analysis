### INFO BOXES

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
  <h4 style = 'color: ", fontColour, ";
  font-weight: bold;
  font-size: 18px;
  margin-top: 0px;
  margin-bottom: 10px;
  display: ", display,";'>", 
  header, "</h4>
  <p style = 'color: ", fontColour, ";
  font-size: 16px;
  margin-top: 0px;
  margin-bottom: 0px;'>", text, "</p>
</div>"
  )
}

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
  <h4 style = 'color: ", fontColour, ";
  font-weight: bold;
  font-size: 18px;
  margin-top: 0px;
  margin-bottom: 10px;
  display: ", display,";'>", 
  header, "</h4>
  <p style = 'color: ", fontColour, ";
  font-size: 16px;
  margin-top: 0px;
  margin-bottom: 0px;'>", text, "</p>
</div>"
  )
}

#-----------------------------------------

# New NI PCA data

northern_irish_pca_extraction_new <- function(link = NULL, file_path = NULL, sheet = 3) {
  
  
  # Extracting total_items and total_costs from URL link
  if (!is.null(link)) {
    
    #Create a temp file using URL link
    
    temp <- tempfile()
    
    ni_url <- utils::download.file(url = link, temp, mode = "wb")
    
    #keep total items and total gross ingredient cost (NIC equivalent)
    #rename columns to TOTAL_ITEMS and TOTAL_COST
    
    ni_pcassfsf <- readxl::read_xlsx(temp,
                                     sheet = sheet,
                                     range = "E3:F3",
                                     col_names = c("TOTAL_ITEMS", "TOTAL_COST"))
    
    #presenting the data
    return(ni_pcassfsf)
    
    
    
    # Extracting total_items and total_costs from file path
  } else if (!is.null(file_path)) {
    
    #keep total items and total gross ingredient cost (NIC equivalent)
    #rename columns to TOTAL_ITEMS and TOTAL_COST
    
    
    ni_pca2 <- readxl::read_excel(file_path,
                                  sheet = sheet,
                                  range = "E3:F3",
                                  col_names = c("TOTAL_ITEMS", "TOTAL_COST"))
    .
    
    #presenting the data
    return(ni_pca2)
    
    
  } else {
    # Return an error message
    stop("Function requires either a link to the Northern Irish PCA data or a file path to the Data")
  }
  
}

# ----------------

#MiSC
round_any <-
  function(x, accuracy, f = round) {
    f(x / accuracy) * accuracy
  }