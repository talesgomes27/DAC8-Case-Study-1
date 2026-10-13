#' Ingestao e Carregamento de Dados do Cyclistic Bike-Share
#'
#' @description
#' Carrega os dados brutos de viagens a partir de um diretorio contendo arquivos CSV
#' ou utiliza a amostra local caso os arquivos brutos nao estejam disponiveis.
#'
#' @param source_path Caminho opcional para a pasta com os CSVs brutos. Se NULL, tenta
#' caminhos padroes ('data/raw', '../database', 'database') antes de recorrer a 'data/sample_tripdata.csv'.
#' @return Um tibble com os dados brutos consolidados e tipagem validada.
#' @export

load_trip_data <- function(source_path = NULL) {
  requireNamespace("readr", quietly = TRUE)
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("fs", quietly = TRUE)
  
  # 0. Prioridade 1: Carrega Apache Parquet otimizado se disponivel
  parquet_candidates <- c(
    "data/processed/cyclistic_trips_cleaned.parquet",
    "../data/processed/cyclistic_trips_cleaned.parquet"
  )
  for (pq in parquet_candidates) {
    if (fs::file_exists(pq) && requireNamespace("nanoparquet", quietly = TRUE)) {
      message("Carregando dataset otimizado em Apache Parquet: ", pq)
      t0 <- Sys.time()
      df <- nanoparquet::read_parquet(pq)
      t1 <- Sys.time()
      message(sprintf("Carga Parquet concluida em %.2f s. Registros: %s linhas e %d colunas.",
                      as.numeric(difftime(t1, t0, units = "secs")),
                      format(nrow(df), big.mark = ".", decimal.mark = ","), ncol(df)))
      return(df)
    }
  }
  
  target_files <- character(0)
  
  # 1. Verifica caminhos de dados completos se nenhum for explicitamente passado
  candidate_dirs <- if (!is.null(source_path)) {
    source_path
  } else {
    c("data/raw", "../database", "database", "../data/raw")
  }
  
  for (d in candidate_dirs) {
    if (fs::dir_exists(d)) {
      csvs <- fs::dir_ls(d, glob = "*.csv", recurse = FALSE)
      if (length(csvs) > 0) {
        target_files <- csvs
        message(sprintf("Encontrados %d arquivos CSV no diretorio: %s", length(target_files), d))
        break
      }
    }
  }
  
  # 2. Fallback para a amostra local representativa
  if (length(target_files) == 0) {
    sample_path <- "data/sample_tripdata.csv"
    if (!fs::file_exists(sample_path) && fs::file_exists("../data/sample_tripdata.csv")) {
      sample_path <- "../data/sample_tripdata.csv"
    }
    
    if (fs::file_exists(sample_path)) {
      message("Diretorio de arquivos brutos nao localizado. Carregando amostra de reproducibilidade: ", sample_path)
      target_files <- sample_path
    } else {
      stop("Nenhum dado encontrado. Forneca o caminho dos arquivos brutos ou execute data/generate_sample.R.")
    }
  }
  
  # 3. Especificacao de tipos para consistencia entre arquivos
  expected_types <- readr::cols(
    ride_id = readr::col_character(),
    rideable_type = readr::col_character(),
    started_at = readr::col_datetime(),
    ended_at = readr::col_datetime(),
    start_station_name = readr::col_character(),
    start_station_id = readr::col_character(),
    end_station_name = readr::col_character(),
    end_station_id = readr::col_character(),
    start_lat = readr::col_double(),
    start_lng = readr::col_double(),
    end_lat = readr::col_double(),
    end_lng = readr::col_double(),
    member_casual = readr::col_character()
  )
  
  # 4. Leitura e uniao
  raw_df <- readr::read_csv(
    target_files,
    col_types = expected_types,
    show_col_types = FALSE,
    id = if (length(target_files) > 1) "source_file" else NULL
  )
  
  message(sprintf("Carga concluida com sucesso. Total de registros: %s linhas e %d colunas.",
                  format(nrow(raw_df), big.mark = ".", decimal.mark = ","), ncol(raw_df)))
  
  return(raw_df)
}
