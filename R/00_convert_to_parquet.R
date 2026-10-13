#' Conversao em Lote e Otimizacao do Dataset para Apache Parquet
#'
#' @description
#' Carrega os 12 arquivos mensais brutos em 'data/raw/', aplica a higienizacao
#' e engenharia de variaveis espaciais e salva em 'data/processed/cyclistic_trips_cleaned.parquet'
#' com compressao colunar ZSTD e codificacao por dicionario (fatores).

source("R/01_ingest.R")
source("R/02_clean_and_transform.R")

raw_dir <- "data/raw"
output_dir <- "data/processed"
output_file <- file.path(output_dir, "cyclistic_trips_cleaned.parquet")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

csv_files <- list.files(raw_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(csv_files) == 0) {
  stop("Nenhum arquivo CSV encontrado em 'data/raw/'. Verifique o diretorio.")
}

cat("=== Otimizacao de Dataset: CSV -> Apache Parquet ===\n")
cat(sprintf("Encontrados %d arquivos CSV em %s\n", length(csv_files), raw_dir))

# 1. Ingestao dos CSVs brutos
t0 <- Sys.time()
cat("[1/3] Ingerindo arquivos CSV brutos...\n")
raw_data <- load_trip_data(raw_dir)

# 2. Limpeza e Engenharia de Variaveis
cat("[2/3] Executando limpeza e engenharia de atributos (Haversine, velocidades)...\n")
cleaned_data <- clean_and_transform(raw_data)

# Remove colunas redundantes que inflam desnecessariamente o espaco em disco
cleaned_data$source_file <- NULL
cleaned_data$trip_route <- NULL

# Converte colunas categoricas para fatores nominais (ativa compressao por dicionario no Parquet)
cols_factor <- c(
  "member_casual", "rideable_type", "is_weekend", "season", "day_part",
  "weekday", "month", "start_station_name", "end_station_name"
)
for (col in cols_factor) {
  if (col %in% names(cleaned_data)) {
    cleaned_data[[col]] <- as.factor(cleaned_data[[col]])
  }
}

# 3. Gravacao em Parquet compactado com ZSTD nivel 7
cat(sprintf("[3/3] Serializando em Apache Parquet: %s ...\n", output_file))
nanoparquet::write_parquet(
  cleaned_data,
  output_file,
  compression = "zstd",
  options = nanoparquet::parquet_options(compression_level = 7)
)
t1 <- Sys.time()

# 4. Metricas e Benchmark
csv_bytes <- sum(file.size(csv_files))
parquet_bytes <- file.size(output_file)

csv_mb <- round(csv_bytes / (1024^2), 1)
parquet_mb <- round(parquet_bytes / (1024^2), 1)
ratio <- round(csv_bytes / parquet_bytes, 1)

cat("\n======================================================\n")
cat("            CONVERSAO CONCLUIDA COM SUCESSO           \n")
cat("======================================================\n")
cat(sprintf("Linhas processadas:    %s\n", scales::number(nrow(cleaned_data), big.mark = ".")))
cat(sprintf("Colunas estruturadas:  %d\n", ncol(cleaned_data)))
cat(sprintf("Tamanho original CSV:  %s MB\n", csv_mb))
cat(sprintf("Tamanho final Parquet: %s MB\n", parquet_mb))
cat(sprintf("Fator de reducao:       %.1fx menor!\n", ratio))
cat(sprintf("Tempo total:           %.1f segundos\n", as.numeric(difftime(t1, t0, units = "secs"))))
cat("======================================================\n")
