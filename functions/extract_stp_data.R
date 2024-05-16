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
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "MYS_SERVICE_TYPE", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, REGION_NAME, REGION_CODE, STP_NAME, 
                      STP_CODE, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS, MYS_SERVICE_TYPE) |>
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
                    "DISP_PREP_CLASS", "PRESC_PREP_CLASS", "MYS_SERVICE_TYPE", "ITEM_COUNT", "ITEM_PAY_DR_NIC",
                    "ITEM_CALC_PAY_QTY") |>
      dplyr::group_by(MONTH_TYPE, YEAR_DESC, REGION_NAME, REGION_CODE, STP_NAME, 
                      STP_CODE, DISP_PRESEN_BNF, DISP_PRESEN_BNF_DESCR, DISP_PRESEN_SNOMED_CODE,
                      DISP_SUPPLIER_NAME, VMPP_UOM, GENERIC_BNF_CODE, 
                      GEN_PRESENTATION_BNF_DESCR, BNF_CHEMICAL_SUBSTANCE, CHEMICAL_SUBSTANCE_BNF_DESCR,
                      BNF_PARAGRAPH, PARAGRAPH_DESCR, BNF_SECTION, SECTION_DESCR, 
                      BNF_CHAPTER, CHAPTER_DESCR, DISP_PREP_CLASS, PRESC_PREP_CLASS, MYS_SERVICE_TYPE) |>
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