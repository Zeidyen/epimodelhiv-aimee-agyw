## plot_agedisparity.R — how the age-disparate gradient develops over the burn-in.
## AGYW (15-24) vs older population (25+) prevalence over time, by transmission level.
## Data from the diagnostic runs (diagnostic.R).
suppressMessages({library(ggplot2); library(tidyr)})

d <- read.csv(text="beta,year,AGYW,Older_25plus
0.006,10,0.037,0.193
0.006,15,0.026,0.177
0.006,20,0.009,0.147
0.006,25,0.008,0.107
0.015,10,0.111,0.497
0.015,15,0.194,0.565
0.015,20,0.313,0.628
0.015,25,0.209,0.707
0.030,10,0.353,0.784
0.030,15,0.412,0.830
0.030,20,0.428,0.863
0.030,25,0.555,0.885")
long <- pivot_longer(d, c(AGYW, Older_25plus), names_to="group", values_to="prev")
long$group <- factor(long$group, levels=c("Older_25plus","AGYW"),
                     labels=c("Older women (25+)","AGYW (15-24)"))
long$beta_lab <- factor(paste0("inf.prob.act = ", long$beta))

p <- ggplot(long, aes(year, prev, colour=group)) +
  geom_line(linewidth=1) + geom_point(size=2) +
  facet_wrap(~beta_lab) +
  scale_y_continuous(labels=scales::percent) +
  scale_colour_manual(values=c("Older women (25+)"="#2c3e50","AGYW (15-24)"="#e67e22"),
                      name=NULL) +
  labs(title="Age-disparate dynamics: older women always carry far higher prevalence than AGYW",
       subtitle="The gap is the engine — AGYW acquire from the older, high-prevalence pool",
       x="Year (burn-in)", y="HIV prevalence") +
  theme_minimal(base_size=12) + theme(legend.position="top")
ggsave("results/age_disparity_trajectory.png", p, width=9, height=4.5, dpi=140)
cat("Wrote results/age_disparity_trajectory.png\n")
