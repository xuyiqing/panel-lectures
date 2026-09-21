library(foreign)
library(plm)
library(lmtest)

# Run from this folder (02-did/figs): the data file sits next to the script.

d <- read.dta("CK1994_longformat.dta",convert.factors = FALSE)

head(d[, c('ID', 'nj', 'postperiod', 'emptot')])

# DID differences in means
with(d, (mean(emptot[nj == 1 & postperiod == 1], na.rm = TRUE) - mean(emptot[nj == 1 & postperiod == 0], na.rm = TRUE)) 
      - (mean(emptot[nj == 0 & postperiod == 1], na.rm = TRUE) - mean(emptot[nj == 0 & postperiod == 0], na.rm = TRUE)))

# DID regression
ols <- lm(emptot ~ postperiod * nj, data = d)
coeftest(ols)

# with  clustered SEs
d$Dit <- d$nj * d$postperiod
d <- plm.data(d, indexes = c("ID", "postperiod"))
did.reg <- plm(emptot ~ postperiod * nj, data = d, model = "pooling")
coeftest(did.reg, vcov=function(x) vcovHC(x, cluster="group", type="HC1"))

# fixed effects
fixed.mod <- (plm(emptot ~ postperiod * nj , data = d, model = "within"))
coeftest(fixed.mod, vcov=function(x) vcovHC(x, cluster="group", type="HC1"))

# first differences
firstdiff.mod <- (plm(emptot ~ postperiod * nj, data = d, model = "fd"))
coeftest(firstdiff.mod, vcov=function(x) vcovHC(x,type="HC0"))


