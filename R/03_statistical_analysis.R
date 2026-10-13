#' Analise Estatistica Avancada, Modelagem e Segmentacao: Cyclistic Bike-Share
#'
#' @description
#' Executa estatistica descritiva canonica (incluindo moda do dia da semana),
#' inferencia nao parametrica de Wilcoxon e Qui-quadrado com tamanhos de efeito
#' (r de Rosenthal e V de Cramer), regressao logistica explicativa com Odds Ratios
#' e segmentacao quantitativa das personas de ciclistas casuais.

calculate_mode <- function(x) {
  tab <- table(x)
  if (length(tab) == 0) return(NA_character_)
  names(tab)[which.max(tab)]
}

cramers_v <- function(chi_test, n) {
  chi_stat <- as.numeric(chi_test$statistic)
  dims <- dim(chi_test$observed)
  k <- min(dims[1], dims[2])
  if (k <= 1 || n <= 0) return(0)
  sqrt(chi_stat / (n * (k - 1)))
}

wilcoxon_r <- function(wilcox_test, n) {
  p_val <- wilcox_test$p.value
  # Aproximacao do escore Z a partir do p-valor bicaudal
  p_clamped <- max(min(p_val, 0.99999999), 1e-300)
  z_stat <- abs(stats::qnorm(p_clamped / 2))
  r_val <- z_stat / sqrt(n)
  return(round(r_val, 3))
}

run_advanced_statistics <- function(df) {
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("stats", quietly = TRUE)
  
  n_total <- nrow(df)
  
  # 1. Estatistica Descritiva Canonica (Metricas exigidas no PDF do Google)
  descriptive_summary <- df |>
    dplyr::group_by(member_casual) |>
    dplyr::summarise(
      total_viagens = dplyr::n(),
      media_duracao_min = round(mean(trip_duration_min), 2),
      desvio_duracao_min = round(stats::sd(trip_duration_min), 2),
      mediana_duracao_min = round(stats::median(trip_duration_min), 2),
      iqr_duracao_min = round(stats::IQR(trip_duration_min), 2),
      min_duracao_min = round(min(trip_duration_min), 2),
      max_duracao_min = round(max(trip_duration_min), 2),
      moda_dia_semana = calculate_mode(weekday),
      distancia_media_km = round(mean(distance_km), 2),
      distancia_mediana_km = round(stats::median(distance_km), 2),
      taxa_rotas_circulares_pct = round(mean(is_round_trip, na.rm = TRUE) * 100, 2),
      .groups = "drop"
    )
  
  # 2. Testes de Hipotese: Wilcoxon-Mann-Whitney
  wilcox_dur <- stats::wilcox.test(
    trip_duration_min ~ member_casual,
    data = df,
    exact = FALSE,
    conf.int = TRUE
  )
  r_duracao <- wilcoxon_r(wilcox_dur, n_total)
  
  wilcox_dist <- stats::wilcox.test(
    distance_km ~ member_casual,
    data = df,
    exact = FALSE,
    conf.int = TRUE
  )
  r_distancia <- wilcoxon_r(wilcox_dist, n_total)
  
  # 3. Testes Qui-quadrado de Independencia
  tab_weekend <- table(df$member_casual, df$is_weekend)
  chisq_weekend <- stats::chisq.test(tab_weekend)
  v_weekend <- round(cramers_v(chisq_weekend, n_total), 3)
  
  tab_bike <- table(df$member_casual, df$rideable_type)
  chisq_bike <- stats::chisq.test(tab_bike)
  v_bike <- round(cramers_v(chisq_bike, n_total), 3)
  
  tab_round <- table(df$member_casual, df$is_round_trip)
  chisq_round <- stats::chisq.test(tab_round)
  v_round <- round(cramers_v(chisq_round, n_total), 3)
  
  # 4. Regressao Logistica Explicativa
  # Modela probabilidade de ser Membro (1) vs Casual (0)
  df_model <- df |>
    dplyr::mutate(
      target_member = as.numeric(member_casual == "Membro"),
      is_commute_hours = as.numeric(start_hour %in% c(7, 8, 9, 16, 17, 18)),
      is_weekend_num = as.numeric(is_weekend == "Fim de Semana")
    )
  
  logit_fit <- stats::glm(
    target_member ~ is_weekend_num + is_commute_hours + distance_km + rideable_type + season,
    data = df_model,
    family = stats::binomial(link = "logit")
  )
  
  coef_summary <- summary(logit_fit)$coefficients
  odds_ratios_df <- data.frame(
    variavel = rownames(coef_summary),
    coeficiente = round(coef_summary[, "Estimate"], 4),
    erro_padrao = round(coef_summary[, "Std. Error"], 4),
    p_valor = coef_summary[, "Pr(>|z|)"],
    odds_ratio = round(exp(coef_summary[, "Estimate"]), 3),
    ci_inf = round(exp(coef_summary[, "Estimate"] - 1.96 * coef_summary[, "Std. Error"]), 3),
    ci_sup = round(exp(coef_summary[, "Estimate"] + 1.96 * coef_summary[, "Std. Error"]), 3),
    stringsAsFactors = FALSE
  )
  rownames(odds_ratios_df) <- NULL
  
  # 5. Segmentacao Quantitativa de Personas Casuais
  casuals <- df |>
    dplyr::filter(member_casual == "Casual") |>
    dplyr::mutate(
      persona = dplyr::case_when(
        is_weekend == "Dia Util" & (start_hour %in% c(7, 8, 9, 16, 17, 18)) & !is_round_trip & trip_duration_min <= 45 ~ "Comutador Oculto",
        is_weekend == "Fim de Semana" | is_round_trip ~ "Lazer de Fim de Semana",
        TRUE ~ "Espontaneo / Noite"
      )
    )
  
  personas_summary <- casuals |>
    dplyr::group_by(persona) |>
    dplyr::summarise(
      volume_viagens = dplyr::n(),
      proporcao_pct = round((dplyr::n() / nrow(casuals)) * 100, 1),
      mediana_duracao_min = round(stats::median(trip_duration_min), 1),
      mediana_distancia_km = round(stats::median(distance_km), 2),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(volume_viagens))
  
  return(list(
    descriptive = descriptive_summary,
    wilcox_duration = list(test = wilcox_dur, r = r_duracao),
    wilcox_distance = list(test = wilcox_dist, r = r_distancia),
    chisq_tests = list(
      weekend = list(test = chisq_weekend, v = v_weekend),
      bike = list(test = chisq_bike, v = v_bike),
      round_trip = list(test = chisq_round, v = v_round)
    ),
    logistic_model = logit_fit,
    odds_ratios = odds_ratios_df,
    personas = personas_summary
  ))
}
