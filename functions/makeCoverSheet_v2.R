makeCoverSheet_v2 <- function(spread_sheet_title,
                           spread_sheet_subtitble,
                           date_of_publication,
                           input_workbook,
                           sheet_names,
                           link_text,
                           link_sheets){
  
  
  ## Adding title to Spreadsheet
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = spread_sheet_title,
                      startCol = 1,
                      startRow = 1)
  
  ## Adding sub-title to Spreadsheet
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = spread_sheet_subtitble,
                      startCol = 1,
                      startRow = 2)
  
  
  ## Adding publication date to Spreadsheet
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = date_of_publication,
                      startCol = 1,
                      startRow = 3)
  
  
  ## Adding sub-heading of "contents to Spreadsheet
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Contents:",
                      startCol = 1,
                      startRow = 4)
  
  
  ## Identifying layout/ cell spacing needs
  num_sheets <- length(sheet_names) +6
  count <- 4
  
  ## Inserting sheet names
  for ( i in link_text){
    count <- count + 1
    openxlsx::writeData(input_workbook,
                        sheet = "Cover_sheet",
                        x = i ,
                        startCol = 1,
                        startRow =  count )
  }
  
  
  ## Inserting hyperlinks from cover sheet to sheet tabs
  for(i in 1:length(link_sheets)){
    ## Internal Hyperlink - create hyperlink formula manually
    openxlsx::writeFormula(
      input_workbook,
      "Cover_sheet",
      startRow = i + 4,
      startCol = 1,
      x = openxlsx::makeHyperlinkString(
        sheet = link_sheets[i],
        row = 1,
        col = 1,
        text = link_text[i]
      )
    )
  }
  
  
  ## Inserting contents of cover sheet
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Feedback:",
                      startCol = 1,
                      startRow = (num_sheets))
  
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Feedback is important to us; we welcome any questions and comments relating to these statistics. You can contact us by:",
                      startCol = 1,
                      startRow = (num_sheets+1))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "email:",
                      startCol = 1,
                      startRow = (num_sheets+2))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "statistics@nhsbsa.nhs.uk",
                      startCol = 2,
                      startRow = (num_sheets+2))
  
  x <- "https://online1.snapsurveys.com/Official_Statistics_Feedback"
  names(x) <- "Or you can complete a short feedback survey on our website"
  class(x) <- "hyperlink"
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = x,
                      startCol = 1,
                      startRow = (num_sheets+3))
  
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Media enquires:",
                      startCol = 1,
                      startRow = (num_sheets+4))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "communicationsteam@nhsbsa.nhs.uk",
                      startCol = 1,
                      startRow = (num_sheets+5))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "You can also write to us at:",
                      startCol = 1,
                      startRow = (num_sheets+6))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "NHSBSA - Statistics",
                      startCol = 1,
                      startRow = (num_sheets +7))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "NHS Business Services Authority",
                      startCol = 1,
                      startRow = (num_sheets +8))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Stella House",
                      startCol = 1,
                      startRow = (num_sheets+9))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Goldcrest Way",
                      startCol = 1,
                      startRow = (num_sheets+10))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Riverside",
                      startCol = 1,
                      startRow = (num_sheets+11))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Newcastle upon Tyne",
                      startCol = 1,
                      startRow = (num_sheets+12))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "NE15 8NY",
                      startCol = 1,
                      startRow = (num_sheets+13))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Statistics:",
                      startCol = 1,
                      startRow = (num_sheets+14))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "You may re-use this document/publication (not including logos) free of charge in any format or medium, under the terms of the Open Government Licence v3.0.",
                      startCol = 1,
                      startRow = num_sheets+15)
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "To view this licence visit",
                      startCol = 1,
                      startRow = (num_sheets+16))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "www.nationalarchives.gov.uk/doc/open-government-licence",
                      startCol = 1,
                      startRow = (num_sheets+17))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "or write to the Information Policy Team, The National Archives,",
                      startCol = 1,
                      startRow = (num_sheets+18))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "Kew, Richmond, Surrey, TW9 4DU;",
                      startCol = 1,
                      startRow = (num_sheets+19))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = "or email:",
                      startCol = 1,
                      startRow = (num_sheets+20))
  
  openxlsx::writeData(input_workbook,
                      sheet = "Cover_sheet",
                      x = " psi@nationalarchives.gsi.gov.uk",
                      startCol = 2,
                      startRow = (num_sheets+20))
  
  ## styling for Title
  openxlsx::addStyle(input_workbook,
                     sheet = "Cover_sheet",
                     style = openxlsx::createStyle(fontName = "Arial",
                                                   fontSize = 28,
                                                   textDecoration = "bold"),
                     rows = 1, cols = 1)
  
  
  
  ## Styling for heading
  openxlsx::addStyle(input_workbook,
                     sheet = "Cover_sheet",
                     style = openxlsx::createStyle(fontName = "Arial",
                                                   fontSize = 19,
                                                   textDecoration = "bold"),
                     rows = 2, cols = 1)
  
  
  ## Styling for subtitles
  openxlsx::addStyle(input_workbook,
                     sheet = "Cover_sheet",
                     style = openxlsx::createStyle(fontName = "Arial",
                                                   fontSize = 10,
                                                   textDecoration = "bold"),
                     rows = c(4,
                              num_sheets,
                              num_sheets+2,
                              num_sheets+3,
                              num_sheets+4,
                              num_sheets+14),
                     cols = 1)
  ## Styling for hyperlink
  openxlsx::addStyle(input_workbook,
                     sheet = "Cover_sheet",
                     style = openxlsx::createStyle(fontColour = "#0000EE",
                                                   fontName = "Arial",
                                                   fontSize = 10,
                                                   textDecoration = "bold"),
                     rows = c(num_sheets+3),
                     cols = 1)
  
  #set row heights to 14.5 for accessibility
  openxlsx::setRowHeights(input_workbook, sheet = "Cover_sheet", rows = c(4:(num_sheets+20)), heights = 14.5)
  
}