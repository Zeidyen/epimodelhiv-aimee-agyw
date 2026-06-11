## plot_intervention.R — multiple views of the intervention result from
## results/intervention.rds: (1) % averted heatmap, (2) dose-response,
## (3) efficiency (AGYW reached per infection averted).
suppressMessages({library(ggplot2); library(gridExtra)})
d <- readRDS("results/intervention.rds"); res <- d$res
res$causal <- factor(res$causal, levels=c("conservative","central","optimistic"))
res$reachf <- factor(res$reach*100)

# (1) % infections averted heatmap
p1 <- ggplot(res, aes(causal, reachf, fill=pct_med)) +
  geom_tile(colour="white") +
  geom_text(aes(label=sprintf("%.1f%%", pct_med)), size=4) +
  scale_fill_gradient(low="#f7fcf5", high="#00441b", name="% averted") +
  labs(title="% of AGYW HIV infections averted", x="Causal fraction", y="Reach (%)") +
  theme_minimal(base_size=12)

# (2) dose-response: % averted vs reach, line per causal fraction
p2 <- ggplot(res, aes(reach*100, pct_med, colour=causal, group=causal)) +
  geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_colour_brewer(palette="Set2", name="Causal fraction") +
  labs(title="Dose-response: impact vs reach", x="Chatbot reach among AGYW (%)",
       y="% infections averted") + theme_minimal(base_size=12)

# (3) efficiency: AGYW reached per infection averted (lower = more efficient)
p3 <- ggplot(res, aes(reach*100, nnr, colour=causal, group=causal)) +
  geom_line(linewidth=1) + geom_point(size=2.5) +
  scale_colour_brewer(palette="Set2", name="Causal fraction") +
  labs(title="Efficiency: AGYW reached per infection averted",
       x="Chatbot reach among AGYW (%)", y="AGYW reached / infection averted") +
  theme_minimal(base_size=12)

g <- arrangeGrob(p1, p2, p3, ncol=3,
       top="Aimee chatbot impact on AGYW HIV (2025-2035, South Africa) - alternative views")
ggsave("results/intervention_views.png", g, width=15, height=4.5, dpi=140)
cat("Wrote results/intervention_views.png\n")
