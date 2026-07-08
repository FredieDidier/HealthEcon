# =============================================================================
# 12_maps.R — municipal choropleth maps of the cesarean epidemic.
#   Map 1: cesarean share of ALL births by municipality (SINASC, 2020-2024 avg).
#   Map 2: cesarean share of PRIVATE deliveries by municipality (TISS, 2020-2024,
#          municipalities with at least 100 private deliveries in the window).
# Municipality polygons from geobr (IBGE 2020, simplified). Outputs to
# analysis/output/maps/ as PDF + PNG.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, sf, geobr, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
MAP <- here::here("analysis", "output", "maps")
dir.create(MAP, recursive = TRUE, showWarnings = FALSE)

# elegant diverging-warm gradient (navy → sand → deep red)
GRAD <- c("#1A3A5C", "#2E6F9E", "#8FBBD9", "#F4E9D8", "#EFB366", "#D35D3F", "#8E1E20")

save_map <- function(plot, name, width = 7.5, height = 7.5) {
  ggsave(file.path(MAP, paste0(name, ".pdf")), plot, width = width, height = height, bg = "white")
  ggsave(file.path(MAP, paste0(name, ".png")), plot, width = width, height = height, dpi = 300, bg = "white")
}

theme_map <- function() {
  theme_void(base_size = 13) +
    theme(legend.position = "bottom",
          legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.35, "cm"),
          legend.title = element_text(size = 11), legend.text = element_text(size = 10))
}

# --- municipality polygons (7-digit code → 6-digit key) ------------------------
mu <- geobr::read_municipality(year = 2020, simplified = TRUE, showProgress = FALSE)
mu <- sf::st_as_sf(mu)
mu$muni6 <- substr(as.character(mu$code_muni), 1, 6)

# --- Map 1: all-births cesarean share (SINASC 2020-2024) -----------------------
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]
m1 <- sd[year %between% c(2020, 2024),
         .(births = sum(births), rate = sum(cesarean) / sum(births)), by = muni]
m1 <- m1[births >= 50]
mp1 <- merge(mu, m1[, .(muni6 = muni, rate)], by = "muni6", all.x = TRUE)

map1 <- ggplot(mp1) +
  geom_sf(aes(fill = 100 * rate), colour = NA) +
  scale_fill_gradientn(colours = GRAD, limits = c(15, 100),
                       na.value = "grey92",
                       name = "Cesarean rate (%), all births") +
  theme_map()
save_map(map1, "map01_csection_all")

# --- Map 2: private (TISS) cesarean share (2020-2024) --------------------------
p <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
m2 <- p[!is.na(muni) & year %between% c(2020, 2024),
        .(del = sum(n_deliveries), rate = sum(n_cesarean) / sum(n_deliveries)),
        by = .(muni6 = formatC(as.integer(muni), width = 6, flag = "0"))]
m2 <- m2[del >= 100]
mp2 <- merge(mu, m2[, .(muni6, rate)], by = "muni6", all.x = TRUE)

map2 <- ggplot(mp2) +
  geom_sf(aes(fill = 100 * rate), colour = NA) +
  scale_fill_gradientn(colours = GRAD, limits = c(15, 100),
                       na.value = "grey92",
                       name = "Cesarean rate (%), private deliveries") +
  theme_map()
save_map(map2, "map02_csection_private")

message("12_maps.R done")
