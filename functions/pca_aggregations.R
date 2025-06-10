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
                  `Advanced Service Type` = MYS_SERVICE_TYPE, 
                  `Total Items` = TOTAL_ITEMS,
                  `Total Quantity` = TOTAL_QTY,
                  `Total Cost (£)` = TOTAL_NIC)
  
  # create tables based on area argument 
  
  if (area == "national") {
    national_total <- df %>%
      dplyr::group_by(YEAR_DESC) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      # rename YEAR_DESC column  to financial or calendar year 
      # based on MONTH_TYPE column contents
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`)
    
    bnf_chapters <- df %>%
      dplyr::group_by(YEAR_DESC,
                      `BNF Chapter Code`,
                      `BNF Chapter Name`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`)
    
    bnf_sections <- df %>%
      dplyr::group_by(YEAR_DESC,
                      `BNF Section Code`,
                      `BNF Section Name`,
                      `BNF Chapter Code`,
                      `BNF Chapter Name`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`)
    
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`)
    
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`)
    
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
        `Prescribed Preparation Class`,
        `Advanced Service Type`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (£)` = sum(`Total Cost (£)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
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
        `Prescribed Preparation Class`,
        `Advanced Service Type`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (£)` = sum(`Total Cost (£)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`)
  }
  
  else if (area == "regional") {
    
    df <- df %>%
      dplyr::rename(`Region Name` = REGION_NAME,
                    `Region Code` = REGION_CODE,)
    
    national_total <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`, 
        `Region Code`) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_chapters <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_sections <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    bnf_paragraphs <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
        `BNF Paragraph Code`,
        `BNF Paragraph Name`,
        `BNF Section Code`,
        `BNF Section Name`,
        `BNF Chapter Code`,
        `BNF Chapter Name`
      ) %>%
      dplyr::summarise(`Total Items` = sum(`Total Items`),
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    chemical_substances <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    presentations <- df %>%
      dplyr::group_by(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
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
        `Prescribed Preparation Class`,
        `Advanced Service Type`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (£)` = sum(`Total Cost (£)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
    
    SNOMED_code <- df %>%
      dplyr::select(
        YEAR_DESC,
        `Region Name`,
        `Region Code`,
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
        `Advanced Service Type`,
        `Total Items`,
        `Total Quantity`,
        `Total Cost (£)`
      ) %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
        `Quantity Per Item` = `Total Quantity` / `Total Items`) %>%
      dplyr::arrange(`Region Code`)
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
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
                       `Total Cost (£)` = sum(`Total Cost (£)`)) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(`Cost Per Item (£)` = `Total Cost (£)` / `Total Items`) %>%
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
        `Prescribed Preparation Class`,
        `Advanced Service Type`
      ) %>%
      dplyr::summarise(
        `Total Items` = sum(`Total Items`),
        `Total Quantity` = sum(`Total Quantity`),
        `Total Cost (£)` = sum(`Total Cost (£)`)
      ) %>%
      ungroup() %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
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
        `Advanced Service Type`,
        `Total Items`,
        `Total Quantity`,
        `Total Cost (£)`
      ) %>%
      {if ("FY" %in% df$MONTH_TYPE) dplyr::rename(.,`Financial Year` = YEAR_DESC) else .} %>%
      {if ("CY" %in% df$MONTH_TYPE) dplyr::rename(.,`Calendar Year` = YEAR_DESC) else .} %>%
      dplyr::mutate(
        `Cost Per Item (£)` = `Total Cost (£)` / `Total Items`,
        `Cost Per Quantity (£)` = `Total Cost (£)` / `Total Quantity`,
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
  presentations$`Generic BNF Presentation Name`[is.nan(presentations$`Cost Per Quantity (£)`)] <- as.numeric("")
  SNOMED_code$`Generic BNF Presentation Name`[is.nan(SNOMED_code$`Cost Per Quantity (£)`)] <- as.numeric("")
  
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