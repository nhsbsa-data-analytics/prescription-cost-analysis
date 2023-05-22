### DWH Data extracts
extract_nat_data <- function(con, year_type = c("financial", "calendar"), year = "year") {
  
  fact_db <- dplyr::tbl(con,
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT"))
  
  if (year_type == "financial") {
    
    #filter for financial year in function call
    
    raw_data <- fact_db |>
      dplyr::filter(MONTH_TYPE == "FY") |>
      dplyr::filter(YEAR_DESC == year) |>
      dplyr::select("MONTH_TYPE", "YEAR_DESC", "DISP_PRESEN_BNF", "DISP_PRESEN_BNF_DESCR", "DISP_PRESEN_SNOMED_CODE",
                    "DISP_SUPPLIER_NAME", "VMPP_UOM", "GENERIC_BNF_CODE", "GEN_PRESENTATION_BNF_DESCR",
                    "BNF_CHEMICAL_SUBSTANCE", "CHEMICAL_SUBSTANCE_BNF_DESCR", "BNF_PARAGRAPH",
                    "PARAGRAPH_DESCR", "BNF_SECTION", "SECTION_DESCR", "BNF_CHAPTER", "CHAPTER_DESCR",
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS) |>
      dplyr::summarise(TOTAL_ITEMS = sum(ITEM_COUNT),
                       TOTAL_QTY = sum(ITEM_CALC_PAY_QTY),
                       TOTAL_NIC = sum(ITEM_PAY_DR_NIC)/100) |>
      ungroup() |>
      dplyr::rename(SECTION_NAME = SECTION_DESCR,
                    SECTION_CODE = BNF_SECTION) |>
      dplyr::arrange(MONTH_TYPE, YEAR_DESC, DISP_PRESEN_BNF, DISP_SUPPLIER_NAME) |>
      collect()
  }
  
  else if (year_type == "calendar") {
    
    #filter for calendar year in function call
    
    raw_data <- fact_db |>
      dplyr::filter(MONTH_TYPE == "CY") |>
      dplyr::filter(YEAR_DESC == year) |>
      dplyr::select("MONTH_TYPE", "YEAR_DESC", "DISP_PRESEN_BNF", "DISP_PRESEN_BNF_DESCR", "DISP_PRESEN_SNOMED_CODE",
                    "DISP_SUPPLIER_NAME", "VMPP_UOM", "GENERIC_BNF_CODE", "GEN_PRESENTATION_BNF_DESCR",
                    "BNF_CHEMICAL_SUBSTANCE", "CHEMICAL_SUBSTANCE_BNF_DESCR", "BNF_PARAGRAPH",
                    "PARAGRAPH_DESCR", "BNF_SECTION", "SECTION_DESCR", "BNF_CHAPTER", "CHAPTER_DESCR",
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS) |>
      dplyr::summarise(TOTAL_ITEMS = sum(ITEM_COUNT),
                       TOTAL_QTY = sum(ITEM_CALC_PAY_QTY),
                       TOTAL_NIC = sum(ITEM_PAY_DR_NIC)/100) |>
      ungroup() |>
      dplyr::rename(SECTION_NAME = SECTION_DESCR,
                    SECTION_CODE = BNF_SECTION) |>
      dplyr::arrange(MONTH_TYPE, YEAR_DESC, DISP_PRESEN_BNF, DISP_SUPPLIER_NAME) |>
      collect()
    
  }
  
  #return data for use in pipeline
  
  return(raw_data)
  
}

extract_stp_data <- function(con, year_type = c("financial", "calendar"), year = "year") {
  
  fact_db <- dplyr::tbl(con,
                        from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT"))
  
  if (year_type == "financial") {
    
    #filter for financial year in function call
    
    raw_data <- fact_db |>
      dplyr::filter(MONTH_TYPE == "FY") |>
      dplyr::filter(YEAR_DESC == year) |>
      dplyr::select("MONTH_TYPE", "YEAR_DESC", "REGION_NAME", "REGION_CODE", "STP_NAME", "STP_CODE",
                    "DISP_PRESEN_BNF", "DISP_PRESEN_BNF_DESCR", "DISP_PRESEN_SNOMED_CODE",
                    "DISP_SUPPLIER_NAME", "VMPP_UOM", "GENERIC_BNF_CODE", "GEN_PRESENTATION_BNF_DESCR",
                    "BNF_CHEMICAL_SUBSTANCE", "CHEMICAL_SUBSTANCE_BNF_DESCR", "BNF_PARAGRAPH",
                    "PARAGRAPH_DESCR", "BNF_SECTION", "SECTION_DESCR", "BNF_CHAPTER", "CHAPTER_DESCR",
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, REGION_NAME, REGION_CODE, STP_NAME, 
                      STP_CODE, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS) |>
      dplyr::summarise(TOTAL_ITEMS = sum(ITEM_COUNT),
                       TOTAL_QTY = sum(ITEM_CALC_PAY_QTY),
                       TOTAL_NIC = sum(ITEM_PAY_DR_NIC)/100) |>
      ungroup() |>
      dplyr::rename(SECTION_NAME = SECTION_DESCR,
                    SECTION_CODE = BNF_SECTION) |>
      dplyr::arrange(MONTH_TYPE, YEAR_DESC, REGION_NAME, STP_NAME, DISP_PRESEN_BNF, DISP_SUPPLIER_NAME) |>
      collect()
    
  }
  
  
  else if (year_type == "calendar") {
    
    #filter for calendar year in function call
    
    raw_data <- fact_db |>
      dplyr::filter(MONTH_TYPE == "CY") |>
      dplyr::filter(YEAR_DESC == year) |>
      dplyr::select("MONTH_TYPE", "YEAR_DESC", "REGION_NAME", "REGION_CODE", "STP_NAME", "STP_CODE",
                    "DISP_PRESEN_BNF", "DISP_PRESEN_BNF_DESCR", "DISP_PRESEN_SNOMED_CODE",
                    "DISP_SUPPLIER_NAME", "VMPP_UOM", "GENERIC_BNF_CODE", "GEN_PRESENTATION_BNF_DESCR",
                    "BNF_CHEMICAL_SUBSTANCE", "CHEMICAL_SUBSTANCE_BNF_DESCR", "BNF_PARAGRAPH",
                    "PARAGRAPH_DESCR", "BNF_SECTION", "SECTION_DESCR", "BNF_CHAPTER", "CHAPTER_DESCR",
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, REGION_NAME, REGION_CODE, STP_NAME, 
                      STP_CODE, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS) |>
      dplyr::summarise(TOTAL_ITEMS = sum(ITEM_COUNT),
                       TOTAL_QTY = sum(ITEM_CALC_PAY_QTY),
                       TOTAL_NIC = sum(ITEM_PAY_DR_NIC)/100) |>
      ungroup() |>
      dplyr::rename(SECTION_NAME = SECTION_DESCR,
                    SECTION_CODE = BNF_SECTION) |>
      dplyr::arrange(MONTH_TYPE, YEAR_DESC, REGION_NAME, STP_NAME, DISP_PRESEN_BNF, DISP_SUPPLIER_NAME) |>
      collect()
    
  }
  
  #return data for use in pipeline
  
  return(raw_data)
  
}

# ------------------

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

#MiSC
round_any <-
  function(x, accuracy, f = round) {
    f(x / accuracy) * accuracy
  }


# aggregation functions 
pca_aggregations <- function(data, area = c("national", "ICB")) {
  
  # rename columns to appear in final output
  
  df <- data %>%
    dplyr::rename(`BNF Presentation Code` = DISP_PRESEN_BNF,
                  `BNF Presentation Name` = DISP_PRESEN_BNF_DESCR,
                  `SNOMED Code` = DISP_PRESEN_SNOMED_CODE,
                  `Supplier Name` = DISP_SUPPLIER_NAME,
                  `Unit of Measure` = VMPP_UOM,
                  `Generic BNF Presentation Code` = GENERIC_BNF_CODE,
                  `Generic BNF Presentation Name` = GEN_PRESENTATION_BNF_DESCR,
                  `BNF Chemical Substance Code` = BNF_CHEMICAL_SUBSTANCE,
                  `BNF Chemical Substance Name` = CHEMICAL_SUBSTANCE_BNF_DESCR,
                  `BNF Paragraph Code` = BNF_PARAGRAPH,
                  `BNF Paragraph Name` = PARAGRAPH_DESCR,
                  `BNF Section Code` = SECTION_CODE,
                  `BNF Section Name` = SECTION_NAME,
                  `BNF Chapter Code` = BNF_CHAPTER,
                  `BNF Chapter Name` = CHAPTER_DESCR,
                  `Preparation Class` = DISP_PREP_CLASS,
                  `Prescribed Preparation Class` = PRESC_PREP_CLASS,
                  `Total Items` = TOTAL_ITEMS,
                  `Total Quantity` = TOTAL_QTY,
                  `Total Cost (GBP)` = TOTAL_NIC)
  
  # create tables based on area argument 
  
  if (area == "national") {
    national_total <- df %>%
      dplyr::group_by(YEAR_DESC) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      # rename YEAR_DESC column  to financial or calendar year 
      # based on MONTH_TYPE column contents
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`)
    
    bnf_chapters <- df %>%
      dplyr::group_by(YEAR_DESC,
                      `BNF Chapter Code`,
                      `BNF Chapter Name`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`)
    
    bnf_sections <- df %>%
      dplyr::group_by(YEAR_DESC,
                      `BNF Section Code`,
                      `BNF Section Name`,
                      `BNF Chapter Code`,
                      `BNF Chapter Name`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`)
    
    bnf_paragraphs <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`)
    
    chemical_substances <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`)
    
    presentations <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `BNF Presentation Code`,
        `BNF Presentation Name`,
        `Unit of Measure`,
        `Generic BNF Presentation Code`,
        `Generic BNF Presentation Name`,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`,
        `Preparation Class`,
        `Prescribed Preparation Class`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (GBP)` = sum(`Total Cost (GBP)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`,
        `Cost Per Quantity (GBP)` = `Total Cost (GBP)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`)
    
    SNOMED_code <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `BNF Presentation Code`,
        `BNF Presentation Name`,
        `SNOMED Code`,
        `Supplier Name`,
        `Unit of Measure`,
        `Generic BNF Presentation Code`,
        `Generic BNF Presentation Name`,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`,
        `Preparation Class`,
        `Prescribed Preparation Class`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (GBP)` = sum(`Total Cost (GBP)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`,
        `Cost Per Quantity (GBP)` = `Total Cost (GBP)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`)
  }
  
  else if (area == "ICB") {
    
    df <- df %>%
      dplyr::rename(`Region Name` = REGION_NAME,
                    `Region Code` = REGION_CODE,
                    `ICB Name` = STP_NAME,
                    `ICB Code` = STP_CODE)
    
    national_total <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`, 
        `Region Code`, 
        `ICB Name`, 
        `ICB Code`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_chapters <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_sections <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_paragraphs <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    chemical_substances <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (GBP)` = sum(`Total Cost (GBP)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    presentations <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Presentation Code`,
        `BNF Presentation Name`,
        `Unit of Measure`,
        `Generic BNF Presentation Code`,
        `Generic BNF Presentation Name`,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`,
        `Preparation Class`,
        `Prescribed Preparation Class`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (GBP)` = sum(`Total Cost (GBP)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`,
        `Cost Per Quantity (GBP)` = `Total Cost (GBP)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    SNOMED_code <- df %>%
      dplyr::select(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `ICB Name`,
        `ICB Code`,
        `BNF Presentation Code`,
        `BNF Presentation Name`,
        `SNOMED Code`,
        `Supplier Name`,
        `Unit of Measure`,
        `Generic BNF Presentation Code`,
        `Generic BNF Presentation Name`,
        `BNF Chemical Substance Code`,
        `BNF Chemical Substance Name`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`,
        `Preparation Class`,
        `Prescribed Preparation Class`,
        `Total Items`,
        `Total Quantity`,
        `Total Cost (GBP)`
      ) %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (GBP)` = `Total Cost (GBP)` / `Total Items`,
        `Cost Per Quantity (GBP)` = `Total Cost (GBP)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
  }
  
  #replace NA with blanks
  national_total[is.na(national_total)] <- ""
  bnf_chapters[is.na(bnf_chapters)] <- ""
  bnf_sections[is.na(bnf_sections)] <- ""
  bnf_paragraphs[is.na(bnf_paragraphs)] <- ""
  chemical_substances[is.na(chemical_substances)] <- ""
  presentations$`Generic BNF Presentation Name`[is.na(presentations$`Generic BNF Presentation Name`)] <- ""
  SNOMED_code$`Generic BNF Presentation Name`[is.na(SNOMED_code$`Generic BNF Presentation Name`)] <- ""
  presentations$`Generic BNF Presentation Name`[is.nan(presentations$`Cost Per Quantity (GBP)`)] <- as.numeric("")
  SNOMED_code$`Generic BNF Presentation Name`[is.nan(SNOMED_code$`Cost Per Quantity (GBP)`)] <- as.numeric("")
  
  summary_tables <-
    list(
      "National"= national_total,
      "BNF_Chapters"= bnf_chapters,
      "BNF_Sections"= bnf_sections,
      "BNF_Paragraphs"= bnf_paragraphs,
      "Chemical_Substances"= chemical_substances,
      "Presentations"= presentations,
      "SNOMED_Code"= SNOMED_code
    )
  return(summary_tables)
}

# ------------------

### CSV Download button
get_download_button <- function(data = data, title = "Download chart data", filename = "data") { 
  dt <- datatable(data, rownames = FALSE,
                  extensions = 'Buttons',
                  options = list(
                    searching = FALSE,
                    paging = TRUE,
                    bInfo = FALSE,
                    pageLength = 1,
                    dom = '<"datatable-wrapper"B>',
                    buttons = list(
                      list(extend = 'csv',
                           text = title,
                           filename = filename,
                           className = "nhs-button-style")
                    ),
                    initComplete = JS(
                      "function(settings, json) {",
                      "$(this.api().table().node()).css('visibility', 'hidden');",
                      "}"
                    )
                  )
  )
  
  return(dt)
}
#---------------

### add_anl_4ii function
pca_exemtion_categories <- function(con) {
raw_data <- dplyr::tbl(con,
                              from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
  dplyr::filter(MONTH_TYPE %in% c("FY"),YEAR_DESC != "2013/2014") |>
  dplyr::select(
    "YEAR_DESC",
    "PFEA_EXEMPT_CAT",
    "EXEMPT_CAT",
    "ITEM_COUNT",
    "ITEM_PAY_DR_NIC"
  ) |>
  dplyr::group_by(YEAR_DESC, PFEA_EXEMPT_CAT, EXEMPT_CAT) |>
  dplyr::summarise(ITEM_COUNT = sum(ITEM_COUNT),
                   ITEM_PAY_DR_NIC = sum(ITEM_PAY_DR_NIC) / 100
  ) |>
  dplyr::ungroup()  |>
  dplyr::arrange(YEAR_DESC)
#pull data from warehouse
data <- raw_data |>
  collect()

return(data)
}
# -----------------------