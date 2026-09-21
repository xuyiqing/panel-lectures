# Map for the Mariel boatlift example: Mariel (Cuba) to Miami, drawn from the maps package.
# Run from this folder:  Rscript mariel_map_2026.R
suppressPackageStartupMessages({library(ggplot2); library(maps)})

w <- map_data("world", region = c("Cuba", "USA", "Bahamas", "Haiti", "Dominican Republic", "Jamaica",
                                  "Mexico", "Cayman Islands", "Turks and Caicos Islands"))
pts <- data.frame(place = c("Mariel", "Miami"), long = c(-82.75, -80.19), lat = c(23.02, 25.77))
p <- ggplot() +
  geom_polygon(data = w, aes(long, lat, group = group), fill = "grey88", colour = "grey55", linewidth = 0.3) +
  annotate("segment", x = -82.75, y = 23.02, xend = -80.19, yend = 25.77, colour = "grey15",
           linewidth = 0.8, arrow = arrow(length = unit(0.12, "inches"))) +
  geom_point(data = pts, aes(long, lat), size = 3, colour = "grey15") +
  geom_text(data = pts, aes(long, lat, label = place), nudge_x = c(-0.9, 1.1), nudge_y = c(-0.5, 0.35), size = 5) +
  annotate("text", x = -79.3, y = 21.6, label = "Cuba", size = 5, colour = "grey30") +
  annotate("text", x = -81.6, y = 28.6, label = "Florida", size = 5, colour = "grey30") +
  coord_quickmap(xlim = c(-88, -74), ylim = c(19.5, 30.5), expand = FALSE) +
  theme_void()
ggsave("mariel_map_2026.pdf", p, width = 5.6, height = 4.4)
cat("wrote mariel_map_2026.pdf\n")
