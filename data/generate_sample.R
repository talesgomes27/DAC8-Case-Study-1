# Script para gerar amostra representativa de dados para reproducibilidade local
# Simula a estrutura exata do Divvy / Cyclistic Trip Data

set.seed(42)

n_trips <- 10000

# Estacoes tipicas de Chicago e suas coordenadas
stations <- tibble::tribble(
  ~name, ~lat, ~lng,
  "Streeter Dr & Grand Ave", 41.89228, -87.61204,
  "Millennium Park", 41.88103, -87.62408,
  "Michigan Ave & Oak St", 41.90096, -87.62378,
  "Clark St & Elm St", 41.90297, -87.63128,
  "Theater on the Lake", 41.92628, -87.63083,
  "Wells St & Concord Ln", 41.91213, -87.63466,
  "Clark St & Lincoln Ave", 41.91569, -87.63460,
  "Kingsbury St & Kinzie St", 41.88918, -87.63850,
  "Wabash Ave & Grand Ave", 41.89147, -87.62676,
  "Dearborn St & Erie St", 41.89399, -87.62932
)

# Proporcao de usuarios: ~55% membros, ~45% casuais
user_types <- sample(c("member", "casual"), size = n_trips, replace = TRUE, prob = c(0.55, 0.45))

# Tipos de bicicleta
bike_types <- sample(c("classic_bike", "electric_bike", "docked_bike"), size = n_trips, replace = TRUE, prob = c(0.42, 0.31, 0.27))

# Datas entre Julho de 2020 e Junho de 2021
start_epoch <- as.POSIXct("2020-07-01 00:00:00", tz = "America/Chicago")
end_epoch <- as.POSIXct("2021-06-30 23:59:59", tz = "America/Chicago")

# Sazonalidade: mais viagens no verao (jul-set), menos no inverno (jan-mar)
month_weights <- c(0.04, 0.03, 0.05, 0.08, 0.11, 0.14, 0.15, 0.15, 0.12, 0.08, 0.03, 0.02)
sampled_months <- sample(1:12, size = n_trips, replace = TRUE, prob = month_weights)
sampled_days <- sample(1:28, size = n_trips, replace = TRUE)

# Horarios: membros concentram em 7-9h e 16-18h em dias uteis; casuais concentram a tarde e fins de semana
start_times <- vector("list", n_trips)
for (i in seq_len(n_trips)) {
  yr <- if (sampled_months[i] <= 6) 2021 else 2020
  base_date <- as.Date(sprintf("%04d-%02d-%02d", yr, sampled_months[i], sampled_days[i]))
  wday_num <- as.POSIXlt(base_date)$wday # 0 = dom, 6 = sab
  is_wknd <- wday_num %in% c(0, 6)
  
  if (user_types[i] == "member") {
    if (!is_wknd) {
      hr <- sample(c(7, 8, 8, 9, 12, 16, 17, 17, 18, 19), 1)
    } else {
      hr <- sample(10:17, 1)
    }
  } else {
    if (!is_wknd) {
      hr <- sample(11:20, 1)
    } else {
      hr <- sample(11:18, 1)
    }
  }
  min_sec <- sample(0:3599, 1)
  start_times[[i]] <- as.POSIXct(base_date) + (hr * 3600) + min_sec
}
started_at <- do.call(c, start_times)

# Duracao em minutos: media ~14 min para membros, ~35 min para casuais
durations_mins <- ifelse(
  user_types == "member",
  rgamma(n_trips, shape = 3, scale = 4.5), # media ~13.5
  rgamma(n_trips, shape = 2.5, scale = 14)  # media ~35
)
# Garante limite minimo de 2 min
durations_mins <- pmax(durations_mins, 2.1)
ended_at <- started_at + (durations_mins * 60)

# Estacoes de origem e destino
start_idx <- sample(seq_len(nrow(stations)), size = n_trips, replace = TRUE)
start_station <- stations$name[start_idx]
start_lat <- stations$lat[start_idx] + rnorm(n_trips, 0, 0.0005)
start_lng <- stations$lng[start_idx] + rnorm(n_trips, 0, 0.0005)

# Casuais tem maior chance de volta a mesma estacao (round trip: ~15% vs 3% membros)
end_idx <- numeric(n_trips)
for (i in seq_len(n_trips)) {
  is_round <- if (user_types[i] == "casual") (runif(1) < 0.18) else (runif(1) < 0.03)
  if (is_round) {
    end_idx[i] <- start_idx[i]
  } else {
    end_idx[i] <- sample(seq_len(nrow(stations)), 1)
  }
}
end_station <- stations$name[end_idx]
end_lat <- stations$lat[end_idx] + rnorm(n_trips, 0, 0.0005)
end_lng <- stations$lng[end_idx] + rnorm(n_trips, 0, 0.0005)

# IDs
ride_ids <- sprintf("%016X", sample(1:1e9, n_trips, replace = FALSE))
start_station_ids <- sprintf("TA130%03d", start_idx)
end_station_ids <- sprintf("TA130%03d", end_idx)

sample_df <- data.frame(
  ride_id = ride_ids,
  rideable_type = bike_types,
  started_at = format(started_at, "%Y-%m-%d %H:%M:%S"),
  ended_at = format(ended_at, "%Y-%m-%d %H:%M:%S"),
  start_station_name = start_station,
  start_station_id = start_station_ids,
  end_station_name = end_station,
  end_station_id = end_station_ids,
  start_lat = round(start_lat, 5),
  start_lng = round(start_lng, 5),
  end_lat = round(end_lat, 5),
  end_lng = round(end_lng, 5),
  member_casual = user_types,
  stringsAsFactors = FALSE
)

write.csv(sample_df, "/home/tales/Documentos/github/DAC8-Case-Study-1/data/sample_tripdata.csv", row.names = FALSE)
cat("Amostra gerada com sucesso em data/sample_tripdata.csv (", nrow(sample_df), " linhas).\n", sep = "")
