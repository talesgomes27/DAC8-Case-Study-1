#' Identidade Visual e Funcoes Graficas Padronizadas: Cyclistic Bike-Share
#'
#' @description
#' Implementa o tema customizado para ggplot2, paleta acessivel com contraste verificado
#' e funcoes de plotagem encapsuladas para dinamica temporal, sazonalidade, densidade,
#' rotas, odds ratios e segmentacao de personas.

library(ggplot2)

# Paleta oficial acessivel (contraste WCAG 2.1 AA)
cyclistic_colors <- c(
  "Membro" = "#1E3A8A",   # Azul institucional profundo (rotina e previsibilidade)
  "Casual" = "#D97706"    # Laranja ambar quente (espontaneidade e viagens de lazer)
)

theme_cyclistic <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(1.15),
        color = "#0F172A",
        margin = ggplot2::margin(b = 6)
      ),
      plot.subtitle = ggplot2::element_text(
        color = "#475569",
        size = ggplot2::rel(0.92),
        margin = ggplot2::margin(b = 12)
      ),
      plot.caption = ggplot2::element_text(
        color = "#94A3B8",
        size = ggplot2::rel(0.8),
        margin = ggplot2::margin(t = 10)
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(color = "#E2E8F0", linewidth = 0.5),
      axis.title = ggplot2::element_text(color = "#334155", size = ggplot2::rel(0.9)),
      axis.text = ggplot2::element_text(color = "#475569"),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(color = "#1E293B", face = "bold"),
      strip.text = ggplot2::element_text(
        face = "bold",
        color = "#1E293B",
        hjust = 0,
        size = ggplot2::rel(0.95)
      )
    )
}

scale_color_cyclistic <- function(...) {
  ggplot2::scale_color_manual(values = cyclistic_colors, ...)
}

scale_fill_cyclistic <- function(...) {
  ggplot2::scale_fill_manual(values = cyclistic_colors, ...)
}

# 1. Volume de Viagens por Hora do Dia (com anotacoes de pico)
plot_trips_by_hour <- function(df) {
  df |>
    dplyr::group_by(member_casual, start_hour) |>
    dplyr::summarise(total = dplyr::n(), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = start_hour, y = total, color = member_casual, group = member_casual)) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_x_continuous(breaks = seq(0, 23, by = 2)) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    scale_color_cyclistic() +
    theme_cyclistic() +
    ggplot2::annotate("rect", xmin = 7.5, xmax = 8.5, ymin = 0, ymax = Inf, alpha = 0.08, fill = "#1E3A8A") +
    ggplot2::annotate("rect", xmin = 16.5, xmax = 17.5, ymin = 0, ymax = Inf, alpha = 0.08, fill = "#1E3A8A") +
    ggplot2::labs(
      title = "Volume de Viagens por Hora do Dia",
      subtitle = "Picos as 8h e 17h evidenciam o fluxo pendular corporativo dos membros anuais",
      x = "Hora de Inicio da Corrida",
      y = "Total de Viagens"
    )
}

# 2. Duracao Mediana das Viagens por Hora
plot_duration_by_hour <- function(df) {
  df |>
    dplyr::group_by(member_casual, start_hour) |>
    dplyr::summarise(mediana_duracao = stats::median(trip_duration_min), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = start_hour, y = mediana_duracao, color = member_casual, group = member_casual)) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_x_continuous(breaks = seq(0, 23, by = 2)) +
    scale_color_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Duracao Mediana das Viagens por Horario",
      subtitle = "Ciclistas casuais mantem duracoes 2x maiores, com pico proximo a 35 min a tarde",
      x = "Hora de Inicio da Corrida",
      y = "Duracao Mediana (minutos)"
    )
}

# 3. Volume por Dia da Semana
plot_trips_by_weekday <- function(df) {
  df |>
    dplyr::group_by(member_casual, weekday) |>
    dplyr::summarise(total = dplyr::n(), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = weekday, y = total, fill = member_casual)) +
    ggplot2::geom_col(position = "dodge2", width = 0.7) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    scale_fill_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Distribuicao de Viagens por Dia da Semana",
      subtitle = "Inversao de demanda: membros dominam os dias uteis; casuais lideram no fim de semana",
      x = "Dia da Semana",
      y = "Total de Viagens"
    )
}

# 4. Sazonalidade Mensal
plot_seasonal_trends <- function(df) {
  df |>
    dplyr::group_by(member_casual, month) |>
    dplyr::summarise(total = dplyr::n(), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = month, y = total, color = member_casual, group = member_casual)) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.2) +
    scale_color_cyclistic() +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    theme_cyclistic() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)) +
    ggplot2::labs(
      title = "Evolucao Sazonal Mensal de Viagens",
      subtitle = "O inverno rigoroso de Chicago (dez a fev) comprime o volume de casuais de forma severa",
      x = "Mes do Ano",
      y = "Total de Viagens"
    )
}

# 5. Distribuicao Empirica de Densidade da Duracao
plot_density_duration <- function(df) {
  # Limita visualizacao ate 90 min para melhor escala
  df |>
    dplyr::filter(trip_duration_min <= 90) |>
    ggplot2::ggplot(ggplot2::aes(x = trip_duration_min, fill = member_casual, color = member_casual)) +
    ggplot2::geom_density(alpha = 0.35, linewidth = 0.8) +
    scale_fill_cyclistic() +
    scale_color_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Distribuicao de Densidade do Tempo de Viagem",
      subtitle = "Membros apresentam curva concentrada em trajetos curtos; casuais exibem cauda longa",
      x = "Duracao da Corrida (minutos)",
      y = "Densidade Probabilistica"
    )
}

# 6. Top Estacoes de Partida
plot_top_stations <- function(df, top_n = 10) {
  df |>
    dplyr::filter(!is.na(start_station_name)) |>
    dplyr::group_by(start_station_name) |>
    dplyr::summarise(total = dplyr::n(), .groups = "drop") |>
    dplyr::slice_max(order_by = total, n = top_n) |>
    ggplot2::ggplot(ggplot2::aes(x = stats::reorder(start_station_name, total), y = total)) +
    ggplot2::geom_col(fill = "#1E3A8A", width = 0.65) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    theme_cyclistic() +
    ggplot2::labs(
      title = paste("Top", top_n, "Estacoes de Partida Mais Utilizadas"),
      subtitle = "Forte concentracao na orla do Lago Michigan e polos turisticos (ex: Streeter Dr)",
      x = "",
      y = "Total de Viagens"
    )
}

# 7. Taxa de Rotas Circulares (Viagens de Lazer)
plot_round_trips <- function(df) {
  df |>
    dplyr::group_by(member_casual) |>
    dplyr::summarise(taxa_pct = mean(is_round_trip, na.rm = TRUE) * 100, .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = member_casual, y = taxa_pct, fill = member_casual)) +
    ggplot2::geom_col(width = 0.55) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f%%", taxa_pct)),
      vjust = -0.4,
      fontface = "bold",
      color = "#0F172A"
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 25), labels = function(x) paste0(x, "%")) +
    scale_fill_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Proporcao de Rotas Circulares (Origem = Destino)",
      subtitle = "Ciclistas casuais realizam quase 5 vezes mais circuitos fechados para recreacao",
      x = "",
      y = "Viagens Circulares (%)"
    )
}

# 8. Forest Plot de Odds Ratios da Regressao Logistica
plot_forest_odds_ratios <- function(odds_df) {
  # Filtra intercepto para visualizacao dos preditores
  plot_data <- odds_df |>
    dplyr::filter(variavel != "(Intercept)") |>
    dplyr::mutate(
      rotulo = dplyr::case_when(
        variavel == "is_commute_hours" ~ "Horario de Pico Comercial",
        variavel == "is_weekend_num" ~ "Fim de Semana",
        variavel == "distance_km" ~ "Distancia Percorrida (km)",
        variavel == "rideable_typedocked_bike" ~ "Modal: Docked Bike",
        variavel == "rideable_typeelectric_bike" ~ "Modal: Electric Bike",
        variavel == "seasonVerao" ~ "Estacao: Verao",
        variavel == "seasonOutono" ~ "Estacao: Outono",
        variavel == "seasonInverno" ~ "Estacao: Inverno",
        TRUE ~ variavel
      )
    )
  
  ggplot2::ggplot(plot_data, ggplot2::aes(x = odds_ratio, y = stats::reorder(rotulo, odds_ratio))) +
    ggplot2::geom_vline(xintercept = 1.0, linetype = "dashed", color = "#94A3B8", linewidth = 0.8) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = ci_inf, xmax = ci_sup), width = 0.25, color = "#1E3A8A", linewidth = 0.9) +
    ggplot2::geom_point(size = 3.2, color = "#1E3A8A") +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Odds Ratios: Fatores Associados ao Perfil de Membro Anual",
      subtitle = "Picos comerciais e dias uteis multiplicam a propensao de comportamento comutador",
      x = "Odds Ratio (Razao de Chances com IC 95%)",
      y = ""
    )
}

# 9. Distribuicao das Personas Casuais
plot_persona_breakdown <- function(personas_df) {
  ggplot2::ggplot(personas_df, ggplot2::aes(x = stats::reorder(persona, volume_viagens), y = volume_viagens, fill = persona)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%s (%s%%)", scales::number(volume_viagens, big.mark = "."), proporcao_pct)),
      hjust = -0.1,
      fontface = "bold",
      color = "#0F172A",
      size = 3.8
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(big.mark = "."),
      expand = ggplot2::expansion(mult = c(0, 0.25))
    ) +
    ggplot2::scale_fill_manual(values = c(
      "Comutador Oculto" = "#1E3A8A",
      "Lazer de Fim de Semana" = "#D97706",
      "Espontaneo / Noite" = "#64748B"
    )) +
    theme_cyclistic() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(
      title = "Segmentacao Comportamental dos Ciclistas Casuais",
      subtitle = "O segmento 'Comutador Oculto' representa o publico-alvo prioritario para conversao",
      x = "",
      y = "Volume de Viagens"
    )
}
