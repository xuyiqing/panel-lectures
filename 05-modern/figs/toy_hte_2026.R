#!/usr/bin/env Rscript
# toy_hte_2026.R -- Lecture 5 "Review: What Goes Wrong under Heterogeneous Effects" and
# "...and It Compounds with Reversal and Carryover" (back in Lecture 5 since 2026-09-20 evening): three-unit toy
# trajectories (A never treated, B and C treated), observed (solid) vs. Y(0)
# (dashed, triangles). Ported from the reanalysis project's toy example (seed 123),
# with the deck palette and the red "forbidden comparison" box drawn in R.
# Run from this folder:  Rscript toy_hte_2026.R
# Outputs (5 x 5 in): toy_hte_const[_box].pdf, toy_hte_dynamic[_box].pdf,
#                     toy_general_ideal.pdf, toy_general_carryover.pdf
# Written 2026-09-20.

col.A <- "gray45"; col.B <- "#9E1B32"; col.C <- "#2F6B9A"   # ink / SlideRed / SlideBlue
n <- 15; x0 <- 1:n; e.sd <- 0.09

frame_axes <- function() {
  par(mar = c(3.6, 3.6, 1, 1), family = "sans")
  plot(1, type = "n", xlim = c(0.5, n + 0.5), ylim = c(0.5, 20), axes = FALSE, xlab = "", ylab = "")
  mtext("Time", 1, 2.3); mtext("Outcome", 2, 2.3)
  box(); axis(2, las = 1); axis(1, at = seq(1, 15, by = 2))
}
draw_unit <- function(y, y0, treated, cf.idx, cf.pts, col, lab, lab.y) {
  lines(x0, y, col = col); points(x0, y, col = col)
  if (length(treated)) points(x0[treated], y[treated], pch = 16, col = col)
  if (length(cf.idx)) { lines(x0[cf.idx], y0[cf.idx], lty = 2, col = col)
                        points(x0[cf.pts], y0[cf.pts], col = col, pch = 2) }
  text(4, lab.y, lab, col = col, font = 2)
}
redbox <- function(x1, y1, x2, y2) rect(x1, y1, x2, y2, border = "red", lwd = 2)

## ---------- staggered: B treated from 7, C from 11 ----------
t2 <- 6; t3 <- 10
d2 <- c(rep(0, t2), rep(1, n - t2)); d3 <- c(rep(0, t3), rep(1, n - t3))
dd2 <- which(d2 == 1); dd3 <- which(d3 == 1)

staggered <- function(file, te2, te3, box = FALSE) {
  set.seed(123)
  y1 <- 1 + x0 * 0.5 + rnorm(n, 0, e.sd)
  y2.0 <- 2.5 + x0 * 0.5 + rnorm(n, 0, e.sd); y2 <- y2.0 + te2
  y3.0 <- 8 + x0 * 0.5 + rnorm(n, 0, e.sd);   y3 <- y3.0 + te3
  pdf(file, height = 5, width = 5); frame_axes()
  draw_unit(y1, y1, integer(0), integer(0), integer(0), col.A, "A", 1.8)
  draw_unit(y2, y2.0, dd2, c(dd2[1] - 1, dd2), dd2, col.B, "B", 6)
  draw_unit(y3, y3.0, dd3, c(dd3[1] - 1, dd3), dd3, col.C, "C", 11)
  if (box) redbox(10.5, 9.3, 13.5, 19.2)   # periods 11-13: B's treated cells serve as C's controls
  graphics.off()
}
te2.const <- d2 * 3; te3.const <- d3 * 3
te2.dyn <- c(rep(0, t2), 1 + (1:(n - t2)) * 0.5)   # B's effect grows
te3.dyn <- c(rep(0, t3), 3 - (1:(n - t3)) * 0.2)   # C's effect fades
staggered("toy_hte_const.pdf",       te2.const, te3.const)
staggered("toy_hte_const_box.pdf",   te2.const, te3.const, box = TRUE)
staggered("toy_hte_dynamic.pdf",     te2.dyn,   te3.dyn)
staggered("toy_hte_dynamic_box.pdf", te2.dyn,   te3.dyn,   box = TRUE)

## ---------- general: B on 7-11 then off; C on at 3 and 9 ----------
general <- function(file, te2, te3, y.pars, cf2, cf2.pts, cf3, cf3.pts, lab.y, box = TRUE) {
  set.seed(123)
  d2 <- d3 <- rep(0, n); d2[7:11] <- 1; d3[c(3, 9)] <- 1
  dd2 <- which(d2 == 1); dd3 <- which(d3 == 1)
  y1 <- y.pars$a1 + x0 * y.pars$b1 + rnorm(n, 0, e.sd)
  y2.0 <- y.pars$a2 + x0 * y.pars$b2 + rnorm(n, 0, e.sd); y2 <- y2.0 + te2
  y3.0 <- y.pars$a3 + x0 * y.pars$b3 + rnorm(n, 0, e.sd); y3 <- y3.0 + te3
  pdf(file, height = 5, width = 5); frame_axes()
  draw_unit(y1, y1, integer(0), integer(0), integer(0), col.A, "A", lab.y[1])
  draw_unit(y2, y2.0, dd2, cf2, cf2.pts, col.B, "B", lab.y[2])
  draw_unit(y3, y3.0, dd3, cf3, cf3.pts, col.C, "C", lab.y[3])
  if (box) redbox(7.5, 6.3, 11.5, 19.2)   # B's treated spell, where B and C compare against each other
  graphics.off()
}
# ideal: effects switch off with the treatment
general("toy_general_ideal.pdf",
        te2 = c(rep(0, 6), rep(1, 5), rep(0, 4)) * 3,
        te3 = c(0, 0, 1, 0, 0, 0, 0, 0, 1, rep(0, 6)) * 3,
        y.pars = list(a1 = 0.8, b1 = 0.5, a2 = 3, b2 = 0.5, a3 = 8, b3 = 0.5),
        cf2 = 6:12, cf2.pts = 7:11, cf3 = c(2:4, 8:10), cf3.pts = c(3, 9),
        lab.y = c(1.8, 5.8, 9.2))
# carryover: effects build up and linger after exit
general("toy_general_carryover.pdf",
        te2 = c(rep(0, 5), 0.5, 1, 0.8, 0.6, 0.4, 0.2, rep(0, 4)) * 3,
        te3 = c(0, 0, 1, 0.5, 0, 0, 0, 0, 0.4, 0.2, 0, 0, 0, 0, 0) * 3,
        y.pars = list(a1 = 2, b1 = 0.3, a2 = 3, b2 = 0.6, a3 = 7, b3 = 0.8),
        cf2 = 5:12, cf2.pts = 6:11, cf3 = c(2:4, 8:11), cf3.pts = c(3:4, 9:10),
        lab.y = c(1.8, 6.2, 9.6))
cat("toy figures written\n")
