get_recent_file_nat_fy <- function() {
  file <- rownames(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "nat_data_fy"
    )
  ))[which.max(file.info(
    list.files(
      "Y:/Official Stats/PCA/data",
      full.names = T,
      pattern = "nat_data_fy"
    )
  )$mtime)]
  
  vroom::vroom(file,
               #read snomed code as character
               col_types = c(DISP_PRESEN_SNOMED_CODE = "c"))
}
