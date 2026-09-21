# Card and Krueger (1994) redrawn from the public store-level data (CK1994_longformat.dta):
#   ck_wages_before_2026.pdf, ck_wages_after_2026.pdf  starting-wage distributions in New Jersey
#                                                       and Pennsylvania, February and November 1992
#   ck_map_2026.pdf                                     the geography of the comparison
# Run from this folder:  Rscript card_krueger_2026.R
suppressPackageStartupMessages({library(haven); library(dplyr); library(ggplot2); library(maps)})

d <- read_dta("CK1994_longformat.dta")
bins <- seq(4.25, 5.55, by = 0.10)
w <- d |>
  filter(!is.na(wage_st)) |>
  mutate(state = ifelse(nj == 1, "New Jersey", "Pennsylvania"),
         wave  = ifelse(postperiod == 1, "November 1992", "February 1992"),
         bin   = bins[pmax(1, pmin(length(bins), 1 + round((wage_st - 4.25) / 0.10)))]) |>
  count(wave, state, bin) |>
  group_by(wave, state) |> mutate(pct = 100 * n / sum(n)) |> ungroup()

plot_wave <- function(wv, file) {
  dat <- filter(w, wave == wv) |> mutate(bin = factor(sprintf("%.2f", bin), levels = sprintf("%.2f", bins)))
  p <- ggplot(dat, aes(bin, pct, fill = state)) +
    geom_col(position = position_dodge(width = 0.8, preserve = "single"), width = 0.75) +
    scale_fill_manual(values = c("New Jersey" = "grey15", "Pennsylvania" = "grey70")) +
    scale_x_discrete(drop = FALSE) +
    labs(title = wv, x = "Starting wage (dollars per hour)", y = "Percent of stores", fill = NULL) +
    theme_classic(base_size = 13) +
    theme(legend.position = "bottom", axis.text.x = element_text(angle = 90, vjust = 0.5, size = 9),
          plot.title = element_text(hjust = 0.5))
  ggsave(file, p, width = 5.2, height = 4.8)
}
plot_wave("February 1992", "ck_wages_before_2026.pdf")
plot_wave("November 1992", "ck_wages_after_2026.pdf")

# Map: New Jersey (treated) against eastern Pennsylvania (comparison). County outlines from
# the maps package; the paper's stores were sampled in New Jersey and in eastern Pennsylvania.
cty <- map_data("county", region = c("new jersey", "pennsylvania"))
st  <- map_data("state",  region = c("new jersey", "pennsylvania"))
cty <- cty |> mutate(area = case_when(region == "new jersey" ~ "New Jersey (minimum wage rose)",
                                      long > -76.4 ~ "Eastern Pennsylvania (comparison)",
                                      TRUE ~ "Rest of Pennsylvania"))
p <- ggplot() +
  geom_polygon(data = cty, aes(long, lat, group = group, fill = area), colour = "white", linewidth = 0.25) +
  geom_polygon(data = st, aes(long, lat, group = group), fill = NA, colour = "grey20", linewidth = 0.6) +
  annotate("text", x = -77.9, y = 40.9, label = "PA", size = 6, colour = "grey20") +
  annotate("text", x = -74.4, y = 39.6, label = "NJ", size = 6, colour = "white") +
  scale_fill_manual(values = c("New Jersey (minimum wage rose)" = "grey25",
                               "Eastern Pennsylvania (comparison)" = "grey60",
                               "Rest of Pennsylvania" = "grey90")) +
  coord_quickmap() +
  labs(fill = NULL) +
  theme_void(base_size = 13) + theme(legend.position = "bottom", legend.direction = "vertical")
ggsave("ck_map_2026.pdf", p, width = 6.2, height = 5.4)
cat("wrote ck_wages_before_2026.pdf, ck_wages_after_2026.pdf, ck_map_2026.pdf\n")
