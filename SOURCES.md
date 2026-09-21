# Sources: figures, data, and scripts

What every figure in the six decks is and where it comes from. Own figures and figures the
R scripts in each deck's `figs/` regenerate are covered by the repository's CC BY 4.0
license. Third-party material listed in Section 2 is excluded from that license and remains
under its owners' terms. `python3 scripts/check_figures.py` lists every referenced figure and
any unreferenced file.

## 1. Regenerated from data or redrawn (September 2026)

Figures that used to be crops of other people's work and are now produced by a script in the
deck's `figs/` folder, from public data or by simulation. Every one is credited on its frame.

| Deck | Figure(s) | Script | What it does |
|---|---|---|---|
| 1 | `svp_heterogeneity_2026.pdf` | `svp_heterogeneity_2026.R` | Effect of representative democracy on the naturalization rate by the municipality's SVP vote share: two-way fixed effects with a linear interaction and quartile bins, on Hainmueller and Hangartner's Swiss data (`swissnat.dta`). Replaces a figure taken from Hainmueller and Hangartner (2019). |
| 2 | `ck_wages_before_2026.pdf`, `ck_wages_after_2026.pdf`, `ck_map_2026.pdf` | `card_krueger_2026.R` | Starting-wage distributions in New Jersey and Pennsylvania in February and November 1992 from the Card and Krueger store data (`CK1994_longformat.dta`), and a county map of the comparison (`maps` package). Replace the wage histograms of Card and Krueger (1994), Figure 1, and the restaurant map of Card and Krueger (2000). |
| 2 | `mariel_map_2026.pdf` | `mariel_map_2026.R` | Cuba-to-Miami map (`maps` package). Replaces a Google Maps screenshot; the unsourced boatlift photograph that stood next to it was dropped. |
| 4 | `gb_threegroups_2026.pdf`, `gb_four2x2_2026.pdf` | `goodman_bacon_2026.R` | The three-group timing schematic and the four 2x2 comparisons, redrawn after Goodman-Bacon (2021), Figures 1 and 2, from simulated paths. |
| 4 | `gb_divorce_es_2026.pdf`, `gb_weights_2026.pdf` | `goodman_bacon_2026.R` | Own replication of the unilateral-divorce example: event study, TWFE estimate, and the Bacon decomposition, on the Stevenson and Wolfers (2006) data shipped with the `bacondecomp` R package. Our TWFE estimate is -3.05 against the published -3.08. |
| 6 | `augsynth_prop99_2026.pdf` | `augsynth_prop99_2026.R` | Proposition 99 gaps under synthetic control, ridge-augmented synthetic control, and ridge-augmented with covariates, estimated with the `augsynth` package on the Abadie, Diamond, and Hainmueller (2010) smoking panel (`tidysynth` copy). Replaces the plot from the `augsynth` README. |
| 6 | `trop_rmse_2026.pdf` | `trop_rmse_2026.R` | Heatmap of Table 1 in Athey, Imbens, Qu, and Viviano (2026). |
| 5 | `ex3_sub_twfe.png` | reanalysis code (Chiu, Lan, Liu, and Xu 2026) | The paper's event-study specification for Example 3 replicated on its own subsample. Replaces a crop of the paper's Figure 1B. |
| 1, 2, 5 | every other `*_2026.pdf` | `update_panel_examples_2026.R`, `update_simulations_2026.R`, `three_settings_2026.R`, `toy_hte_2026.R` | Own simulations and applications, regenerated in 2026. |

Typed in LaTeX instead of a scan (numbers are facts; the layout was the publisher's): Gruber
(1994) Table 3 on the two triple-difference frames of deck 2; Card and Krueger (1994) Table 3,
rows 1 to 3; Hong (2013) Tables 1 and 8.

## 2. Third-party material still included

| Deck | File(s) | What it is | Credit on the frame | Status |
|---|---|---|---|---|
| 2 | `PreTrend.pdf` | Card and Krueger (2000), Figure 2: employment in eating and drinking places from BLS ES-202 data, New Jersey and Pennsylvania counties | source line | Kept with attribution; the underlying series is not public. |
| 2 | `Ken.pdf` | Scheve and Stasavage (2010), Figure 1: top marginal income tax rates in World War I participants and non-participants | source line | Kept with attribution; replication data not retrieved. |
| 3 | `c_ex_fouka.pdf`, `c_ex_aer.pdf`, `c_ex_ajps.pdf`, `c_ex_jop.pdf` | Title-page crops (title, authors, abstract) of Fouka (2019), Squicciarini (2020), Chen, Wang, and Zhang (2025), and de Kadt and Larreguy (2018), on the three "More Examples" frames | source line on each frame | Kept with attribution. |
| 6 | `sdid1.png`, `sdid2.png`, `sdid3.png`, `sdid4.png` | Schematics and the three-panel California figure from the authors' slides for Arkhangelsky, Athey, Hirshberg, Imbens, and Wager (2021) | source line on each of the four SDID frames | Kept with attribution. |
| 6 | `benin_smp.png`, `benin_data1.png`, `benin_data2.png`, `benin_2009.png`, `benin_2014.png` | Luke Sanford's Benin land-titling example (working paper, 2019); `benin_data1.png` and `benin_data2.png` carry Google and DigitalGlobe imagery credits | frame cites Sanford (2019) | Used with the author's permission. |

Two decks note on their References frame that parts of the lecture build on teaching slides
by Jens Hainmueller (decks 1 and 2).

## 3. Own figures, by family

- **Deck 1:** Stata output on the Swiss naturalization panel (`S1`, `S1a`, `S3` to `S6`, `S5b`,
  `POLS`, `T1a` to `T1aaaa`, `FDL`, `FDL2`, `FDL2a`); `autor3.pdf` (own leads-and-lags plot);
  `alter_twfe_ldv.pdf`; `journal.pdf`; `seq0` to `seq2`; `edr_rawdata.pdf`, `ex_HH2015_treat.pdf`
  (`panelView`).
- **Deck 2:** `KCfalsification1` to `4` (own drawings); `ex_guncontrol`, `ex_trade`, `ex_demoGDP`,
  `ex_ajkkm` (own event-study reanalyses, shared with deck 4).
- **Deck 3:** figures from Cao, Xu, and Zhang (2022) and the `fdid` package (`raw`, `fig5`,
  `hist`, `est_any`, `dyn_*`, `c_map_*`, `c_cxz_table`) and the schematic `c_canonical_*`,
  `c_factorial_did`, `c_setup_grids`, `c_multiperiod`.
- **Deck 4:** `sim_treat_*` (`panelView` simulations), `wordle.png` and `dag_clean.png` (own
  drawings), `fig3_est_all.pdf` (Chiu, Lan, Liu, and Xu 2026, Figure 3).
- **Deck 5:** the reanalysis figures with Chiu, Lan, and Liu (`bischof_*`, `gs2020_*`,
  `grumbach_compare`, `ex2_*`, `ex3_*`, `distelhorst_carryover`, `hallyoder_honest`,
  `caughey_honest`, `est_ratio2`, `est_staggered_coef`, `pvalues_*`), `hte_taxonomy`,
  `journal2`, and the `setting_*` and `toy_*` drawings.
- **Deck 6:** `ca1` to `ca8` (own `Synth` output on the Abadie, Diamond, and Hainmueller 2010
  data), `scm_intuition1` to `6` (own drawings), `sim_*`, `toy_*`, `edr_*`, `xu2017_*`,
  `ex_Xu2017_*` (Xu 2017), `state_capacity.png` (`panelView`).

## 4. Data and scripts in the repository

| File | Origin | Used by |
|---|---|---|
| `01-panel/figs/Swiss_Panel_long.dta`, `swissnat.dta` | Hainmueller and Hangartner's naturalization data as distributed in Jens Hainmueller's course materials, re-saved with `haven` (the Stata headers carry no path) | `update_panel_examples_2026.R`, `svp_heterogeneity_2026.R` |
| `02-did/figs/CK1994_longformat.dta` | Card and Krueger (1994) public store data, from the same course materials, re-saved with `haven` | `card_krueger_2026.R`, `did_card_krueger.R` |
| traffic-fatality panel, divorce panel, smoking panel | loaded from the `AER`, `bacondecomp`, and `tidysynth` R packages; no file in the repository | deck 1, 4, and 6 scripts |

## 5. Left out of the repository on purpose

Exports of other talks, backup folders, figures no deck uses, the Stata demonstration scripts
and the data only they read, and two legacy R scripts from 2012 to 2014.
