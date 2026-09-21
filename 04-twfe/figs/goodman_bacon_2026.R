# Goodman-Bacon (2021) figures redrawn:
#   gb_threegroups_2026.pdf   the three-group timing schematic (simulated paths)
#   gb_four2x2_2026.pdf       the four 2x2 comparisons the TWFE estimate averages over
#   gb_divorce_es_2026.pdf    event-study and TWFE estimates, unilateral divorce laws and
#                             female suicide (Stevenson and Wolfers 2006 data, bacondecomp package)
#   gb_weights_2026.pdf       the Bacon decomposition: every 2x2 estimate against its weight
# Run from this folder:  Rscript goodman_bacon_2026.R
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(fixest); library(bacondecomp)})

## 1. Schematics ---------------------------------------------------------------------------
tt <- 1:30; k <- 10; l <- 20
sched <- data.frame(t = tt) |>
  mutate(U = 10 + 0.4 * t,
         E = 18 + 0.4 * t + ifelse(t >= k, 12 + 0.25 * (t - k), 0),   # early group, treated at k
         L = 14 + 0.4 * t + ifelse(t >= l, 12 + 0.25 * (t - l), 0))   # late group, treated at l
long <- tidyr::pivot_longer(sched, -t, names_to = "group", values_to = "y") |>
  mutate(group = factor(group, levels = c("E", "L", "U"),
                        labels = c("Early group (treated at k)", "Late group (treated at l)", "Untreated group")))
base_plot <- function(dat, dim_groups = character(0)) {
  dat <- dat |> mutate(dim = group %in% dim_groups)
  ggplot(dat, aes(t, y, group = group, colour = group, shape = group, alpha = dim)) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.6) +
    geom_vline(xintercept = c(k, l), colour = "firebrick", linewidth = 0.5) +
    scale_colour_manual(values = c("grey10", "grey40", "grey55")) +
    scale_shape_manual(values = c(17, 1, NA)) +
    scale_alpha_manual(values = c(`FALSE` = 1, `TRUE` = 0.15), guide = "none") +
    scale_x_continuous(breaks = c(k, l), labels = c("k", "l")) +
    labs(x = "Time", y = "Units of y", colour = NULL, shape = NULL) +
    theme_classic(base_size = 12) + theme(legend.position = "bottom")
}
p1 <- base_plot(long) +
  annotate("text", x = c(k / 2, (k + l) / 2, (l + 30) / 2), y = 6, label = c("PRE(k)", "MID(k, l)", "POST(l)"), size = 3.6) +
  annotate("text", x = 26, y = 45, label = "y^k", parse = TRUE, size = 4) +
  annotate("text", x = 29, y = 37, label = "y^l", parse = TRUE, size = 4) +
  annotate("text", x = 26, y = 19, label = "y^U", parse = TRUE, size = 4)
ggsave("gb_threegroups_2026.pdf", p1, width = 6.4, height = 4.4)

E <- "Early group (treated at k)"; L <- "Late group (treated at l)"; U <- "Untreated group"
panels <- list(
  list(title = "A. Early group vs. untreated group",       keep = c(E, U), win = c(1, 30)),
  list(title = "B. Late group vs. untreated group",        keep = c(L, U), win = c(1, 30)),
  list(title = "C. Early group vs. late group, before l",  keep = c(E, L), win = c(1, l - 1)),
  list(title = "D. Late group vs. early group, after k",   keep = c(E, L), win = c(k, 30)))
plots <- lapply(panels, function(pn) {
  dat <- long |> filter(t >= pn$win[1], t <= pn$win[2])
  base_plot(dat, dim_groups = setdiff(levels(long$group), pn$keep)) +
    ggtitle(pn$title) + theme(legend.position = "none", plot.title = element_text(size = 11))
})
pdf("gb_four2x2_2026.pdf", width = 8.4, height = 6.2)
gridExtra::grid.arrange(grobs = plots, ncol = 2)
dev.off()

## 2. Unilateral divorce and female suicide (Stevenson and Wolfers 2006 data) ---------------
data(divorce, package = "bacondecomp")
# sex == 2 is women; suiciderate_jag is the age-adjusted suicide rate per capita; unilateral
# flags years at or after the state's unilateral divorce law (divyear; 2000 = no law by 1996,
# 1950 = law in place before the sample starts, the "always treated" states)
dv <- divorce |>
  filter(sex == 2, year >= 1964, year <= 1996) |>
  mutate(asmrs = 1e6 * suiciderate_jag, post = as.integer(unilateral), rel = year - divyear,
         rel_b = pmin(pmax(rel, -9), 16)) |>          # bin the event-time endpoints
  filter(!is.na(asmrs))
twfe <- feols(asmrs ~ post | st + year, data = dv, cluster = ~st)
dd <- coef(twfe)[["post"]]
es <- feols(asmrs ~ i(rel_b, ref = -1) | st + year, data = filter(dv, divyear > 1964), cluster = ~st)
ct <- as.data.frame(coeftable(es)) |> tibble::rownames_to_column("term") |>
  mutate(rel = as.integer(sub("rel_b::", "", term))) |> filter(rel >= -8, rel <= 15) |>
  rename(est = Estimate, se = `Std. Error`) |> bind_rows(data.frame(rel = -1, est = 0, se = 0))
p3 <- ggplot(ct, aes(rel, est)) +
  geom_hline(yintercept = 0, colour = "grey40") +
  geom_hline(yintercept = dd, colour = "firebrick", linewidth = 0.9) +
  geom_line(aes(y = est - 1.96 * se), linetype = "dashed", colour = "grey50") +
  geom_line(aes(y = est + 1.96 * se), linetype = "dashed", colour = "grey50") +
  geom_line(linewidth = 0.9, colour = "grey20") + geom_vline(xintercept = -1, colour = "grey30") +
  annotate("text", x = -4, y = dd - 1.2, label = sprintf("TWFE estimate = %.2f (s.e. = %.2f)", dd, se(twfe)[["post"]]),
           colour = "firebrick", size = 3.6) +
  labs(x = "Years relative to divorce reform", y = "Suicides per 1m women") +
  theme_classic(base_size = 12)
ggsave("gb_divorce_es_2026.pdf", p3, width = 6.6, height = 4.4)

## 3. Bacon decomposition of the TWFE estimate ----------------------------------------------
bd <- bacon(asmrs ~ post, data = as.data.frame(dv[, c("st", "year", "asmrs", "post")]), id_var = "st", time_var = "year", quietly = TRUE)
sumry <- bd |> group_by(type) |> summarise(avg = weighted.mean(estimate, weight), wsum = sum(weight), .groups = "drop") |>
  mutate(label = sprintf("%s\nweight = %.2f; DD = %.2f", type, wsum, avg))
p4 <- ggplot(bd, aes(weight, estimate, shape = type)) +
  geom_hline(yintercept = sum(bd$weight * bd$estimate), colour = "firebrick", linewidth = 0.9) +
  geom_point(size = 2.2, colour = "grey15") +
  scale_shape_manual(values = c(4, 17, 1, 15, 3)[seq_along(unique(bd$type))], labels = sumry$label[match(sort(unique(bd$type)), sumry$type)]) +
  annotate("text", x = max(bd$weight) * 0.55, y = sum(bd$weight * bd$estimate) + 1.5,
           label = sprintf("DD estimate = %.2f", sum(bd$weight * bd$estimate)), colour = "firebrick", size = 3.6) +
  labs(x = "Weight", y = "2x2 DD estimate", shape = NULL) +
  theme_classic(base_size = 12) + theme(legend.position = "right", legend.text = element_text(size = 8))
ggsave("gb_weights_2026.pdf", p4, width = 8, height = 4.6)
cat(sprintf("TWFE DD = %.3f; Bacon-weighted sum = %.3f; types: %s\n", dd, sum(bd$weight * bd$estimate), paste(unique(bd$type), collapse = " | ")))
