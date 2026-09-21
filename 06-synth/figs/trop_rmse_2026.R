#!/usr/bin/env Rscript
# trop_rmse_2026.R -- Lecture 6 "TROP against the Alternatives": heatmap of Table 1 in
# Athey, Imbens, Qu, and Viviano (2026, Journal of Applied Econometrics): out-of-sample
# RMSE of six estimators in 21 semi-synthetic designs (10 treated units, 10 post-treatment
# periods), each divided by the smallest RMSE in its row. Values typed in from the
# published table on 2026-09-20. Run from this folder:
#   Rscript trop_rmse_2026.R   -> trop_rmse_2026.pdf  (12 x 5.2 in, full slide width)
suppressPackageStartupMessages(library(ggplot2))

rows <- c(
  "CPS log wage, min. wage", "CPS unemployment, min. wage", "CPS hours, min. wage",
  "CPS log wage, gun law", "CPS log wage, abortion", "CPS log wage, random",
  "PWT log GDP, democracy", "PWT log GDP, education", "PWT log GDP, random",
  "Germany GDP, random", "Germany GDP, simulated", "Germany GDP, treated unit",
  "Basque GDP, random", "Basque GDP, simulated", "Basque GDP, treated unit",
  "Prop 99 packs, random", "Prop 99 packs, simulated", "Prop 99 packs, treated unit",
  "Boatlift log wage, random", "Boatlift log wage, simulated", "Boatlift log wage, treated unit")
vals <- matrix(c(
  1.00, 1.14, 1.44, 1.91, 1.26, 1.22,
  1.00, 1.05, 1.11, 1.89, 1.10, 1.09,
  1.00, 1.19, 1.22, 1.25, 1.11, 1.20,
  1.00, 1.15, 1.13, 2.04, 1.33, 1.32,
  1.00, 1.14, 1.43, 1.99, 1.25, 1.24,
  1.00, 1.12, 1.10, 1.95, 1.24, 1.17,
  1.00, 1.44, 1.59, 7.85, 1.76, 1.54,
  1.00, 1.51, 2.10, 6.90, 1.60, 1.57,
  1.00, 1.32, 1.51, 4.31, 1.41, 1.50,
  1.00, 1.46, 2.82, 3.58, 1.56, 2.46,
  1.00, 1.79, 5.82, 7.58, 1.93, 4.72,
  1.00, 1.13, 1.82, 5.17, 1.27, 1.89,
  1.00, 1.02, 4.55, 9.11, 1.70, 2.47,
  1.00, 1.55, 2.11, 3.05, 1.30, 1.66,
  1.00, 1.35, 2.79, 1.25, 3.02, 2.94,
  1.00, 1.22, 1.48, 2.16, 1.14, 1.45,
  1.00, 1.28, 1.93, 2.88, 1.44, 1.41,
  1.00, 1.04, 1.72, 2.18, 1.27, 1.30,
  1.00, 1.34, 1.62, 1.35, 1.04, 1.62,
  1.00, 1.50, 1.31, 1.46, 1.12, 1.58,
  1.24, 1.93, 1.00, 1.35, 1.17, 2.07), ncol = 6, byrow = TRUE)
est <- c("TROP", "SDID", "SC", "DID", "MC", "DIFP")

df <- data.frame(design = rep(rows, times = 6),
                 estimator = factor(rep(est, each = length(rows)), levels = est),
                 ratio = as.vector(vals))
df$block  <- factor(ifelse(match(df$design, rows) <= 11, "designs 1-11", "designs 12-21"),
                    levels = c("designs 1-11", "designs 12-21"))
df$design <- factor(df$design, levels = rev(rows))     # first row of the table on top
df$fill   <- pmin(df$ratio, 3)                          # one hue, light -> dark, capped at 3x
df$label  <- sprintf("%.2f", df$ratio)
df$dark   <- df$ratio >= 2.2                            # white text on the darkest cells

p <- ggplot(df, aes(estimator, design, fill = fill)) +
  geom_tile(colour = "white", linewidth = 0.9) +
  geom_text(aes(label = label, colour = dark), size = 4.1) +
  scale_colour_manual(values = c(`FALSE` = "#252A34", `TRUE` = "white"), guide = "none") +
  scale_fill_gradient(low = "#FBF3F4", high = "#9E1B32", limits = c(1, 3),
                      breaks = c(1, 2, 3), labels = c("1 (best in row)", "2", "3 or more"),
                      name = "RMSE relative to the best estimator") +
  guides(fill = guide_colourbar(title.position = "top", title.hjust = 0.5)) +
  facet_wrap(~ block, ncol = 2, scales = "free_y") +
  scale_x_discrete(position = "top", expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 15) +
  theme(panel.grid = element_blank(), strip.text = element_blank(),
        axis.text.x = element_text(face = "bold", size = 13, colour = "#252A34"),
        axis.text.y = element_text(size = 12, colour = "#252A34", hjust = 1),
        legend.position = "bottom", legend.key.width = unit(1.6, "cm"),
        legend.key.height = unit(0.32, "cm"),
        legend.title = element_text(size = 12), legend.text = element_text(size = 11),
        panel.spacing.x = unit(1.2, "cm"), plot.margin = margin(2, 8, 2, 2))
ggsave("trop_rmse_2026.pdf", p, width = 12, height = 5.2)
cat("trop_rmse_2026.pdf written\n")
