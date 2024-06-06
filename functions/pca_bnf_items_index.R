pca_bnf_items_index <- function(con) {
  #extract raw data
  raw_data <- dplyr::tbl(con,
                         from = dbplyr::in_schema("AML", "PCA_MY_FY_CY_FACT")) |>
    dplyr::filter(MONTH_TYPE %in% c("FY")) |>
    dplyr::filter(YEAR_DESC != "2013/2014") |>
    dplyr::select(
      "YEAR_DESC",
      "BNF_CHAPTER",
      "CHAPTER_DESCR",
      "ITEM_COUNT",
      "ITEM_PAY_DR_NIC"
    ) |>
    dplyr::group_by(YEAR_DESC,BNF_CHAPTER,CHAPTER_DESCR) |>
    dplyr::summarise(
      TOTAL_ITEMS = sum(ITEM_COUNT),
      TOTAL_NIC = sum(ITEM_PAY_DR_NIC) / 100,
      .groups = "drop") |>
    collect()
  
  bnf_lookup <- raw_data |> select(BNF_CHAPTER,
                                   CHAPTER_DESCR) |>
    unique()
  
  data <- raw_data |>
    select(
      YEAR_DESC,
      BNF_CHAPTER,
      TOTAL_ITEMS
    ) |>
    arrange(BNF_CHAPTER,YEAR_DESC) |>
    pivot_wider(names_from = BNF_CHAPTER,
                values_from = TOTAL_ITEMS) |>
    mutate(
      `01_INDEX` = 100 * (`01` / `01`[YEAR_DESC == min(YEAR_DESC)]),
      `02_INDEX` = 100 * (`02` / `02`[YEAR_DESC == min(YEAR_DESC)]),
      `03_INDEX` = 100 * (`03` / `03`[YEAR_DESC == min(YEAR_DESC)]),
      `04_INDEX` = 100 * (`04` / `04`[YEAR_DESC == min(YEAR_DESC)]),
      `05_INDEX` = 100 * (`05` / `05`[YEAR_DESC == min(YEAR_DESC)]),
      `06_INDEX` = 100 * (`06` / `06`[YEAR_DESC == min(YEAR_DESC)]),
      `07_INDEX` = 100 * (`07` / `07`[YEAR_DESC == min(YEAR_DESC)]),
      `08_INDEX` = 100 * (`08` / `08`[YEAR_DESC == min(YEAR_DESC)]),
      `09_INDEX` = 100 * (`09` / `09`[YEAR_DESC == min(YEAR_DESC)]),
      `10_INDEX` = 100 * (`10` / `10`[YEAR_DESC == min(YEAR_DESC)]),
      `11_INDEX` = 100 * (`11` / `11`[YEAR_DESC == min(YEAR_DESC)]),
      `12_INDEX` = 100 * (`12` / `12`[YEAR_DESC == min(YEAR_DESC)]),
      `13_INDEX` = 100 * (`13` / `13`[YEAR_DESC == min(YEAR_DESC)]),
      `14_INDEX` = 100 * (`14` / `14`[YEAR_DESC == min(YEAR_DESC)]),
      `15_INDEX` = 100 * (`15` / `15`[YEAR_DESC == min(YEAR_DESC)])#,
      #`18_INDEX` = 100 * (`18` / `18`[YEAR_DESC == min(YEAR_DESC)]),
      #`19_INDEX` = 100 * (`19` / `19`[YEAR_DESC == min(YEAR_DESC)]),
      #`20_INDEX` = 100 * (`20` / `20`[YEAR_DESC == min(YEAR_DESC)]),
      #`21_INDEX` = 100 * (`21` / `21`[YEAR_DESC == min(YEAR_DESC)]),
      #`22_INDEX` = 100 * (`22` / `22`[YEAR_DESC == min(YEAR_DESC)]),
    ) |>
    select(YEAR_DESC,
           `01_INDEX`:`15_INDEX`) |>
    pivot_longer(
      cols = c(`01_INDEX`:`15_INDEX`),
      names_to = "BNF_CHAPTER",
      values_to = "VALUE"
    ) |>
    mutate(
      BNF_CHAPTER = substr(BNF_CHAPTER,1,2)
    ) |>
    left_join(
      bnf_lookup
    ) |>
    select(YEAR_DESC, BNF_CHAPTER, CHAPTER_DESCR, VALUE)
  
  max_change_bnf <- data |>
    filter(YEAR_DESC == max(YEAR_DESC)) |>
    filter(VALUE == max(VALUE)) |>
    select(BNF_CHAPTER) |>
    pull()
  
  min_change_bnf <- data |>
    filter(YEAR_DESC == max(YEAR_DESC)) |>
    filter(VALUE == min(VALUE)) |>
    select(BNF_CHAPTER) |>
    pull()
  
  figure_data <- data |>
    filter(BNF_CHAPTER %in% c(max_change_bnf, min_change_bnf)) |>
    mutate(BNF_CHAPTER = paste0(BNF_CHAPTER, " - ", CHAPTER_DESCR))
  
  return(figure_data)
}
