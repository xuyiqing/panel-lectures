library(ggplot2)
library(dplyr)
library(fdid)

set.seed(8052026)

one_run <- function(differential_trend = 0, n = 200) {
  treated <- rep(c(0, 1), each = n / 2)
  unit_effect <- rnorm(n)
  outcome <- sapply(1:6, function(tt) {
    unit_effect + 0.25 * tt +
      differential_trend * treated * tt +
      2 * treated * (tt >= 4) + rnorm(n)
  })
  pre <- rowMeans(outcome[, 1:3])
  post <- rowMeans(outcome[, 4:6])
  mean(post[treated == 1] - pre[treated == 1]) -
    mean(post[treated == 0] - pre[treated == 0])
}

sim <- bind_rows(
  tibble(estimate = replicate(2000, one_run(0)),
         design = "Parallel trends"),
  tibble(estimate = replicate(2000, one_run(0.20)),
         design = "Differential untreated trend")
)

p_sim <- ggplot(sim, aes(estimate, fill = design)) +
  geom_density(alpha = 0.50, linewidth = 0.6) +
  geom_vline(xintercept = 2, linetype = 2, linewidth = 0.7) +
  annotate("text", x = 2.05, y = Inf, vjust = 1.5, hjust = 0,
           label = "True effect = 2", size = 3.5) +
  scale_fill_manual(values = c("#D55E00", "#4E2A84")) +
  labs(x = "DID estimate", y = NULL, fill = NULL,
       subtitle = "2,000 replications; N = 200; six periods") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

ggsave("did_simulation_2026.pdf", p_sim, width = 8.2, height = 4.4)

d <- mortality
cutoff <- median(d$pczupu[!duplicated(d$countyid)])
famine_plot <- d |>
  mutate(social_capital = if_else(pczupu >= cutoff, "High social capital",
                                  "Low social capital")) |>
  group_by(year, social_capital) |>
  summarise(mortality = mean(mortality, na.rm = TRUE), .groups = "drop")

p_fdid <- ggplot(famine_plot,
                 aes(year, mortality, color = social_capital)) +
  annotate("rect", xmin = 1958, xmax = 1961, ymin = -Inf, ymax = Inf,
           fill = "#4E2A84", alpha = 0.10) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("#4E2A84", "#D55E00")) +
  scale_x_continuous(breaks = seq(1954, 1966, 2)) +
  labs(x = NULL, y = "Deaths per 1,000", color = NULL,
       subtitle = "Great Famine years shaded") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

ggsave("fdid_famine_2026.pdf", p_fdid, width = 8.2, height = 4.4)
