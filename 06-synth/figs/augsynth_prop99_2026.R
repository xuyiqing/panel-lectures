# Proposition 99 with the augsynth package (Ben-Michael, Feller, and Rothstein 2021): the gap
# between California and its synthetic control under plain SCM, ridge-augmented SCM, and
# ridge-augmented SCM with covariates. Data: the smoking panel shipped with tidysynth (Abadie,
# Diamond, and Hainmueller 2010). Output: augsynth_prop99_2026.pdf.
# Run from this folder:  Rscript augsynth_prop99_2026.R
suppressPackageStartupMessages({library(augsynth); library(dplyr); library(ggplot2)})

data(smoking, package = "tidysynth")
d <- smoking |> mutate(treated = as.integer(state == "California" & year >= 1989)) |> as.data.frame()
fits <- list(
  "Synthetic control" = augsynth(cigsale ~ treated, unit = state, time = year, data = d,
                                 progfunc = "None", scm = TRUE),
  "Ridge-augmented" = augsynth(cigsale ~ treated, unit = state, time = year, data = d,
                               progfunc = "Ridge", scm = TRUE),
  "Ridge-augmented + covariates" = augsynth(cigsale ~ treated | lnincome + beer + age15to24 + retprice,
                                            unit = state, time = year, data = d, progfunc = "Ridge", scm = TRUE,
                                            cov_agg = function(x) mean(x, na.rm = TRUE)))
res <- bind_rows(lapply(names(fits), function(nm) {
  s <- summary(fits[[nm]])
  data.frame(model = nm, s$att)
})) |> mutate(model = factor(model, levels = names(fits)))
p <- ggplot(res, aes(Time, Estimate)) +
  geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound, fill = model), alpha = 0.35) +
  geom_line(aes(colour = model), linewidth = 0.8) +
  geom_hline(yintercept = 0, colour = "grey30") + geom_vline(xintercept = 1988, linetype = "dashed") +
  facet_wrap(~ model) +
  scale_fill_manual(values = c("#e4a89b", "#8f9bb3", "#5a8f7b")) + scale_colour_manual(values = c("#b04a35", "#4a5a7a", "#2f6b52")) +
  labs(x = "Year", y = "Difference in cigarette sales per capita (packs)") +
  theme_bw(base_size = 12) + theme(legend.position = "none", strip.background = element_rect(fill = "grey92"))
ggsave("augsynth_prop99_2026.pdf", p, width = 10, height = 3.8)
for (nm in names(fits)) cat(sprintf("%-30s ATT = %.2f\n", nm, summary(fits[[nm]])$average_att$Estimate))
