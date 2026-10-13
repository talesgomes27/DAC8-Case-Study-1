#' Identidade Visual e Funcoes Graficas Padronizadas: Cyclistic Bike-Share
#'
#' @description
#' Implementa o tema customizado para ggplot2, paleta acessivel com contraste verificado
#' e funcoes encapsuladas para geracao dos graficos analiticos eliminando duplicacao.

library(ggplot2)

# Paleta oficial acessivel (contraste WCAG AA sobre fundos claros)
cyclistic_colors <- c(
  "Membro" = "#1E3A8A",   # Azul institucional profundo (rotina e previsibilidade)
  "Casual" = "#D97706"    # Laranja ambar (espontaneidade e viagens de lazer)
)

#' Tema minimalista institucional Cyclistic
#' @export
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

#' Escala de cor manual Cyclistic
#' @export
scale_color_cyclistic <- function(...) {
  ggplot2::scale_color_manual(values = cyclistic_colors, ...)
}

#' Escala de preenchimento manual Cyclistic
#' @export
scale_fill_cyclistic <- function(...) {
  ggplot2::scale_fill_manual(values = cyclistic_colors, ...)
}

#' Grafico: Volume de viagens por hora do dia
#' @export
plot_trips_by_hour <- function(df) {
  df |>
    dplyr::group_by(member_casual, start_hour) |>
    dplyr::summarise(total = dplyr::n(), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = start_hour, y = total, color = member_casual, group = member_casual)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_continuous(breaks = seq(0, 23, by = 2)) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    scale_color_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Volume de Viagens por Hora do Dia",
      subtitle = "Membros apresentam picos evidentes nos deslocamentos de trabalho (8h e 17h)",
      x = "Hora do Início da Corrida",
      y = "Total de Viagens"
    )
}

#' Grafico: Duracao media por hora do dia
#' @export
plot_duration_by_hour <- function(df) {
  df |>
    dplyr::group_by(member_casual, start_hour) |>
    dplyr::summarise(mediana_duracao = stats::median(trip_duration_min), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = start_hour, y = mediana_duracao, color = member_casual, group = member_casual)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_continuous(breaks = seq(0, 23, by = 2)) +
    scale_color_cyclistic() +
    theme_cyclistic() +
    ggplot2::labs(
      title = "Duração Mediana das Viagens por Horário",
      subtitle = "Ciclistas casuais mantêm duração consideravelmente mais longa em todas as faixas",
      x = "Hora do Início da Corrida",
      y = "Duração Mediana (minutos)"
    )
}

#' Grafico: Volume de viagens por dia da semana
#' @export
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
      title = "Distribuição de Viagens por Dia da Semana",
      subtitle = "Padrão inverso: membros concentram uso em dias úteis; casuais dominam o fim de semana",
      x = "Dia da Semana",
      y = "Total de Viagens"
    )
}

#' Grafico: As 10 estacoes de partida mais populares
#' @export
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
      title = paste("Top", top_n, "Estações de Partida Mais Utilizadas"),
      subtitle = "Concentração expressiva na orla do Lago Michigan e pontos turísticos centrais",
      x = "",
      y = "Total de Viagens"
    )
}
