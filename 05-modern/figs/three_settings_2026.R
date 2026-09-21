#!/usr/bin/env Rscript
# three_settings_2026.R -- Lecture 5 "Three Data Settings": regenerate the three
# treatment-status panels (block / staggered / general with reversal) at
# IDENTICAL dimensions (6 x 4.5 in) and styling. Run from this folder:
#   Rscript three_settings_2026.R
# Replaces sim_treat_did / sim_treat1 / sim_treat_general on that frame only
# (those originals stay in use in Lectures 4 and 6). Written 2026-09-15.
suppressPackageStartupMessages(library(ggplot2))
set.seed(20260915)
N <- 50; TT <- 30

plot_status <- function(D, file) {
  first <- apply(D, 1, function(r) if (any(r == 1)) which(r == 1)[1] else TT + 1)
  ord <- order(first, -rowSums(D), seq_len(N))      # first adopters on top, never-treated at the bottom
  df <- expand.grid(unit = seq_len(N), time = seq_len(TT))
  df$status <- factor(ifelse(D[cbind(df$unit, df$time)] == 1, "Under Treatment", "Under Control"),
                      levels = c("Under Control", "Under Treatment"))
  df$unit <- factor(df$unit, levels = rev(ord))
  p <- ggplot(df, aes(time, unit, fill = status)) +
    geom_tile(colour = "white", linewidth = 0.06) +
    scale_fill_manual(values = c("Under Control" = "#B0C4DE", "Under Treatment" = "#06266F"), name = NULL) +
    scale_x_continuous(breaks = seq_len(TT), expand = c(0, 0)) +
    scale_y_discrete(expand = c(0, 0), labels = NULL) +
    labs(x = "Time", y = "Unit") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid = element_blank(),
          axis.ticks = element_blank(), axis.text.x = element_text(size = 7),
          legend.text = element_text(size = 10), legend.key.size = unit(0.4, "cm"),
          plot.margin = margin(4, 8, 2, 4))
  ggsave(file, p, width = 6, height = 4.5)
}

# 1) block assignment: 20 units treated from period 16 on
D1 <- matrix(0, N, TT); D1[1:20, 16:TT] <- 1
# 2) staggered adoption, no reversal: 30 adopters with dates spread over 11..26
D2 <- matrix(0, N, TT); g <- sort(sample(11:26, 30, replace = TRUE))
for (i in seq_along(g)) D2[i, g[i]:TT] <- 1
# 3) general case: treatment switches on and off (Markov spells)
D3 <- matrix(0, N, TT)
for (i in seq_len(N)) { s <- 0
  for (t in seq_len(TT)) { s <- if (s == 0) rbinom(1, 1, 0.06) else 1 - rbinom(1, 1, 0.22); D3[i, t] <- s } }

plot_status(D1, "setting_block.pdf")
plot_status(D2, "setting_staggered.pdf")
plot_status(D3, "setting_general.pdf")
cat(sprintf("treated units: block %d, staggered %d, general %d\n",
            sum(rowSums(D1) > 0), sum(rowSums(D2) > 0), sum(rowSums(D3) > 0)))
