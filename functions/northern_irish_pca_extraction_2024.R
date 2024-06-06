northern_irish_pca_extraction_2024 <-
  function(link = NULL,
           file_path = NULL,
           sheet = 3) {
    # Extracting total_items and total_costs from URL link
    if (!is.null(link)) {
      #Create a temp file using URL link
      
      temp <- tempfile()
      
      ni_url <- utils::download.file(url = link, temp, mode = "wb")
      
      #keep total items and total gross ingredient cost (NIC equivalent)
      #rename columns to TOTAL_ITEMS and TOTAL_COST
      
      ni_pcassfsf <- readxl::read_xlsx(
        temp,
        sheet = 5,
        range = "A5:E26") |>
        summarise(
          TOTAL_ITEMS = sum(`Number of prescription items`),
          TOTAL_COST = sum(`Ingredient cost before discount (£)`)
        )
      
      
      #presenting the data
      return(ni_pcassfsf)
      
      
      
      # Extracting total_items and total_costs from file path
    } else if (!is.null(file_path)) {
      #keep total items and total gross ingredient cost (NIC equivalent)
      #rename columns to TOTAL_ITEMS and TOTAL_COST
      
      
      ni_pca2 <- readxl::read_excel(file_path,
                                    sheet = 5,
                                    range = "A5:E26") |>
        summarise(
          TOTAL_ITEMS = sum(`Number of prescription items`),
          TOTAL_COST = sum(`Ingredient cost before discount (£)`)
        )
      
      
      
      #presenting the data
      return(ni_pca2)
      
      
    } else {
      # Return an error message
      stop("Function requires either a link to the Northern Irish PCA data or a file path to the Data")
    }
    
  }