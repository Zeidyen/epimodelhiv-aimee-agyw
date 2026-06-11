## plot_calib_ci.R — re-plot the calibrated baseline with CIs, expressing
## INCIDENCE as CASES (national new HIV infections/yr) not a rate.
## Model is a sample (N) so its incidence RATE is scaled to the national AGYW
## population to give national-equivalent new-infection COUNTS.
suppressMessages({library(ggplot2); library(gridExtra)})

d <- readRDS("results/calib_ci.rds"); model <- d$model; tgt <- d$tgt

# Thembisa national AGYW (women 15-24): new infections/yr + population (v5.0)
NEWINF <- c(`1990`=29833,`1991`=46678,`1992`=68610,`1993`=93825,`1994`=119612,`1995`=142967,
  `1996`=161826,`1997`=174125,`1998`=181761,`1999`=185202,`2000`=184698,`2001`=181088,
  `2002`=175658,`2003`=170249,`2004`=165619,`2005`=161192,`2006`=156413,`2007`=152040,
  `2008`=146987,`2009`=139378,`2010`=129105,`2011`=118576,`2012`=110351,`2013`=103931,
  `2014`=98259,`2015`=91878,`2016`=83732,`2017`=75078,`2018`=67852,`2019`=61239,
  `2020`=55877,`2021`=51552,`2022`=48277)
POP <- c(`1990`=3541877,`1991`=3657518,`1992`=3789017,`1993`=3914400,`1994`=4033816,`1995`=4148108,
  `1996`=4257621,`1997`=4335407,`1998`=4419180,`1999`=4507519,`2000`=4598399,`2001`=4699279,
  `2002`=4792161,`2003`=4878802,`2004`=4954925,`2005`=5015427,`2006`=5055992,`2007`=5103721,
  `2008`=5127982,`2009`=5132028,`2010`=5122390,`2011`=5094345,`2012`=5115107,`2013`=5111665,
  `2014`=5094297,`2015`=5075186,`2016`=5047850,`2017`=5021278,`2018`=4995007,`2019`=4981661,
  `2020`=4999116,`2021`=5028006,`2022`=5071746)

# ---- Prevalence panels (unchanged, %) --------------------------------------
prevpan <- model[grepl("Prevalence", model$panel),]
prevtgt <- tgt[grepl("Prevalence", tgt$panel),]
pp <- ggplot(prevpan, aes(year)) +
  geom_ribbon(aes(ymin=lo,ymax=hi), fill="#c0392b", alpha=0.2) +
  geom_line(aes(y=med), colour="#c0392b", linewidth=0.9) +
  geom_line(data=prevtgt, aes(y=val), colour="black", linewidth=1) +
  geom_point(data=prevtgt, aes(y=val), colour="black", size=1.2) +
  facet_wrap(~panel, scales="free_y") + scale_y_continuous(labels=scales::percent) +
  labs(x="Year", y="HIV prevalence") + theme_minimal(base_size=11)

# ---- Incidence panel as CASES (national new infections/yr) -----------------
inc <- model[grepl("Incidence", model$panel),]
inc$rate <- inc$med/100; inc$rate_lo <- inc$lo/100; inc$rate_hi <- inc$hi/100  # rds was *100
inc$pop <- POP[as.character(inc$year)]
inc$cases <- inc$rate*inc$pop/1000          # thousands of new infections
inc$cases_lo <- inc$rate_lo*inc$pop/1000; inc$cases_hi <- inc$rate_hi*inc$pop/1000
inc_tgt <- data.frame(year=as.integer(names(NEWINF)), cases=NEWINF/1000)

ip <- ggplot(inc, aes(year)) +
  geom_ribbon(aes(ymin=cases_lo,ymax=cases_hi), fill="#2c7fb8", alpha=0.2) +
  geom_line(aes(y=cases), colour="#2c7fb8", linewidth=0.9) +
  geom_line(data=inc_tgt, aes(y=cases), colour="black", linewidth=1) +
  geom_point(data=inc_tgt, aes(y=cases), colour="black", size=1.2) +
  labs(title="New HIV infections / yr: women 15-24 (national)",
       x="Year", y="New infections (thousands)") + theme_minimal(base_size=11)

g <- arrangeGrob(pp, ip, ncol=2, widths=c(2,1),
       top="Calibrated baseline, 95% simulation interval (N=2500, 20 sims). Black=Thembisa; coloured=model.")
ggsave("results/calib_ci.png", g, width=13, height=4.2, dpi=140)
cat("Wrote results/calib_ci.png (incidence as national cases)\n")
