#' Script para Download e Descompactacao dos Dados Brutos do Cyclistic (Divvy)
#'
#' @description
#' Baixa os 12 arquivos mensais (Julho/2020 a Junho/2021) diretamente do bucket S3 oficial
#' da Divvy/Motivate International, extrai os arquivos CSV para 'data/raw/' e remove os zips.

dest_dir <- "data/raw"
if (!dir.exists(dest_dir)) {
  dir.create(dest_dir, recursive = TRUE)
}

# Lista dos 12 meses do estudo original
months <- c(
  "202007", "202008", "202009", "202010", "202011", "202012",
  "202101", "202102", "202103", "202104", "202105", "202106"
)

base_url <- "https://divvy-tripdata.s3.amazonaws.com"

cat("Iniciando download dos 12 meses do Cyclistic Bike-Share...\n")
cat("Destino:", dest_dir, "\n\n")

for (m in months) {
  zip_name <- paste0(m, "-divvy-tripdata.zip")
  zip_url <- paste0(base_url, "/", zip_name)
  dest_zip <- file.path(dest_dir, zip_name)
  
  cat(sprintf("[>] Baixando %s...\n", zip_name))
  tryCatch({
    download.file(zip_url, destfile = dest_zip, mode = "wb", quiet = FALSE)
    
    cat(sprintf("    Descompactando %s...\n", zip_name))
    unzip(dest_zip, exdir = dest_dir)
    
    # Remove arquivo zip temporario
    file.remove(dest_zip)
    cat(sprintf("    [OK] %s concluido.\n\n", m))
  }, error = function(e) {
    cat(sprintf("    [ERRO] Falha ao processar %s: %s\n\n", zip_name, e$message))
  })
}

# Remove eventuais pastas de metadata do MacOS (__MACOSX) geradas no unzip
macosx_dir <- file.path(dest_dir, "__MACOSX")
if (dir.exists(macosx_dir)) {
  unlink(macosx_dir, recursive = TRUE)
}

csv_files <- list.files(dest_dir, pattern = "\\.csv$", full.names = TRUE)
cat(sprintf("Download finalizado! Total de arquivos CSV em %s: %d\n", dest_dir, length(csv_files)))
cat("Agora basta executar 'quarto render report/index.qmd' para processar a base completa.\n")
