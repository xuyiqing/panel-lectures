library(dplyr)
library(fixest)
library(ggplot2)
library(haven)
library(patchwork)
library(plm)

purple <- "#4E2A84"
blue <- "#2F6B9A"
orange <- "#D97706"
ink <- "#252A34"
mist <- "#F4F2F8"

theme_workshop <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.35),
      axis.title = element_text(color = ink),
      axis.text = element_text(color = ink),
      strip.text = element_text(face = "bold", color = ink),
      strip.background = element_rect(fill = mist, color = NA),
      legend.position = "bottom"
    )
}

## Two empirical applications ------------------------------------------------
swiss <- read_dta("figs/Swiss_Panel_long.dta") |>
  mutate(
    year = as.integer(year),
    time = year - min(year),
    regime = if_else(repdem == 1,
                     "Representative democracy", "Direct democracy")
  )

switcher_ids <- c(3032, 739, 242, 3024, 415, 352)
swiss_intro <- swiss |>
  filter(muniID %in% switcher_ids) |>
  mutate(muni_name = factor(muni_name, levels = unique(muni_name)))

p_naturalization_intro <- ggplot(
  swiss_intro, aes(year, nat_rate, group = muniID)
) +
  geom_line(color = "grey65", linewidth = 0.65) +
  geom_point(aes(color = regime), size = 1.55) +
  facet_wrap(~ muni_name, nrow = 2) +
  scale_color_manual(values = c(
    "Direct democracy" = blue,
    "Representative democracy" = orange
  )) +
  scale_x_continuous(breaks = c(1991, 2000, 2009)) +
  labs(x = "Year", y = "Naturalization rate (%)", color = NULL) +
  theme_workshop(10.5) +
  theme(panel.spacing = grid::unit(0.45, "lines"),
        legend.text = element_text(size = 8.5))

ggsave("figs/naturalization_intro_2026.pdf", p_naturalization_intro,
       width = 7.0, height = 4.8, device = cairo_pdf)

data("Fatalities", package = "AER")
fatalities <- Fatalities |>
  mutate(
    state = toupper(as.character(state)),
    year = as.integer(as.character(year)),
    fatal_rate = 10000 * fatal / pop
  )

p_fatalities_intro <- ggplot(fatalities, aes(beertax, fatal_rate)) +
  geom_point(color = blue, alpha = 0.42, size = 1.45) +
  geom_smooth(method = "lm", se = FALSE, color = ink,
              linewidth = 1.0, linetype = "dashed") +
  labs(x = "Real beer tax per case", y = "Traffic deaths per 10,000") +
  theme_workshop(11.5)

ggsave("figs/fatalities_intro_2026.pdf", p_fatalities_intro,
       width = 7.0, height = 4.8, device = cairo_pdf)

## Counterfactual imputation under three panel models ------------------------
set.seed(20260805)
toy_times <- 1:10
toy_units <- c(paste0("Control ", 1:8), "Treated")
toy_intercepts <- c(-1.15, -0.75, -0.35, -0.05, 0.25, 0.55, 0.90, 1.20, 1.05)
toy_slopes <- c(-0.045, 0.020, -0.025, 0.040, 0.025, -0.015, 0.035, -0.035, 0.23)
toy_common <- c(0.00, 0.32, -0.10, 0.48, 0.16, 0.62, 0.30, 0.88, 0.52, 1.05)

toy_panel <- expand.grid(
  unit = factor(toy_units, levels = toy_units),
  time = toy_times
) |>
  arrange(unit, time) |>
  mutate(
    unit_id = as.integer(unit),
    treated = unit == "Treated",
    post = time >= 7,
    y0 = toy_intercepts[unit_id] + toy_slopes[unit_id] * time +
      toy_common[time] + rnorm(n(), sd = 0.055),
    effect = if_else(treated & post, 1.15 + 0.18 * (time - 7), 0),
    y = y0 + effect
  )

toy_control_mean <- toy_panel |>
  filter(!treated) |>
  group_by(time) |>
  summarize(control_mean = mean(y), .groups = "drop")

toy_treated_pre <- toy_panel |>
  filter(treated, !post) |>
  left_join(toy_control_mean, by = "time")

toy_level_gap <- mean(toy_treated_pre$y - toy_treated_pre$control_mean)
toy_trend_fit <- lm(I(y - control_mean) ~ time, data = toy_treated_pre)

toy_predictions <- toy_control_mean |>
  mutate(
    unit_fe = mean(toy_treated_pre$y),
    twfe = control_mean + toy_level_gap,
    twfe_trend = control_mean + predict(toy_trend_fit, newdata = data.frame(time))
  ) |>
  filter(time >= 7)

toy_controls <- toy_panel |> filter(!treated)
toy_treated <- toy_panel |> filter(treated)

counterfactual_panel <- function(prediction, panel_title, panel_subtitle) {
  pred_data <- toy_predictions |>
    transmute(time, imputed = .data[[prediction]])

  ggplot() +
    annotate("rect", xmin = 6.5, xmax = 10.5, ymin = -Inf, ymax = Inf,
             fill = mist, alpha = 0.65) +
    geom_line(
      data = toy_controls,
      aes(time, y, group = unit),
      color = "grey76", linewidth = 0.55
    ) +
    geom_point(
      data = toy_controls,
      aes(time, y), color = "grey76", alpha = 0.65, size = 0.9
    ) +
    geom_line(
      data = toy_treated,
      aes(time, y), color = orange, linewidth = 1.15
    ) +
    geom_point(
      data = toy_treated,
      aes(time, y), color = orange, size = 1.8
    ) +
    geom_line(
      data = pred_data,
      aes(time, imputed), color = purple, linewidth = 1.25,
      linetype = "longdash"
    ) +
    geom_point(
      data = pred_data |> filter(time >= 7),
      aes(time, imputed), color = purple, size = 1.7, shape = 21,
      fill = "white", stroke = 0.8
    ) +
    geom_vline(xintercept = 6.5, color = ink, linewidth = 0.55,
               linetype = "dotted") +
    annotate("text", x = 6.72, y = 5.75, label = "Treatment begins",
             hjust = 0, color = ink, size = 3.0) +
    scale_x_continuous(breaks = c(1, 3, 5, 7, 9), limits = c(1, 10.2)) +
    coord_cartesian(ylim = c(-1.3, 6.1)) +
    labs(title = panel_title, subtitle = panel_subtitle,
         x = "Time", y = "Outcome") +
    theme_workshop(10.5) +
    theme(
      plot.title = element_text(face = "bold", color = ink, size = 11.5),
      plot.subtitle = element_text(color = ink, size = 9.5),
      legend.position = "none"
    )
}

p_impute_unit <- counterfactual_panel(
  "unit_fe", expression("One-way unit FE: " * alpha[i]),
  "Pre-treatment mean"
)
p_impute_twfe <- counterfactual_panel(
  "twfe", expression("Two-way fixed effects: " * alpha[i] + lambda[t]),
  "Pre-treatment level + time effects\nfrom controls"
)
p_impute_trend <- counterfactual_panel(
  "twfe_trend",
  expression("TWFE + unit-specific trends: " * alpha[i] + lambda[t] + delta[i] * t),
  "Also uses the treated unit's trend\nrelative to controls"
)

p_counterfactual_models <-
  p_impute_unit + p_impute_twfe + p_impute_trend +
  plot_annotation(
    caption = "Orange: observed outcome, eventually treated unit    Purple: imputed Y(0), periods 7-10    Gray: observed controls"
  ) &
  theme(plot.caption = element_text(color = ink, hjust = 0.5, size = 10.5))

ggsave("figs/counterfactual_imputation_models_2026.pdf",
       p_counterfactual_models, width = 11.2, height = 4.5,
       device = cairo_pdf)

## Beer taxes and traffic fatalities: pooled, FE, RE, and two-way FE ---------
fatalities_panel <- pdata.frame(fatalities, index = c("state", "year"))
models <- list(
  "Pooled OLS" = plm(fatal_rate ~ beertax, data = fatalities_panel,
                     model = "pooling"),
  "State FE" = plm(fatal_rate ~ beertax, data = fatalities_panel,
                   model = "within", effect = "individual"),
  "Random effects" = plm(fatal_rate ~ beertax, data = fatalities_panel,
                         model = "random", random.method = "swar"),
  "State + year FE" = plm(fatal_rate ~ beertax, data = fatalities_panel,
                          model = "within", effect = "twoways")
)

model_rows <- lapply(models, function(model) {
  vcov_cluster <- vcovHC(model, method = "arellano", type = "HC1",
                         cluster = "group")
  c(estimate = coef(model)[["beertax"]],
    std_error = sqrt(diag(vcov_cluster))[["beertax"]])
})
model_results <- do.call(rbind, model_rows)

table_lines <- c(
  "\\begin{tabular}{lc}",
  "\\textbf{Model} & \\textbf{Beer-tax coefficient} \\\\ \\hline",
  sprintf("%s & %.3f (%.3f) \\\\",
          rownames(model_results), model_results[, "estimate"],
          model_results[, "std_error"]),
  "\\end{tabular}"
)
writeLines(table_lines, "figs/fatalities_results_2026.tex")

## Connectedness: actual observations from the naturalization replication ----
library(panelView)
network_ids <- c(402, 423, 875, 1218, 2441, 5812, 6296, 947, 1369, 421)
network_data <- read_dta("figs/swissnat.dta") |>
  mutate(
    observed = complete.cases(
      nat_rate_ord, institution_linearB, ue_rate, svpzero
    )
  ) |>
  filter(year >= 1998, bfs %in% network_ids, observed) |>
  transmute(municipality = ort_name, year = as.integer(year))

network_plot <- panelview(
  network_data, ~ 1,
  index = c("municipality", "year"),
  type = "network",
  layout = "bipartite",
  show.labels = "all",
  node.size = 3.6,
  edge.width = 0.65,
  main = NULL
)
ggsave("figs/naturalization_network_2026.pdf", network_plot$plot,
       width = 10.0, height = 5.2, device = cairo_pdf)

## Simpson's paradox: actual state-year observations -------------------------
fatalities_dm <- fatalities |>
  group_by(state) |>
  mutate(
    beertax_dm = beertax - mean(beertax),
    fatal_rate_dm = fatal_rate - mean(fatal_rate)
  ) |>
  ungroup()

p_pooled <- ggplot(fatalities, aes(beertax, fatal_rate)) +
  geom_point(color = blue, alpha = 0.42, size = 1.45) +
  geom_smooth(method = "lm", se = FALSE, color = ink,
              linewidth = 1.25, linetype = "dashed") +
  annotate("text", x = 1.45, y = 3.9,
           label = "Pooled slope: +0.365", hjust = 0,
           color = ink, size = 4.0) +
  labs(title = "Across states and years",
       x = "Real beer tax per case", y = "Traffic deaths per 10,000") +
  theme_workshop(11.5) +
  theme(plot.title = element_text(face = "bold", color = ink, size = 12))

p_within <- ggplot(fatalities_dm, aes(beertax_dm, fatal_rate_dm)) +
  geom_hline(yintercept = 0, color = "grey85", linewidth = 0.4) +
  geom_vline(xintercept = 0, color = "grey85", linewidth = 0.4) +
  geom_point(color = orange, alpha = 0.46, size = 1.45) +
  geom_smooth(method = "lm", se = FALSE, color = purple,
              linewidth = 1.25) +
  annotate("text", x = 0.22, y = 0.78,
           label = "FE slope: -0.656", hjust = 1,
           color = purple, size = 4.0) +
  labs(title = "After subtracting each state's mean",
       x = "Beer-tax deviation", y = "Fatality-rate deviation") +
  theme_workshop(11.5) +
  theme(plot.title = element_text(face = "bold", color = ink, size = 12))

ggsave(
  "figs/fatalities_within_2026.pdf",
  p_within + labs(title = NULL),
  width = 7.0, height = 4.8, device = cairo_pdf
)

p_simpson <- p_pooled + p_within + plot_layout(guides = "collect")

ggsave("figs/simpson_fe_2026.pdf", p_simpson,
       width = 10.2, height = 5.0, device = cairo_pdf)

## Two states: between-state levels and within-state changes -----------------
highlight_states <- c("PA", "GA")
state_labels <- c("PA" = "Pennsylvania", "GA" = "Georgia")

fatalities_highlight <- fatalities |>
  mutate(
    highlight = if_else(state %in% highlight_states,
                        state_labels[state], "Other states"),
    highlight = factor(
      highlight,
      levels = c("Other states", "Pennsylvania", "Georgia")
    )
  )

highlight_means <- fatalities_highlight |>
  filter(state %in% highlight_states) |>
  group_by(state, highlight) |>
  summarize(
    beertax = mean(beertax),
    fatal_rate = mean(fatal_rate),
    .groups = "drop"
  )

highlight_colors <- c(
  "Other states" = "grey78",
  "Pennsylvania" = purple,
  "Georgia" = orange
)

p_between_states <- ggplot() +
  geom_point(
    data = filter(fatalities_highlight, highlight == "Other states"),
    aes(beertax, fatal_rate), color = "grey78", alpha = 0.45, size = 1.2
  ) +
  geom_point(
    data = filter(fatalities_highlight, highlight != "Other states"),
    aes(beertax, fatal_rate, color = highlight), size = 2.1
  ) +
  geom_smooth(
    data = filter(fatalities_highlight, highlight != "Other states"),
    aes(beertax, fatal_rate, color = highlight),
    method = "lm", se = FALSE, linewidth = 1.1
  ) +
  geom_point(
    data = highlight_means,
    aes(beertax, fatal_rate, color = highlight),
    shape = 23, fill = "white", stroke = 1.4, size = 4.2
  ) +
  scale_color_manual(values = highlight_colors, guide = "none") +
  labs(
    title = "Levels: states differ in their averages",
    x = "Real beer tax per case", y = "Traffic deaths per 10,000",
    color = NULL
  ) +
  theme_workshop(11.5) +
  theme(plot.title = element_text(face = "bold", color = ink, size = 12),
        legend.position = "none")

p_within_states <- ggplot() +
  geom_hline(yintercept = 0, color = "grey75", linewidth = 0.45) +
  geom_vline(xintercept = 0, color = "grey75", linewidth = 0.45) +
  geom_point(
    data = filter(fatalities_dm, !state %in% highlight_states),
    aes(beertax_dm, fatal_rate_dm), color = "grey78", alpha = 0.45, size = 1.2
  ) +
  geom_point(
    data = filter(fatalities_dm, state %in% highlight_states) |>
      mutate(highlight = factor(state_labels[state],
                                levels = c("Pennsylvania", "Georgia"))),
    aes(beertax_dm, fatal_rate_dm, color = highlight), size = 2.1
  ) +
  geom_smooth(
    data = filter(fatalities_dm, state %in% highlight_states) |>
      mutate(highlight = factor(state_labels[state],
                                levels = c("Pennsylvania", "Georgia"))),
    aes(beertax_dm, fatal_rate_dm, color = highlight),
    method = "lm", se = FALSE, linewidth = 1.1
  ) +
  scale_color_manual(values = highlight_colors, guide = "none") +
  labs(
    title = "Demeaned: each state is centered at zero",
    x = "Beer-tax deviation", y = "Fatality-rate deviation", color = NULL
  ) +
  theme_workshop(11.5) +
  theme(plot.title = element_text(face = "bold", color = ink, size = 12),
        legend.position = "none")

p_within_between_states <-
  p_between_states + p_within_states +
  plot_annotation(caption = "Purple: Pennsylvania    Orange: Georgia") &
  theme(plot.caption = element_text(color = ink, hjust = 0.5, size = 10.5))

ggsave("figs/within_between_two_states_2026.pdf", p_within_between_states,
       width = 10.2, height = 5.1, device = cairo_pdf)

## Three approaches to time --------------------------------------------------
time_base <- expand.grid(unit = factor(paste("Unit", LETTERS[1:4])), time = 1:8)
unit_intercepts <- c(-1.2, -0.3, 0.7, 1.6)

common_trend <- time_base |>
  mutate(y = unit_intercepts[as.integer(unit)] + 0.48 * time)

p_common <- ggplot(common_trend, aes(time, y, color = unit)) +
  geom_line(linewidth = 1.15) +
  geom_point(size = 2.0) +
  annotate("segment", x = 1.2, xend = 7.5, y = 4.4, yend = 7.42,
           color = ink, linewidth = 1.2,
           arrow = grid::arrow(length = grid::unit(0.12, "inches"))) +
  annotate("text", x = 4.3, y = 6.25, label = "One common slope",
           color = ink, size = 4.4) +
  scale_color_viridis_d(option = "D", end = 0.82) +
  scale_x_continuous(breaks = 1:8) +
  labs(x = "Time", y = "Outcome", color = NULL) +
  theme_workshop(13)

ggsave("figs/time_common_trend_2026.pdf", p_common,
       width = 9.4, height = 5.0, device = cairo_pdf)

year_shock <- c(0.0, 0.3, 0.1, 1.8, -0.7, 0.4, 0.9, 0.2)
year_fe <- time_base |>
  mutate(y = unit_intercepts[as.integer(unit)] + year_shock[time])
year_mean <- year_fe |>
  group_by(time) |>
  summarize(y = mean(y), .groups = "drop")

p_year <- ggplot(year_fe, aes(time, y, color = unit)) +
  geom_line(linewidth = 0.75, alpha = 0.65) +
  geom_point(size = 1.7, alpha = 0.75) +
  geom_line(data = year_mean, aes(time, y), inherit.aes = FALSE,
            color = ink, linewidth = 1.7) +
  geom_point(data = year_mean, aes(time, y), inherit.aes = FALSE,
             color = ink, size = 2.8) +
  annotate("text", x = 4.1, y = 3.75, label = "Common year effect",
           color = ink, hjust = 0, size = 4.4) +
  scale_color_viridis_d(option = "D", end = 0.82) +
  scale_x_continuous(breaks = 1:8) +
  labs(x = "Time", y = "Outcome", color = NULL) +
  theme_workshop(13)

ggsave("figs/time_year_fe_2026.pdf", p_year,
       width = 9.4, height = 5.0, device = cairo_pdf)

# 2026-09-15: paths now include unit FEs (same intercepts as the other two
# panels), the common year shocks, and milder unit slopes -- the old version
# was pure crossing linear trends, too drastic and inconsistent with the
# model on the slide (y = xb + c_i + g_i t + delta_t + e). Dashed = c_i + g_i t.
unit_slopes <- c(-0.12, 0.04, 0.18, 0.32)
unit_trends <- time_base |>
  mutate(
    intercept = unit_intercepts[as.integer(unit)],
    slope = unit_slopes[as.integer(unit)],
    trend = intercept + slope * time,
    y = trend + year_shock[time]
  )

p_unit <- ggplot(unit_trends, aes(time, y, color = unit)) +
  geom_line(aes(y = trend), linetype = "22", linewidth = 0.7, alpha = 0.55) +
  geom_line(linewidth = 1.15) +
  geom_point(size = 2.0) +
  annotate("text", x = 1.05, y = 5.35,
           label = "Different linear trend for each unit (dashed)",
           color = ink, hjust = 0, size = 4.4) +
  scale_color_viridis_d(option = "D", end = 0.82) +
  scale_x_continuous(breaks = 1:8) +
  labs(x = "Time", y = "Outcome", color = NULL) +
  theme_workshop(13)

ggsave("figs/time_unit_trends_2026.pdf", p_unit,
       width = 9.4, height = 5.0, device = cairo_pdf)

## Naturalization application: sensitivity to time controls -----------------
swiss_year_means <- swiss |>
  group_by(year) |>
  summarize(
    `Naturalization rate` = mean(nat_rate, na.rm = TRUE),
    `Representative democracy` = mean(repdem, na.rm = TRUE),
    .groups = "drop"
  )
swiss_year_long <- bind_rows(
  transmute(swiss_year_means, year, series = "Naturalization rate",
            value = `Naturalization rate`),
  transmute(swiss_year_means, year, series = "Representative democracy",
            value = `Representative democracy`)
) |>
  group_by(series) |>
  mutate(index = (value - first(value)) / sd(value)) |>
  ungroup()

p_swiss_common <- ggplot(swiss_year_long, aes(year, index, color = series)) +
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.5) +
  geom_line(linewidth = 1.25) +
  geom_point(size = 2.0) +
  scale_color_manual(values = c(
    "Naturalization rate" = purple,
    "Representative democracy" = orange
  )) +
  scale_x_continuous(breaks = seq(1991, 2009, by = 3)) +
  labs(x = "Year", y = "Change from 1991 (standard deviations)", color = NULL) +
  theme_workshop(13)

ggsave("figs/hh_common_shocks_2026.pdf", p_swiss_common,
       width = 9.4, height = 5.0, device = cairo_pdf)

swiss_models <- list(
  "Pooled OLS" = feols(nat_rate ~ repdem, data = swiss,
                       cluster = ~ muniID),
  "Municipality FE" = feols(nat_rate ~ repdem | muniID, data = swiss,
                             cluster = ~ muniID),
  "+ year FE" = feols(nat_rate ~ repdem | muniID + year, data = swiss,
                       cluster = ~ muniID),
  "+ municipality trends" = feols(
    nat_rate ~ repdem | muniID + year + muniID[time],
    data = swiss, cluster = ~ muniID
  )
)

swiss_results <- bind_rows(lapply(names(swiss_models), function(name) {
  model <- swiss_models[[name]]
  data.frame(
    model = name,
    estimate = coef(model)[["repdem"]],
    std_error = se(model)[["repdem"]]
  )
})) |>
  mutate(
    model = factor(model, levels = names(swiss_models)),
    lower = estimate - 1.96 * std_error,
    upper = estimate + 1.96 * std_error
  )

p_swiss <- ggplot(swiss_results, aes(model, estimate, group = 1)) +
  geom_hline(yintercept = 0, color = "grey65", linewidth = 0.5) +
  geom_line(color = "grey65", linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.12,
                color = purple, linewidth = 0.9) +
  geom_point(color = purple, fill = "white", shape = 21,
             stroke = 1.2, size = 3.5) +
  geom_text(aes(label = sprintf("%.2f", estimate)), vjust = -1.35,
            color = ink, size = 4.1) +
  coord_cartesian(ylim = c(0, 3.7), clip = "off") +
  labs(x = NULL,
       y = "Coefficient on representative democracy (percentage points)") +
  theme_workshop(13) +
  theme(axis.text.x = element_text(angle = 12, hjust = 1),
        legend.position = "none")

ggsave("figs/hh_time_controls_2026.pdf", p_swiss,
       width = 9.4, height = 5.0, device = cairo_pdf)

message("Updated Lecture 1 figures and model results.")
