#' Limpeza, Validacao e Engenharia de Atributos: Cyclistic Bike-Share
#'
#' @description
#' Aplica filtros de integridade temporal e espacial, calcula distancia geodésica
#' via formula de Haversine vetorizada e estrutura variaveis categoricas.
#'
#' @param df Tibble com dados brutos gerado por `load_trip_data()`.
#' @param min_duration_mins Duracao minima em minutos (padrao = 2 para filtrar testes e falhas).
#' @param max_duration_mins Duracao maxima em minutos (padrao = 1440 = 24 horas).
#' @return Tibble transformado e higienizado pronto para analise estatistica e visualizacao.
#' @export

calculate_haversine_km <- function(lat1, lon1, lat2, lon2) {
  # Raio medio da Terra em quilometros
  r_earth <- 6371.0
  
  # Conversao para radianos
  rad <- pi / 180
  phi1 <- lat1 * rad
  phi2 <- lat2 * rad
  delta_phi <- (lat2 - lat1) * rad
  delta_lambda <- (lon2 - lon1) * rad
  
  # Formula de Haversine
  a <- sin(delta_phi / 2)^2 + cos(phi1) * cos(phi2) * sin(delta_lambda / 2)^2
  # Protecao numerica contra imprecisao de ponto flutuante
  a <- pmin(pmax(a, 0), 1)
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))
  
  return(r_earth * c)
}

clean_and_transform <- function(df, min_duration_mins = 2, max_duration_mins = 1440) {
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("lubridate", quietly = TRUE)
  
  if ("trip_duration_min" %in% names(df) && "distance_km" %in% names(df)) {
    message("Dataset ja higienizado e enriquecido com variaveis espaciais (carga direta).")
    return(df)
  }
  
  initial_rows <- nrow(df)
  
  cleaned_df <- df |>
    # 1. Filtros preliminares de integridade basica de coordenadas
    dplyr::filter(
      !is.na(started_at), !is.na(ended_at),
      !is.na(start_lat), !is.na(start_lng),
      !is.na(end_lat), !is.na(end_lng),
      start_lat > 40 & start_lat < 43,
      start_lng > -89 & start_lng < -86,
      end_lat > 40 & end_lat < 43,
      end_lng > -89 & end_lng < -86
    ) |>
    # 2. Engenharia de variaveis temporais e espaciais
    dplyr::mutate(
      trip_duration_min = as.numeric(difftime(ended_at, started_at, units = "mins")),
      start_hour = lubridate::hour(started_at),
      weekday = lubridate::wday(started_at, label = TRUE, abbr = FALSE, week_start = 1),
      is_weekend = dplyr::if_else(
        lubridate::wday(started_at, week_start = 1) %in% c(6, 7),
        "Fim de Semana",
        "Dia Util"
      ),
      month = lubridate::month(started_at, label = TRUE, abbr = FALSE),
      
      # Sazonalidade meteorologica de Chicago (Hemisferio Norte)
      season = dplyr::case_when(
        lubridate::month(started_at) %in% c(12, 1, 2) ~ "Inverno",
        lubridate::month(started_at) %in% c(3, 4, 5)   ~ "Primavera",
        lubridate::month(started_at) %in% c(6, 7, 8)   ~ "Verao",
        lubridate::month(started_at) %in% c(9, 10, 11) ~ "Outono"
      ),
      
      # Faixas do dia
      day_part = dplyr::case_when(
        start_hour < 6                 ~ "Madrugada",
        start_hour >= 6 & start_hour < 12 ~ "Manha",
        start_hour >= 12 & start_hour < 18 ~ "Tarde",
        start_hour >= 18               ~ "Noite"
      ),
      
      # Distancia geodésica (km) e velocidade media estimada (km/h)
      distance_km = calculate_haversine_km(start_lat, start_lng, end_lat, end_lng),
      speed_kmh = dplyr::if_else(
        trip_duration_min > 0,
        round(distance_km / (trip_duration_min / 60), 2),
        NA_real_
      ),
      
      # Identificacao de viagens circulares (início e término na mesma estacao)
      is_round_trip = (start_station_name == end_station_name & !is.na(start_station_name)),
      
      # Rota formatada
      trip_route = dplyr::if_else(
        !is.na(start_station_name) & !is.na(end_station_name),
        paste0(start_station_name, " -> ", end_station_name),
        NA_character_
      )
    ) |>
    # 3. Filtro de duracao de viagem
    dplyr::filter(
      trip_duration_min >= min_duration_mins,
      trip_duration_min <= max_duration_mins
    ) |>
    # 4. Tipagem semantica de fatores
    dplyr::mutate(
      member_casual = factor(
        member_casual,
        levels = c("member", "casual"),
        labels = c("Membro", "Casual")
      ),
      rideable_type = factor(rideable_type),
      season = factor(
        season,
        levels = c("Primavera", "Verao", "Outono", "Inverno")
      ),
      day_part = factor(
        day_part,
        levels = c("Madrugada", "Manha", "Tarde", "Noite")
      ),
      is_weekend = factor(
        is_weekend,
        levels = c("Dia Util", "Fim de Semana")
      )
    )
  
  final_rows <- nrow(cleaned_df)
  diff_rows <- initial_rows - final_rows
  
  message(sprintf("Limpeza concluida. Linhas retidas: %s de %s (descartadas %s ou %.2f%%).",
                  format(final_rows, big.mark = ".", decimal.mark = ","),
                  format(initial_rows, big.mark = ".", decimal.mark = ","),
                  format(diff_rows, big.mark = ".", decimal.mark = ","),
                  (diff_rows / initial_rows) * 100))
  
  return(cleaned_df)
}
