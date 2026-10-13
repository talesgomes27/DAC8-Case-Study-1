#' Analise Estatistica e Metricas de Conversao: Cyclistic Bike-Share
#'
#' @description
#' Executa testes de hipoteses formais (Wilcoxon-Mann-Whitney para duracao e distancia,
#' Qui-quadrado para preferencias de dia e modal) e isola o segmento de ciclistas casuais
#' com perfil de deslocamento a trabalho (comutadores).
#'
#' @param df Tibble limpo gerado por `clean_and_transform()`.
#' @return Lista contendo os resultados dos testes e sumarios executivos.
#' @export

run_statistical_tests <- function(df) {
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("stats", quietly = TRUE)
  
  # 1. Teste de Wilcoxon para Duracao (distribuicao com forte assimetria a direita)
  wilcox_duration <- stats::wilcox.test(
    trip_duration_min ~ member_casual,
    data = df,
    exact = FALSE,
    conf.int = TRUE
  )
  
  duration_summary <- df |>
    dplyr::group_by(member_casual) |>
    dplyr::summarise(
      mediana_min = round(stats::median(trip_duration_min), 2),
      media_min = round(mean(trip_duration_min), 2),
      iqr_min = round(stats::IQR(trip_duration_min), 2),
      q25_min = round(stats::quantile(trip_duration_min, 0.25), 2),
      q75_min = round(stats::quantile(trip_duration_min, 0.75), 2),
      total_viagens = dplyr::n(),
      .groups = "drop"
    )
  
  # 2. Teste de Wilcoxon para Distancia (km)
  wilcox_distance <- stats::wilcox.test(
    distance_km ~ member_casual,
    data = df,
    exact = FALSE,
    conf.int = TRUE
  )
  
  distance_summary <- df |>
    dplyr::group_by(member_casual) |>
    dplyr::summarise(
      mediana_km = round(stats::median(distance_km), 2),
      media_km = round(mean(distance_km), 2),
      taxa_rotas_circulares_pct = round(mean(is_round_trip, na.rm = TRUE) * 100, 2),
      .groups = "drop"
    )
  
  # 3. Teste Qui-quadrado: Tipo de Usuario vs Fim de Semana
  table_weekend <- table(df$member_casual, df$is_weekend)
  chisq_weekend <- stats::chisq.test(table_weekend)
  
  # 4. Teste Qui-quadrado: Tipo de Usuario vs Tipo de Bicicleta
  table_bike <- table(df$member_casual, df$rideable_type)
  chisq_bike <- stats::chisq.test(table_bike)
  
  # 5. Segmentacao de Conversao: Identificacao de "Casuais Comutadores"
  # Criterios: viagens em dias uteis, nos horarios de pico (7-9h ou 16-18h), ponto-a-ponto, duracao < 45 min
  commuter_casuals <- df |>
    dplyr::filter(member_casual == "Casual") |>
    dplyr::mutate(
      is_commuter_pattern = (
        is_weekend == "Dia Util" &
        (start_hour %in% c(7, 8, 9, 16, 17, 18)) &
        !is_round_trip &
        trip_duration_min <= 45
      )
    )
  
  total_casual_trips <- nrow(commuter_casuals)
  commuter_trips_count <- sum(commuter_casuals$is_commuter_pattern, na.rm = TRUE)
  commuter_pct <- round((commuter_trips_count / total_casual_trips) * 100, 2)
  
  conversion_metrics <- list(
    total_casual_trips = total_casual_trips,
    commuter_trips_count = commuter_trips_count,
    commuter_pct = commuter_pct
  )
  
  return(list(
    wilcox_duration = wilcox_duration,
    duration_summary = duration_summary,
    wilcox_distance = wilcox_distance,
    distance_summary = distance_summary,
    chisq_weekend = chisq_weekend,
    chisq_bike = chisq_bike,
    conversion_metrics = conversion_metrics
  ))
}
