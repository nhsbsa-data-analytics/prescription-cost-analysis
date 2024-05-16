sheetNames_main <-
  c(
    "National",
    "BNF_Chapters",
    "BNF_Sections",
    "BNF_Paragraphs",
    "Chemical_Substances",
    "Presentations",
    "SNOMED_Codes"
  )

#create metadata tab (will need to open file and auto row heights once ran)
meta_fields <- c(
  "Advanced Service Type",
  "BNF Chapter Code",
  "BNF Chapter Name",
  "BNF Chemical Substance Code",
  "BNF Chemical Substance Name",
  "BNF Paragraph Code",
  "BNF Paragraph Name",
  "BNF Presentation Code",
  "BNF Presentation Name",
  "BNF Section Code",
  "BNF Section Name",
  "Cost Per Item (GBP)",
  "Cost Per Quantity (GBP)",
  "Financial Year",
  "Generic BNF Presentation Code",
  "Generic BNF Presentation Name",
  "Preparation Class",
  "Prescribed Preparation Class",
  "Quantity Per Item",
  "SNOMED Code",
  "Supplier Name",
  "Total Cost (GBP)",
  "Total Items",
  "Total Quantity",
  "Unit of Measure"
)

meta_descs <-
  c(
    "The type of advanced service an item has been issued through.",
    "The unique code used to refer to the British National Formulary (BNF) chapter.",
    "The name given to a British National Formulary (BNF) chapter. This is the broadest grouping of the BNF therapeutical classification system.",
    "The unique code used to refer to the British National Formulary (BNF) chemical substance.",
    "The name of the main active ingredient in a drug. Appliances do not hold a chemical substance, but instead inherit the corresponding BNF section. Determined by the British National Formulary (BNF) for drugs, or the NHS BSA for appliances. For example, Amoxicillin.",
    "The unique code used to refer to the British National Formulary (BNF) paragraph.",
    "The name given to the British National Formulary (BNF) paragraph. This level of grouping of the BNF Therapeutical classification system sits below BNF section.",
    "The unique code used to refer to the British National Formulary (BNF) presentation.",
    "The name given to the specific type, strength, and formulation of a drug; or, the specific type of an appliance. For example, Paracetamol 500mg tablets.",
    "The unique code used to refer to the British National Formulary (BNF) section.",
    "The name given to a British National Formulary (BNF) section. This is the next broadest grouping of the BNF therapeutical classification system after chapter.",
    "Cost per item is calculated by dividing the 'Total Cost (GBP)' by the number of 'Total Items'.",
    "Cost per quantity is calculated by dividing the 'Total Cost (GBP)' by the 'Total Quantity'.",
    "The financial year to which the data belongs.",
    "In the cases of proprietary drugs, their generic equivalent BNF presentation code. For generic drugs, a repeat of the already provided BNF code.",
    "In the cases of proprietary drugs, their generic equivalent BNF presentation name. For generic drugs, a repeat of the already provided BNF name.",
    "The NHSBSA specifies and maintains the preparation classes of drugs, appliances, and medical devices to more easily distinguish between generic, proprietary, and appliance products. A product can be classified in one of five ways:\n
Class 1 - drugs prescribed and available generically
Class 2 - drugs prescribed generically but only available as a proprietary product
Class 3 - drugs prescribed and dispensed by proprietary brand name
Class 4 - dressings, appliances, and medical devices
Class 5 - drugs prescribed generically with a named supplier",
"The preparation class of the product listed on the prescription form. Used to determine if an item was prescribed generically.",
"Quantity Per Item is calculated by dividing the 'Total Quantity' by the number of 'Total Items'.",
"A SNOMED CT (Systemised Nomenclature of Medicine Clinical Terms) is a clinical vocabulary readable by computers. The SNOMED code contained within the data is a unique identifier for each Medicinal Product (both VMP and AMP level). The identifier will not be re-used and or allocated to another presentation.",
"The name of the manufacturer or wholesaler of a product. For example, TEVA or A A H Pharmaceuticals.",
"Total Cost is the amount that would be paid using the basic price of the prescribed drug or appliance and the quantity prescribed. Sometimes called the 'Net Ingredient Cost' (NIC). The basic price is given either in the Drug Tariff or is determined from prices published by manufacturers, wholesalers or suppliers. Basic price is set out in Parts 8 and 9 of the Drug Tariff. For any drugs or appliances not in Part 8, the price is usually taken from the manufacturer, wholesaler or supplier of the product. This is given in GBP.",
"The number of prescription items dispensed. 'Items' is the number of times a product appears on a prescription form. Prescription forms include both paper prescriptions and electronic messages.",
"The total quantity of a drug or appliance that was prescribed. This is calculated by multiplying Quantity by Items. For example, if 2 items of Paracetamol 500mg tablets with a quantity of 28 were prescribed, the total quantity will be 56.",
"The unit of measure given to the smallest available unit of a product. For example, tablet, capsule, unit dose, vial, gram, millilitre etc."
  )

# 1 .create national excel for fy ------
#
#create workbook and meta data
fy_nat_wb <- accessibleTables::create_wb(sheetNames_main)

accessibleTables::create_metadata(fy_nat_wb,
                                  meta_fields,
                                  meta_descs)

#### National tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "National",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " overall totals"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_fy_agg$National,
  13
)

#left align column A
accessibleTables::format_data(fy_nat_wb,
                              "National",
                              c("A"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "National",
                              c("B"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "National",
                              c("C", "D"),
                              "right",
                              "#,##0.00")

#### BNF CHAPTER tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "BNF_Chapters",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF chapter"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_fy_agg$BNF_Chapters,
  13
)

#left align column A
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Chapters",
                              c("A", "B", "C"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Chapters",
                              c("D"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Chapters",
                              c("E", "F"),
                              "right",
                              "#,##0.00")

#### BNF SECTION tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "BNF_Sections",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF section"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_fy_agg$BNF_Sections,
  13
)

#left align column A
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Sections",
                              c("A", "B", "C", "D", "E"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Sections",
                              c("F"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Sections",
                              c("G", "H"),
                              "right",
                              "#,##0.00")

#### BNF PARAGRAPH tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "BNF_Paragraphs",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF Paragraph"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_fy_agg$BNF_Paragraphs,
  13
)

#left align column A
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Paragraphs",
                              c("A", "B", "C", "D", "E", "F", "G"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Paragraphs",
                              c("H"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "BNF_Paragraphs",
                              c("I", "J"),
                              "right",
                              "#,##0.00")

#### CHEMICAL SUBSTANCE tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "Chemical_Substances",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF Chemical Substance"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_fy_agg$Chemical_Substances,
  13
)

#left align column A
accessibleTables::format_data(
  fy_nat_wb,
  "Chemical_Substances",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "Chemical_Substances",
                              c("J"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "Chemical_Substances",
                              c("K", "L"),
                              "right",
                              "#,##0.00")

#### PRESENTATIONS tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "Presentations",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF presentation"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  nat_data_fy_agg$Presentations,
  13
)

#left align column A
accessibleTables::format_data(
  fy_nat_wb,
  "Presentations",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P", 
    "Q"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "Presentations",
                              c("R", "S"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "Presentations",
                              c("T", "U", "V", "W"),
                              "right",
                              "#,##0.00")

#### SNOMED tab
# write data to sheet
accessibleTables::write_sheet(
  fy_nat_wb,
  "SNOMED_Codes",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by SNOMED code"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  nat_data_fy_agg$SNOMED_Code,
  13
)

#left align column A
accessibleTables::format_data(
  fy_nat_wb,
  "SNOMED_Codes",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_nat_wb,
                              "SNOMED_Codes",
                              c("T", "U"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_nat_wb,
                              "SNOMED_Codes",
                              c("V", "W", "X", "Y"),
                              "right",
                              "#,##0.00")

accessibleTables::makeCoverSheet(
  paste0("Prescription Cost Analysis - England ", max_data_fy),
  paste0("Statistical Summary Tables - Financial Year ",max_data_fy ," - National level"),
  paste0("Publication date: ", config$publication_date),
  fy_nat_wb,
  sheetNames_main,
  c(
    "Metadata",
    "Table 1: National level data",
    "Table 2: BNF chapter level data",
    "Table 3: BNF section level data",
    "Table 4: BNF paragraph level data",
    "Table 5: BNF chemical substance level data",
    "Table 6: BNF presentation level data",
    "Table 7: SNOMED level data"
  ),
  c("Metadata", sheetNames_main)
)


#save file into outputs folder
openxlsx::saveWorkbook(
  fy_nat_wb,
  #automate names
  paste0(
    "outputs/pca_summary_tables_",
    substr(max_data_fy, 1, 4),
    "_",
    substr(max_data_fy, 8, 9),
    "_v001.xlsx"
  ),
  overwrite = TRUE
)


# 2. create national excel for cy ------
#create workbook and meta data
cy_nat_wb <- create_wb(sheetNames_main)

create_metadata(cy_nat_wb,
                meta_fields,
                meta_descs)

#### National tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "National",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " overall totals"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_cy_agg$National,
  13
)

#left align column A
accessibleTables::format_data(cy_nat_wb,
                              "National",
                              c("A"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "National",
                              c("B"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "National",
                              c("C", "D"),
                              "right",
                              "#,##0.00")

#### BNF CHAPTER tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "BNF_Chapters",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF chapter"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_cy_agg$BNF_Chapters,
  13
)

#left align column A
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Chapters",
                              c("A", "B", "C"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Chapters",
                              c("D"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Chapters",
                              c("E", "F"),
                              "right",
                              "#,##0.00")

#### BNF SECTION tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "BNF_Sections",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF section"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_cy_agg$BNF_Sections,
  13
)

#left align column A
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Sections",
                              c("A", "B", "C", "D", "E"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Sections",
                              c("F"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Sections",
                              c("G", "H"),
                              "right",
                              "#,##0.00")

#### BNF PARAGRAPH tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "BNF_Paragraphs",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF Paragraph"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_cy_agg$BNF_Paragraphs,
  13
)

#left align column A
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Paragraphs",
                              c("A", "B", "C", "D", "E", "F", "G"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Paragraphs",
                              c("H"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "BNF_Paragraphs",
                              c("I", "J"),
                              "right",
                              "#,##0.00")

#### CHEMICAL SUBSTANCE tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "Chemical_Substances",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF Chemical Substance"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  nat_data_cy_agg$Chemical_Substances,
  13
)

#left align column A
accessibleTables::format_data(
  cy_nat_wb,
  "Chemical_Substances",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "Chemical_Substances",
                              c("J"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "Chemical_Substances",
                              c("K", "L"),
                              "right",
                              "#,##0.00")

#### PRESENTATIONS tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "Presentations",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF presentation"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  nat_data_cy_agg$Presentations,
  13
)

#left align column A
accessibleTables::format_data(
  cy_nat_wb,
  "Presentations",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "Presentations",
                              c("R", "S"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "Presentations",
                              c("T", "U", "V", "W"),
                              "right",
                              "#,##0.00")

#### SNOMED tab
# write data to sheet
accessibleTables::write_sheet(
  cy_nat_wb,
  "SNOMED_Codes",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF presentation"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  nat_data_cy_agg$SNOMED_Code,
  13
)

#left align column A
accessibleTables::format_data(
  cy_nat_wb,
  "SNOMED_Codes",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_nat_wb,
                              "SNOMED_Codes",
                              c("T", "U"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_nat_wb,
                              "SNOMED_Codes",
                              c("V", "W", "X", "Y"),
                              "right",
                              "#,##0.00")

accessibleTables::makeCoverSheet(
  paste0("Prescription Cost Analysis - England ", max_data_fy),
  paste0("Statistical Summary Tables - Calendar Year ",max_data_cy ," - National level"),
  paste0("Publication date: ", config$publication_date),
  cy_nat_wb,
  sheetNames_main,
  c(
    "Metadata",
    "Table 1: National level data",
    "Table 2: BNF chapter level data",
    "Table 3: BNF section level data",
    "Table 4: BNF paragraph level data",
    "Table 5: BNF chemical substance level data",
    "Table 6: BNF presentation level data",
    "Table 7: SNOMED level data"
  ),
  c("Metadata", sheetNames_main)
)

#save file into outputs folder
openxlsx::saveWorkbook(
  cy_nat_wb,
  #automate names
  paste0("outputs/pca_summary_tables_",
         max_data_cy,
         "_v001.xlsx"),
  overwrite = TRUE
)

# 3. create stp excel for fy ------

#create workbook and meta data
fy_stp_wb <- create_wb(sheetNames_main)

create_metadata(fy_stp_wb,
                meta_fields,
                meta_descs)

#### National tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "National",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " overall totals"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_fy_agg$National,
  13
)

#left align column A to E
accessibleTables::format_data(fy_stp_wb,
                              "National",
                              c("A", "B", "C", "D", "E"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "National",
                              c("F"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "National",
                              c("G", "H"),
                              "right",
                              "#,##0.00")


#### BNF CHAPTER tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "BNF_Chapters",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF chapter"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_fy_agg$BNF_Chapters,
  13
)

#left align column A
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Chapters",
                              c("A", "B", "C", "D", "E", "F", "G"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Chapters",
                              c("H"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Chapters",
                              c("I", "J"),
                              "right",
                              "#,##0.00")

#### BNF SECTION tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "BNF_Sections",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF section"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_fy_agg$BNF_Sections,
  13
)

#left align column A
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Sections",
                              c("A", "B", "C", "D", "E", "F", "G", "H", "I"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Sections",
                              c("J"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Sections",
                              c("K", "L"),
                              "right",
                              "#,##0.00")

#### BNF PARAGRAPH tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "BNF_Paragraphs",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF Paragraph"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_fy_agg$BNF_Paragraphs,
  13
)

#left align column A
accessibleTables::format_data(
  fy_stp_wb,
  "BNF_Paragraphs",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Paragraphs",
                              c("L"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "BNF_Paragraphs",
                              c("M", "N"),
                              "right",
                              "#,##0.00")

#### CHEMICAL SUBSTANCE tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "Chemical_Substances",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF Chemical Substance"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_fy_agg$Chemical_Substances,
  13
)

#left align column A
accessibleTables::format_data(
  fy_stp_wb,
  "Chemical_Substances",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "Chemical_Substances",
                              c("N"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "Chemical_Substances",
                              c("O", "P"),
                              "right",
                              "#,##0.00")


#### PRESENTATIONS tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "Presentations",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by BNF presentation"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  stp_data_fy_agg$Presentations,
  13
)

#left align column A
accessibleTables::format_data(
  fy_stp_wb,
  "Presentations",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "Presentations",
                              c("V", "W"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "Presentations",
                              c("X", "Y", "Z", "AA"),
                              "right",
                              "#,##0.00")

#### PRESENTATIONS tab
# write data to sheet
accessibleTables::write_sheet(
  fy_stp_wb,
  "SNOMED_Codes",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_fy,
    " totals by SNOMED code"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  stp_data_fy_agg$SNOMED_Code,
  13
)

#left align column A
accessibleTables::format_data(
  fy_stp_wb,
  "SNOMED_Codes",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V", 
    "W"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(fy_stp_wb,
                              "SNOMED_Codes",
                              c("X", "Y"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(fy_stp_wb,
                              "SNOMED_Codes",
                              c("Z", "AA", "AB", "AC"),
                              "right",
                              "#,##0.00")

accessibleTables::makeCoverSheet(
  paste0("Prescription Cost Analysis - England ", max_data_fy),
  paste0("Statistical Summary Tables - Financial Year ",max_data_fy ," - ICB level"),
  paste0("Publication date: ", config$publication_date),
  fy_stp_wb,
  sheetNames_main,
  c(
    "Metadata",
    "Table 1: National level data",
    "Table 2: BNF chapter level data",
    "Table 3: BNF section level data",
    "Table 4: BNF paragraph level data",
    "Table 5: BNF chemical substance level data",
    "Table 6: BNF presentation level data",
    "Table 7: SNOMED level data"
  ),
  c("Metadata", sheetNames_main)
)


#save file into outputs folder
openxlsx::saveWorkbook(
  fy_stp_wb,
  #automate names
  paste0(
    "outputs/pca_icb_summary_tables_",
    substr(max_data_fy, 1, 4),
    "_",
    substr(max_data_fy, 8, 9),
    "_v001.xlsx"
  ),
  overwrite = TRUE
)

# 4. create stp excel for cy ------

#create workbook and meta data
cy_stp_wb <- create_wb(sheetNames_main)

create_metadata(cy_stp_wb,
                meta_fields,
                meta_descs)

#### National tab
accessibleTables::write_sheet(
  cy_stp_wb,
  "National",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " overall totals"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_cy_agg$National,
  13
)

#left align column A to E
accessibleTables::format_data(cy_stp_wb,
                              "National",
                              c("A", "B", "C", "D", "E"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "National",
                              c("F"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "National",
                              c("G", "H"),
                              "right",
                              "#,##0.00")


#### BNF CHAPTER tab
# write data to sheet
accessibleTables::write_sheet(
  cy_stp_wb,
  "BNF_Chapters",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF chapter"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_cy_agg$BNF_Chapters,
  13
)

#left align column A
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Chapters",
                              c("A", "B", "C", "D", "E", "F", "G"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Chapters",
                              c("H"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Chapters",
                              c("I", "J"),
                              "right",
                              "#,##0.00")

#### BNF SECTION tab
# write data to sheet
accessibleTables::write_sheet(
  cy_stp_wb,
  "BNF_Sections",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF section"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_cy_agg$BNF_Sections,
  13
)

#left align column A
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Sections",
                              c("A", "B", "C", "D", "E", "F", "G", "H", "I"),
                              "left",
                              "")

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Sections",
                              c("J"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Sections",
                              c("K", "L"),
                              "right",
                              "#,##0.00")

#### BNF PARAGRAPH tab
# write data to sheet
accessibleTables::write_sheet(
  cy_stp_wb,
  "BNF_Paragraphs",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF Paragraph"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_cy_agg$BNF_Paragraphs,
  13
)

#left align column A
accessibleTables::format_data(
  cy_stp_wb,
  "BNF_Paragraphs",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Paragraphs",
                              c("L"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "BNF_Paragraphs",
                              c("M", "N"),
                              "right",
                              "#,##0.00")

#### CHEMICAL SUBSTANCE tab
# write data to sheet
accessibleTables::write_sheet(
  cy_stp_wb,
  "Chemical_Substances",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF Chemical Substance"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence."
  ),
  stp_data_cy_agg$Chemical_Substances,
  13
)

#left align column A
accessibleTables::format_data(
  cy_stp_wb,
  "Chemical_Substances",
  c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M"),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "Chemical_Substances",
                              c("N"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "Chemical_Substances",
                              c("O", "P"),
                              "right",
                              "#,##0.00")

#### PRESENTATIONS tab
# write data to sheet
accessibleTables::write_sheet(
  cy_stp_wb,
  "Presentations",
  paste0(
    "Prescription Cost Analysis - England ",
    max_data_cy,
    " totals by BNF presentation"
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different summary tables. Costs are rounded to the nearest pence.",
    "Some products may appear with an item count and 0 quantity and 0 cost. It is possible for prescriptions to be issued with a prescribed quantity of 0, when these items are processed by the NHSBSA reimbursement is done so within the framework as set out in the Drug Tariff for England and Wales."
  ),
  stp_data_cy_agg$Presentations,
  13
)

#left align column A
accessibleTables::format_data(
  cy_stp_wb,
  "Presentations",
  c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U"
  ),
  "left",
  ""
)

#right align column B and format number
accessibleTables::format_data(cy_stp_wb,
                              "Presentations",
                              c("V", "W"),
                              "right",
                              "#,##0")

#right align column C and D and format numbers
accessibleTables::format_data(cy_stp_wb,
                              "Presentations",
                              c("X", "Y", "Z","AA"),
                              "right",
                              "#,##0.00")

#save file into outputs folder
openxlsx::saveWorkbook(
  cy_stp_wb,
  #automate names
  paste0("outputs/pca_icb_summary_tables_",
         max_data_cy,
         "_v001.xlsx"),
  overwrite = TRUE
)

# 5. create additional analysis excel ------

#create workbook and meta data
sheetNames_add_anl <- c(
  "Table_A1",
  "Table_A2",
  "Table_A3",
  "Table_A4",
  "Table_A5",
  "Table_A6",
  "Table_A7",
  "Table_A8",
  "Table_A9",
  "Table_A10",
  "Table_A11",
  "Table_A12",
  "Table_A13",
  "Table_A14"
)

add_anl_wb <- create_wb(sheetNames_add_anl)

meta_fields_add_anl <- c(
  "BNF Chapter Code",
  "BNF Chapter Name",
  "BNF Chemical Substance Code",
  "BNF Chemical Substance Name",
  "BNF Presentation Code",
  "BNF Presentation Name",
  "BNF Section Code",
  "BNF Section Name",
  "Change in Cost Per Item YYYY to YYYY (%)",
  "Change in Cost Per Item YYYY to YYYY (GBP)",
  "Change in Costs YYYY to YYYY (%)",
  "Change in Costs YYYY to YYYY (GBP)",
  "Change in Items YYYY to YYYY",
  "Change in Items YYYY to YYYY (%)",
  "Change YYYY to YYYY",
  "Change YYYY to YYYY (%)",
  "Change YYYY to YYYY (GBP)",
  "Cost of dressings and appliances (GBP)",
  "Cost of items prescribed and dispensed generically (%)",
  "Cost of items prescribed and dispensed generically (GBP)",
  "Cost of items prescribed and dispensed proprietary (%)",
  "Cost of items prescribed and dispensed proprietary (GBP)",
  "Cost of items prescribed generically (%)",
  "Cost of items prescribed generically (GBP)",
  "Cost of items prescribed generically, dispensed and reimbursed as proprietary (%)",
  "Cost of items prescribed generically, dispensed and reimbursed as proprietary (GBP)",
  "Cost Per Capita (GBP)",
  "Cost per dressing and appliance (GBP)",
  "Cost Per Item (GBP)",
  "Cost per item prescribed and dispensed generically (GBP)",
  "Cost per item prescribed and dispensed proprietary (GBP)",
  "Cost per item prescribed generically, dispensed and reimbursed as proprietary (GBP)",
  "Cost per item YYYY (GBP)",
  "Dressings and appliances",
  "England population",
  "Exempt Cost (%)",
  "Exempt Items (%)",
  "Financial Year",
  "Items dispensed generically",
  "Items dispensed generically (%)",
  "Items Per Capita",
  "Items prescribed and dispensed generically",
  "Items prescribed and dispensed generically (%)",
  "Items prescribed and dispensed proprietary",
  "Items prescribed and dispensed proprietary (%)",
  "Items prescribed generically",
  "Items prescribed generically (%)",
  "Items prescribed generically, dispensed and reimbursed as proprietary",
  "Items prescribed generically, dispensed and reimbursed as proprietary (%)",
  "Rank YYYY",
  "Total Charged Cost (GBP)",
  "Total Charged Items",
  "Total Cost (GBP)",
  "Total Cost YYYY (GBP)",
  "Total Exempt Cost (GBP)",
  "Total Exempt Items",
  "Total Items",
  "Total Items YYYY",
  "Unit Cost",
  "Unit of Measure"
)

meta_descs_add_anl <- c(
  "The unique code used to refer to the British National Formulary (BNF) chapter.",
  "The name given to a British National Formulary (BNF) chapter. This is the broadest grouping of the BNF therapeutical classification system.",
  "The unique code used to refer to the British National Formulary (BNF) chemical substance.",
  "The name of the main active ingredient in a drug. Appliances do not hold a chemical substance, but instead inherit the corresponding BNF section. Determined by the British National Formulary (BNF) for drugs, or the NHS BSA for appliances. For example, Amoxicillin.",
  "The unique code used to refer to the British National Formulary (BNF) presentation.",
  "The name given to the specific type, strength, and formulation of a drug; or, the specific type of an appliance. For example, Paracetamol 500mg tablets.",
  "The unique code used to refer to the British National Formulary (BNF) section.",
  "The name give to a British National Formulary (BNF) section. This is the next broadest grouping of the BNF Therapeutical classification system after chapter.",
  "The difference in 'Cost Per Item (GBP)' between the financial years displayed expressed as a percentage.",
  "The difference in 'Cost Per Item (GBP)' between the financial years displayed.",
  "The difference in 'Total Cost (GBP)' between the financial years displayed expressed as a percentage.",
  "The difference in 'Total Cost (GBP)' between the financial years displayed.",
  "The difference in 'Total Items' between the financial years displayed.",
  "The difference in 'Total Items' between the financial years displayed expressed as a percentage.",
  "The difference between the measures listed (e.g. Items or Cost) for the financial years displayed.",
  "The difference between the measures listed (e.g. Items or Cost) for the financial years displayed expressed as a percentage.",
  "The difference between the measures listed (e.g. Items or Cost) for the financial years displayed. Displayed as GBP.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 4.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 1 expressed as a percentage.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 1.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 3 expressed as a percentage.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 3.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 1 or 2 expressed as percentage.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 1 or 2.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 2 expressed as a percentage.",
  "The 'Total Cost (GBP)' of prescription items with a preparation class of 2.",
  "Cost per capita is calculated by dividing the 'Total Cost (GBP)' by the 'England population'.",
  "Cost per dressing and appliance is calculated by dividing the 'Total Cost (GBP)' of dressings and appliances by the number of 'Total Items' for dressings and appliances.",
  "Cost per item is calculated by dividing the 'Total Cost (GBP)' by the number of 'Total Items'.",
  "This is calculated by dividing the relevant 'Total Cost (GBP)' by the relevant number of 'Total Items'.",
  "This is calculated by dividing the relevant 'Total Cost (GBP)' by the relevant number of 'Total Items'.",
  "This is calculated by dividing the relevant 'Total Cost (GBP)' by the relevant number of 'Total Items'.",
  "This is calculated by dividing the relevant 'Total Cost (GBP)' by the relevant number of 'Total Items'.",
  "The total number of items for dressings and appliances (prescription items with a preparation class of 4).",
  "England population estimates taken from Office for National Statistics (ONS) - https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates",
  "The 'Total Cost (GBP)' of prescription items that are exempt from prescription charges expressed as a percentage.",
  "The number of prescription items that are exempt from prescription charges expressed as a percentage.",
  "The financial year to which the data belongs.",
  "The number of prescription items that have a preparation class of 1 or 5.",
  "The number of prescription items that have a preparation class of 1 or 5 expressed as a percentage.",
  "Items per capita calculated by dividing 'Total Items' by 'England population'.",
  "The number of prescription items with a preparation class of 1, 2, or 5 that were dispensed as items with class of 1 or 5",
  "The number of prescription items with a preparation class of 1, 2, or 5 that were dispensed as items with class of 1 or 5 expressed as a percentage.",
  "The number of prescription items with a preparation class of 3.",
  "The number of prescription items with a preparation class of 3 expressed as a percentage.",
  "The number of prescription items with a preparation class of 1, 2, or 5.",
  "The number of prescription items with a preparation class of 1, 2 or 5 expressed as a percentage.",
  "The number of prescription items with a preparation class of 1, 2, or 5 that were dispensed as items with a class of 3.",
  "The number of prescription items with a preparation class of 1, 2, or 5 that were dispensed as items with a class of 3 expressed as a percentage.",
  "The rank assigned to that record for the displayed financial year based upon the measure that the table is displaying.",
  "The 'Total Cost (GBP)' of prescription items that are not exempt from prescription charges.",
  "The number of prescription items that are exempt from prescription charges.",
  "Total Cost is the amount that would be paid using the basic price of the prescribed drug or appliance and the quantity prescribed. Sometimes called the 'Net Ingredient Cost' (NIC). The basic price is given either in the Drug Tariff or is determined from prices published by manufacturers, wholesalers or suppliers. Basic price is set out in Parts 8 and 9 of the Drug Tariff. For any drugs or appliances not in Part 8, the price is usually taken from the manufacturer, wholesaler or supplier of the product. This is given in GBP.",
  "The 'Total Cost (GBP)' for the displayed financial year.",
  "The 'Total Cost (GBP)' of prescription items that are exempt from prescription charges.",
  "The number of prescription items that are exempt from prescription charges.",
  "The number prescription items dispensed. 'Items' is the number of times a product appears on a prescription form. Prescription forms include both paper prescriptions and electronic messages.",
  "The 'Total Items' for the displayed financial year.",
  "Unit cost is calculated by dividing the 'Total Cost (GBP)' by the 'Total Quantity' for the given presentation.",
  "The unit of measure given to the smallest available unit of a product. For example, tablet, capsule, unit dose, vial, gram, millilitre etc."
)

accessibleTables::create_metadata(add_anl_wb,
                                  meta_fields_add_anl,
                                  meta_descs_add_anl)

names(add_anl_1) <- c(
  "Financial Year",
  "Total Items",
  "Total Cost (GBP)",
  "England Population",
  "Cost Per Item",
  "Items Per Capita",
  "Cost Per Capita (GBP)"
)
# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A1",
  paste0(
    "Table A1: Total items, cost, number of items and cost per capita, 2014/2015 to ",
    max_data_fy
  ),
  c(
    "ONS population estimates for 2022 were not available prior to publication",
    "ONS population estimates taken from https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates"
  ),
  add_anl_1,
  13
)

#left align column A
accessibleTables::format_data(add_anl_wb,
                              "Table_A1",
                              c("A"),
                              "left",
                              "")

#format columns B and D
accessibleTables::format_data(add_anl_wb,
                              "Table_A1",
                              c("B", "D"),
                              "right",
                              "#,##0")

#format columns C, E, F, G
accessibleTables::format_data(add_anl_wb,
                              "Table_A1",
                              c("C", "E", "F", "G"),
                              "right",
                              "#,##0.00")

#additional analysis - table a2
names(add_anl_2) <- c(
  "BNF Chemical Substance Name",
  "BNF Chemical Substance Code",
  "Total Cost 2014/2015 (GBP) ",
  paste0("Total Cost ", max_data_fy_minus_1 , " (GBP)"),
  paste0("Total Cost ", max_data_fy , " (GBP)"),
  "Rank 2014/2015",
  paste0("Rank ", max_data_fy_minus_1),
  paste0("Rank ", max_data_fy),
  paste0("Change in Costs 2014/2015 to ", max_data_fy, " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1 ,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ", max_data_fy, " (%)"),
  paste0("Change in Costs ", max_data_fy_minus_1 , " to ", max_data_fy, " (%)")
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A2",
  paste0("Table A2: Top 20 drugs by cost, ", max_data_fy),
  c(
    "Top 20 calculations are made excluding BNF chapters 20 to 23, as presentations in these chapters do not hold chemical substances."
  ),
  add_anl_2,
  42
)

#left align column A:B
accessibleTables::format_data(add_anl_wb,
                              "Table_A2",
                              c("A", "B"),
                              "left",
                              "")

#format columns F:H
accessibleTables::format_data(add_anl_wb,
                              "Table_A2",
                              c("F", "G", "H"),
                              "right",
                              "#,##0")

#format columns C:E and I:L
accessibleTables::format_data(add_anl_wb,
                              "Table_A2",
                              c("C", "D", "E", "I", "J", "K", "L"),
                              "right",
                              "#,##0.00")

#additional analysis - table a3
names(add_anl_3) <- c(
  "BNF Chemical Substance Name",
  "BNF Chemical Substance Code",
  "Total Items 2014/2015",
  paste0("Total Items ", max_data_fy_minus_1),
  paste0("Total Items ", max_data_fy),
  "Rank 2014/2015",
  paste0("Rank ", max_data_fy_minus_1),
  paste0("Rank ", max_data_fy),
  paste0("Change in Items 2014/2015 to ", max_data_fy),
  paste0("Change in Items ", max_data_fy_minus_1 , " to ", max_data_fy),
  paste0("Change in Items 2014/2015 to ", max_data_fy, " (%)"),
  paste0("Change in Items ", max_data_fy_minus_1 , " to ", max_data_fy, " (%)")
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A3",
  paste0("Table A3: Top 20 drugs by items dispensed, ", max_data_fy),
  c(
    "Top 20 calculations are made excluding BNF chapters 20 to 23, as presentations in these chapters do not hold chemical substances."
  ),
  add_anl_3,
  40
)

#left align column A:B
accessibleTables::format_data(add_anl_wb,
                              "Table_A3",
                              c("A", "B"),
                              "left",
                              "")

#format columns C:J
accessibleTables::format_data(add_anl_wb,
                              "Table_A3",
                              c("C", "D", "E", "F", "G", "H", "I", "J"),
                              "right",
                              "#,##0")

#format columns K:L
accessibleTables::format_data(add_anl_wb,
                              "Table_A3",
                              c("K", "L"),
                              "right",
                              "#,##0.00")

#additional analysis - table a4
names(add_anl_4) <- c(
  "Financial Year",
  "Total Exempt Items",
  "Total Charged Items",
  "Exempt Items (%)",
  "Total Exempt Cost (GBP)",
  "Total Charged Cost (GBP)",
  "Exempt Cost (%)"
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A4",
  paste0(
    "Table A4: Total items and cost by charge status, 2014/2015 to ",
    max_data_fy
  ),
  c(
    "A charged item is one where the patient has paid the set fee that has been collected by the dispensing contractor.",
    "An exempt item is one where the patient has not paid the set fee for their prescription as they hold a valid exemption. More information on exemption categories can be found at https://www.nhsbsa.nhs.uk/help-nhs-prescription-costs/free-nhs-prescriptions."
  ),
  add_anl_4,
  14
)

#left align column A
accessibleTables::format_data(add_anl_wb,
                              "Table_A4",
                              c("A"),
                              "left",
                              "")

#format columns B:C
accessibleTables::format_data(add_anl_wb,
                              "Table_A4",
                              c("B", "C"),
                              "right",
                              "#,##0")

#format columns D:G
accessibleTables::format_data(add_anl_wb,
                              "Table_A4",
                              c("D", "E", "F", "G"),
                              "right",
                              "#,##0.00")


#additional analysis - table a5

names(add_anl_5) <- c(
  "Financial Year",
  "Items prescribed
 generically",
 "Items prescribed
 and dispensed
 generically",
 "Items prescribed
 generically,
 dispensed and
 reimbursed as
 proprietary",
 "Items prescribed
 and dispensed
 proprietary",
 "Dressings and appliances",
 "Total Items",
 "Items prescribed
 generically
 (%)",
 "Items prescribed
 and dispensed
 generically
 (%)",
 "Items prescribed generically,
 dispensed and reimbursed
 as proprietary
 (%)",
 "Items prescribed
 and dispensed
 proprietary
 (%)",
 "Dressings and Appliances prescribed
 (%)",
 "Cost of items
 prescribed
 generically
 (GBP)",
 "Cost of items
 prescribed and
 dispensed
 generically
 (GBP)",
 "Cost of items
 prescribed
 generically,
 dispensed and
 reimbursed as
 proprietary
 (GBP)",
 "Cost of items
 prescribed and
 dispensed
 proprietary
 (GBP)",
 "Cost of Appliances and Dressings prescribed
 (GBP) ",
 "Total Cost
 (GBP)",
 "Cost of items
 prescribed
 generically
 (%)",
 "Cost of items
 prescribed and
 dispensed
 generically
 (%)",
 "Cost of items
 prescribed
 generically,
 dispensed and
 reimbursed as
 proprietary
 (%)",
 "Cost of items
 prescribed and
 dispensed
 as proprietary
 (%)",
 "Dressings and appliances
 prescribed
 (%)",
 "Cost per item
 prescribed
 generically
 (GBP)",
 "Cost per item
 prescribed and
 dispensed
 generically
 (GBP)",
 "Cost per item
 prescribed
 generically,
 dispensed and
 reimbursed as
 proprietary
 (GBP)",
 "Cost per item
 prescribed and
 dispensed
 proprietary
 (GBP)",
 "Cost per dressing
 and appliance
 (GBP)",
 "Cost Per Item
 (GBP)"
)

add_anl_5 <- add_anl_5 |>
  mutate(`Items prescribed\n generically\n excluding appliances (%)` = `Items prescribed\n generically` / (`Total Items` - `Dressings and appliances`) * 100, .before = `Items prescribed\n and dispensed\n generically\n (%)`) |>
  mutate(`Cost of items\n prescribed\n generically\n excluding appliances (%)` = `Cost of items\n prescribed\n generically\n (GBP)` / (`Total Cost\n (GBP)` - `Cost of Appliances and Dressings prescribed\n (GBP) `) * 100, .before = `Cost of items\n prescribed and\n dispensed\n generically\n (%)`)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A5",
  paste0(
    "Table A5: Generic Prescribing and dispensing by preparation class, 2014/2015 to ",
    max_data_fy
  ),
  c(
    "Generically prescribed items are those with a prescribed preparation class of 1, 2, or 5.",
    "Generically prescribed and dispensed items are those with a prescribed preparation class of 1, 2, or 5 and dispensed as items with a class of 1 or 5.",
    "Generically prescribed/proprietary dispensed items are those with a prescribed preparation class of 1, 2 or 5 and dispensed as items with a class of 2 or 3.",
    "Proprietary prescribed and dispensed items are those with a prescribed preparation class of 3 and dispensed as items with a class of 3.",
    "Dressings and appliances are items which were dispensed as a preparation class of 4"
  ),
  add_anl_5,
  14
)

#left align column A
accessibleTables::format_data(add_anl_wb,
                              "Table_A5",
                              c("A"),
                              "left",
                              "")

#format columns B:G
accessibleTables::format_data(add_anl_wb,
                              "Table_A5",
                              c("B", "C", "D", "E", "F", "G"),
                              "right",
                              "#,##0")

#format columns H:AC
accessibleTables::format_data(
  add_anl_wb,
  "Table_A5",
  c(
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "AA",
    "AB",
    "AC",
    "AD",
    "AE"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a6
names(add_anl_6) <- c(
  "Financial Year",
  "BNF Chapter Code",
  "BNF Chapter Name",
  "Items prescribed generically",
  "Items dispensed generically",
  "Total Items",
  "Items prescribed generically (%)",
  "Items dispensed generically (%)"
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A6",
  paste0(
    "Table A6: Generic prescribing and dispensing by BNF Chapters, 2014/2015 to ",
    max_data_fy
  ),
  c(),
  add_anl_6,
  14
)

#left align column A:C
accessibleTables::format_data(add_anl_wb,
                              "Table_A6",
                              c("A", "B", "C"),
                              "left",
                              "")

#format columns D:F
accessibleTables::format_data(add_anl_wb,
                              "Table_A6",
                              c("D", "E", "F"),
                              "right",
                              "#,##0")

#format columns G:H
accessibleTables::format_data(add_anl_wb,
                              "Table_A6",
                              c("G", "H"),
                              "right",
                              "#,##0.00")

#additional analysis - table a7
names(add_anl_7) <- c(
  "BNF Chapter Code",
  "BNF Chapter Name",
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         "(GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         "(GBP)"),
  "Cost Per Item 2014/2015 (GBP)",
  paste0("Cost Per Item ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Cost Per Item ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A7",
  paste0(
    "Table A7: Number, cost and cost per item by BNF Chapters, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(),
  add_anl_7,
  19
)

#left align column A:B???
accessibleTables::format_data(add_anl_wb,
                              "Table_A7",
                              c("A", "B"),
                              "left",
                              "")

#format columns C:E, L:M
accessibleTables::format_data(add_anl_wb,
                              "Table_A7",
                              c("C", "D", "E", "L", "M"),
                              "right",
                              "#,##0")

#format columns F:K, N:W
accessibleTables::format_data(
  add_anl_wb,
  "Table_A7",
  c(
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a8
names(add_anl_8) <- c(
  "BNF Section Code",
  "BNF Section Name",
  "Rank
 2014/2015",
 paste0("Rank ", max_data_fy_minus_1),
 paste0("Rank ", max_data_fy),
 "Total Items 2014/2015",
 paste0("Total Items ",
        max_data_fy_minus_1),
 paste0("Total Items ",
        max_data_fy),
 "Total Cost 2014/2015 (GBP)",
 paste0("Total Cost ",
        max_data_fy_minus_1,
        "(GBP)"),
 paste0("Total Cost ",
        max_data_fy,
        "(GBP)"),
 "Cost Per Item 2014/2015 (GBP)",
 paste0("Cost Per Item ",
        max_data_fy_minus_1,
        " (GBP)"),
 paste0("Cost Per Item ",
        max_data_fy,
        " (GBP)"),
 paste0("Change in Items 2014/2015 to ",
        max_data_fy),
 paste0("Change in Items ",
        max_data_fy_minus_1,
        " to ",
        max_data_fy),
 paste0("Change in Items 2014/2015 to ",
        max_data_fy,
        " (%)"),
 paste0("Change in Items ",
        max_data_fy_minus_1,
        " to ",
        max_data_fy,
        " (%)"),
 paste0("Change in Costs 2014/2015 to ",
        max_data_fy,
        " (GBP)"),
 paste0(
   "Change in Costs ",
   max_data_fy_minus_1,
   " to ",
   max_data_fy,
   " (GBP)"
 ),
 paste0("Change in Costs 2014/2015 to ",
        max_data_fy,
        " (%)"),
 paste0("Change in Costs ",
        max_data_fy_minus_1,
        " to ",
        max_data_fy,
        " (%)"),
 paste0("Change in Costs Per Item 2014/2015 to ",
        max_data_fy,
        " (GBP)"),
 paste0(
   "Change in Costs Per Item ",
   max_data_fy_minus_1,
   " to ",
   max_data_fy,
   " (GBP)"
 ),
 paste0("Change in Costs Per Item 2014/2015 to ",
        max_data_fy,
        " (%)"),
 paste0(
   "Change in Costs Per Item ",
   max_data_fy_minus_1,
   " to ",
   max_data_fy,
   " (%)"
 )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A8",
  paste0(
    "Table A8: Top 20 BNF Sections by Cost, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(),
  add_anl_8,
  19
)

#left align column A:B
accessibleTables::format_data(add_anl_wb,
                              "Table_A8",
                              c("A", "B"),
                              "left",
                              "")

#format columns C:H, O:P
accessibleTables::format_data(add_anl_wb,
                              "Table_A8",
                              c("C", "D", "E", "F", "G", "H", "O", "P"),
                              "right",
                              "#,##0")

#format columns I:N, P:Z
accessibleTables::format_data(
  add_anl_wb,
  "Table_A8",
  c(
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a9
names(add_anl_9) <- c(
  "BNF Section Code",
  "BNF Section Name",
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         "(GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         "(GBP)"),
  "Cost Per Item 2014/2015 (GBP)",
  paste0("Cost Per Item ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Cost Per Item ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A9",
  paste0(
    "Table A9: Top 20 BNF Sections by increase in cost, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(),
  add_anl_9,
  19
)

#left align column A:B???
accessibleTables::format_data(add_anl_wb,
                              "Table_A9",
                              c("A", "B"),
                              "left",
                              "")

#format columns C:E, L:M
accessibleTables::format_data(add_anl_wb,
                              "Table_A9",
                              c("C", "D", "E", "L", "M"),
                              "right",
                              "#,##0")

#format columns F:K, N:W
accessibleTables::format_data(
  add_anl_wb,
  "Table_A9",
  c(
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a10
names(add_anl_10) <- c(
  "BNF Section Code",
  "BNF Section Name",
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         "(GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         "(GBP)"),
  "Cost Per Item 2014/2015 (GBP)",
  paste0("Cost Per Item ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Cost Per Item ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs Per Item 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Costs Per Item ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A10",
  paste0(
    "Table A10: Top 20 BNF Sections by decrease in cost, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(),
  add_anl_10,
  19
)

#left align column A:B???
accessibleTables::format_data(add_anl_wb,
                              "Table_A10",
                              c("A", "B"),
                              "left",
                              "")

#format columns C:E, L:M
accessibleTables::format_data(add_anl_wb,
                              "Table_A10",
                              c("C", "D", "E", "L", "M"),
                              "right",
                              "#,##0")

#format columns F:K, N:W
accessibleTables::format_data(
  add_anl_wb,
  "Table_A10",
  c(
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a11
names(add_anl_11) <- c(
  "BNF Presentation Code",
  "BNF Presentation Name",
  "Unit of Measure",
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         " (GBP)"),
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Unit Cost 2014/2015 (GBP)",
  paste0("Unit Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Unit Cost ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A11",
  paste0(
    "Table A11: Top 20 BNF Presentations by increase in Unit Cost, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(
    "Analysis is limited to presentations with a total cost greater than 1 million GBP"
  ),
  add_anl_11,
  23
)

#left align column A:C
accessibleTables::format_data(add_anl_wb,
                              "Table_A11",
                              c("A", "B", "C"),
                              "left",
                              "")

#format columns G:I, M:N
accessibleTables::format_data(add_anl_wb,
                              "Table_A11",
                              c("G", "H", "I", "M", "N"),
                              "right",
                              "#,##0")

#format columns D:F, J:L, O:X
accessibleTables::format_data(
  add_anl_wb,
  "Table_A11",
  c(
    "D",
    "E",
    "F",
    "J",
    "K",
    "L",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a12
names(add_anl_12) <- c(
  "BNF Presentation Code",
  "BNF Presentation Name",
  "Unit of Measure",
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         " (GBP)"),
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Unit Cost 2014/2015 (GBP)",
  paste0("Unit Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Unit Cost ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A12",
  paste0(
    "Table A12: Top 20 BNF Presentations by decrease in Unit Cost, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(
    "Analysis is limited to presentations with a total cost greater than 1 million GBP"
  ),
  add_anl_12,
  23
)

#left align column A:C
accessibleTables::format_data(add_anl_wb,
                              "Table_A12",
                              c("A", "B", "C"),
                              "left",
                              "")

#format columns G:I, M:N
accessibleTables::format_data(add_anl_wb,
                              "Table_A12",
                              c("G", "H", "I", "M", "N"),
                              "right",
                              "#,##0")

#format columns D:F, J:L, O:X
accessibleTables::format_data(
  add_anl_wb,
  "Table_A12",
  c(
    "D",
    "E",
    "F",
    "J",
    "K",
    "L",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a13
names(add_anl_13) <- c(
  "BNF Presentation Code",
  "BNF Presentation Name",
  "Unit of Measure",
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         " (GBP)"),
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Unit Cost 2014/2015 (GBP)",
  paste0("Unit Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Unit Cost ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A13",
  paste0(
    "Table A13: Top 20 BNF Presentations by increase in Costs, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(
    "Analysis is limited to presentations with a total cost greater than 1 million GBP"
  ),
  add_anl_13,
  23
)

#left align column A:C
accessibleTables::format_data(add_anl_wb,
                                                "Table_A13",
                                                c("A", "B", "C"),
                                                "left",
                                                "")

#format columns G:I, M:N
accessibleTables::format_data(add_anl_wb,
                              "Table_A13",
                              c("G", "H", "I", "M", "N"),
                              "right",
                              "#,##0")

#format columns D:F, J:L, O:X
format_data(
  add_anl_wb,
  "Table_A13",
  c(
    "D",
    "E",
    "F",
    "J",
    "K",
    "L",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X"
  ),
  "right",
  "#,##0.00"
)

#additional analysis - table a14
names(add_anl_14) <- c(
  "BNF Presentation Code",
  "BNF Presentation Name",
  "Unit of Measure",
  "Total Cost 2014/2015 (GBP)",
  paste0("Total Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Total Cost ",
         max_data_fy,
         " (GBP)"),
  "Total Items 2014/2015",
  paste0("Total Items ",
         max_data_fy_minus_1),
  paste0("Total Items ",
         max_data_fy),
  "Unit Cost 2014/2015 (GBP)",
  paste0("Unit Cost ",
         max_data_fy_minus_1,
         " (GBP)"),
  paste0("Unit Cost ",
         max_data_fy,
         " (GBP)"),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy),
  paste0("Change in Items 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Items ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Costs ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Costs 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Costs ",
         max_data_fy_minus_1,
         " to ",
         max_data_fy,
         " (%)"),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (GBP)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (GBP)"
  ),
  paste0("Change in Unit Cost 2014/2015 to ",
         max_data_fy,
         " (%)"),
  paste0(
    "Change in Unit Cost ",
    max_data_fy_minus_1,
    " to ",
    max_data_fy,
    " (%)"
  )
)

# write data to sheet
accessibleTables::write_sheet(
  add_anl_wb,
  "Table_A14",
  paste0(
    "Table A14: Top 20 BNF Presentations by decrease in Costs, 2014/2015, ",
    max_data_fy_minus_1,
    " and ",
    max_data_fy
  ),
  c(
    "Analysis is limited to presentations with a total cost greater than 1 million GBP"
  ),
  add_anl_14,
  23
)

#left align column A:C
accessibleTables::format_data(add_anl_wb,
                                                "Table_A14",
                                                c("A", "B", "C"),
                                                "left",
                                                "")

#format columns G:I, M:N
accessibleTables::format_data(add_anl_wb,
                              "Table_A14",
                              c("G", "H", "I", "M", "N"),
                              "right",
                              "#,##0")

#format columns D:F, J:L, O:X
format_data(
  add_anl_wb,
  "Table_A14",
  c(
    "D",
    "E",
    "F",
    "J",
    "K",
    "L",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X"
  ),
  "right",
  "#,##0.00"
)

#save file into outputs folder
openxlsx::saveWorkbook(
  add_anl_wb,
  #automate names
  paste0(
    "outputs/pca_additional_tables_",
    substr(max_data_fy, 1, 4),
    "_",
    substr(max_data_fy, 8, 9),
    "_v001.xlsx"
  ),
  overwrite = TRUE
)

# 6. create exemption categories excel ------

#rename data 
names(pca_exemption_categories) <- c(
  "Financial year",
  "Exemption category code",
  "Exemption category",
  "Total items",
  "Total cost (GBP)"
)

#create workbook and meta data
sheetNames_ex_cat <- c(
  "Exemption_categories"
)

ex_cat_wb <- create_wb(sheetNames_ex_cat)

meta_fields_ex_cat <- c(
 "Financial year",
 "Exemption category code",
 "Exemption category",
 "Total items",
 "Total cost (GBP)"
)

meta_descs_ex_cat<- c(
 "The financial year to which the data belongs.",
 "The specific code for the category that was selected by the patient on the back of the prescription form.",
 "The category that was selected by the patient on the back of the prescription form.",
 "The number prescription items dispensed. 'Items' is the number of times a product appears on a prescription form. Prescription forms include both paper prescriptions and electronic messages.",
 "Total cost is the amount that would be paid using the basic price of the prescribed drug or appliance and the quantity prescribed. Sometimes called the 'Net Ingredient Cost' (NIC). The basic price is given either in the Drug Tariff or is determined from prices published by manufacturers, wholesalers or suppliers. Basic price is set out in Parts 8 and 9 of the Drug Tariff. For any drugs or appliances not in Part 8, the price is usually taken from the manufacturer, wholesaler or supplier of the product. This is given in GBP."
)

accessibleTables::create_metadata(ex_cat_wb,
                                  meta_fields_ex_cat,
                                  meta_descs_ex_cat)

# write data to sheet
accessibleTables::write_sheet(
  ex_cat_wb,
  "Exemption_categories",
  paste0(
    "Total items and cost by exemption category, 2014/15 to ",
    max_data_fy
  ),
  c(
    "Due to rounding, total figures may not match exactly between the different tables. Costs are rounded to the nearest pence.",
    "Items assigned an exemption category code of '-' have an unknown exemption category, or an exemption category that was not captured during processing."
  ),
  pca_exemption_categories,
  13
)

#left align column A
accessibleTables::format_data(ex_cat_wb,
                              "Exemption_categories",
                              c("A"),
                              "left",
                              "")

#format columns B and D
accessibleTables::format_data(ex_cat_wb,
                              "Exemption_categories",
                              c("B", "C"),
                              "right",
                              "#,##0")

#format columns C, E, F, G
accessibleTables::format_data(ex_cat_wb,
                              "Exemption_categories",
                              c("D", "E"),
                              "right",
                              "#,##0.00")

#save file into outputs folder
openxlsx::saveWorkbook(
  ex_cat_wb,
  #automate names
  paste0(
    "outputs/pca_exemption_categories_",
    substr(max_data_fy, 1, 4),
    "_",
    substr(max_data_fy, 8, 9),
    "_v001.xlsx"
  ),
  overwrite = TRUE
)
