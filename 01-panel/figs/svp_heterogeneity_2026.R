# Heterogeneous effect of switching from direct to representative democracy on the naturalization
# rate, by the municipality's SVP vote share, on Hainmueller and Hangartner's Swiss data.
# Two-way fixed effects (municipality, year) with the unemployment rate as a covariate and
# standard errors clustered by municipality: a linear interaction (line and 95% band) and
# the effect within quartiles of the SVP share (points), with the SVP distribution below.
# Output: svp_heterogeneity_2026.pdf.  Run from this folder:  Rscript svp_heterogeneity_2026.R
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest); library(ggplot2); library(patchwork)})

s <- read_dta("swissnat.dta") |>
  filter(!is.na(nat_rate_ord), !is.na(institution_dummyB), !is.na(ue_rate)) |>
  transmute(bfs = as.integer(bfs), year = as.integer(year),
            nat_rate = as.numeric(nat_rate_ord),
            repdem = 1 - as.numeric(institution_dummyB),  # institution_dummyB is 1 for direct democracy
            svp = as.numeric(svpconstzero),                # municipality SVP vote share, percent
            ue_rate = as.numeric(ue_rate)) |>
  as.data.frame()

# linear interaction
m_lin <- feols(nat_rate ~ repdem + repdem:svp + ue_rate | bfs + year, data = s, cluster = ~bfs)
b <- coef(m_lin); V <- vcov(m_lin)
grid <- data.frame(svp = seq(0, 60, by = 0.5)) |>
  mutate(effect = b[["repdem"]] + b[["repdem:svp"]] * svp,
         se = sqrt(V["repdem", "repdem"] + svp^2 * V["repdem:svp", "repdem:svp"] + 2 * svp * V["repdem", "repdem:svp"]))

# effect within quartiles of the SVP share
q <- quantile(s$svp, c(0.25, 0.5, 0.75))
s <- s |> mutate(bin = cut(svp, c(-Inf, q, Inf), labels = c("Q1", "Q2", "Q3", "Q4")))
m_bin <- feols(nat_rate ~ i(bin, repdem) + ue_rate | bfs + year, data = s, cluster = ~bfs)
ct <- as.data.frame(coeftable(m_bin)) |> tibble::rownames_to_column("term") |>
  filter(grepl("^bin::", term)) |>
  mutate(bin = sub("bin::(Q[1-4]):repdem", "\\1", term)) |>
  left_join(s |> group_by(bin) |> summarise(svp = median(svp), .groups = "drop"), by = "bin") |>
  rename(effect = Estimate, se = `Std. Error`)

top <- ggplot(grid, aes(svp, effect)) +
  geom_ribbon(aes(ymin = effect - 1.96 * se, ymax = effect + 1.96 * se), fill = "grey80") +
  geom_line(linewidth = 0.9) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_pointrange(data = ct, aes(svp, effect, ymin = effect - 1.96 * se, ymax = effect + 1.96 * se),
                  colour = "#9E1B32", size = 0.4) +
  labs(x = NULL, y = "Effect of representative democracy\non the naturalization rate (pp)") +
  theme_classic(base_size = 12) + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
bottom <- ggplot(distinct(s, bfs, svp), aes(svp)) +
  geom_histogram(binwidth = 2, fill = "grey60", colour = "white", boundary = 0) +
  geom_vline(xintercept = q, colour = "#9E1B32", linetype = "dotted") +
  coord_cartesian(xlim = c(0, 60)) +
  labs(x = "Municipality-level SVP vote share (%)", y = "Municipalities") +
  theme_classic(base_size = 12)
p <- top / bottom + plot_layout(heights = c(3, 1))
ggsave("svp_heterogeneity_2026.pdf", p, width = 7.2, height = 5.4)
cat(sprintf("linear: effect at svp = 0: %.2f (se %.2f); slope per point of SVP share: %.3f (se %.3f)\n",
            b[["repdem"]], sqrt(V["repdem", "repdem"]), b[["repdem:svp"]], sqrt(V["repdem:svp", "repdem:svp"])))
print(ct[, c("bin", "svp", "effect", "se")])
