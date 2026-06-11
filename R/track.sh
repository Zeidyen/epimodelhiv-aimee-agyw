#!/bin/bash
# Live progress tracker for the intervention run (R/40_intervention.R).
# Usage:  bash R/track.sh           (one snapshot)
#         bash R/track.sh -w        (watch, refresh every 30s)
cd "$(dirname "$0")/.." || exit 1
snap() {
  local total done pct
  total=$(cat results/progress_total.txt 2>/dev/null || echo "?")
  done=$(ls results/progress/*.done 2>/dev/null | wc -l | tr -d ' ')
  if [ -f results/intervention.rds ] && [ "$done" = "$total" ]; then
    echo "✅ FINISHED — $done/$total tasks. Results in results/intervention.rds + results/intervention.png"
    return 0
  fi
  if [ "$total" != "?" ] && [ "$done" -gt 0 ] 2>/dev/null; then
    pct=$(( done * 100 / total ))
  else pct=0; fi
  local cpu procs
  procs=$(ps aux | grep -E "[R].framework/Resources/bin/exec/R" | grep -v grep | wc -l | tr -d ' ')
  cpu=$(ps aux | grep -E "[R].framework/Resources/bin/exec/R" | grep -v grep | awk '{s+=$3} END{printf "%.0f", s}')
  echo "$done/$total tasks done (${pct}%)  |  $procs R procs, ${cpu}% CPU"
  return 1
}
if [ "$1" = "-w" ]; then
  while true; do printf "\r%s" "$(snap)"; snap >/dev/null && { echo; break; }; sleep 30; done
else
  snap
fi
