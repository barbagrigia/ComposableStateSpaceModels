library(tidyverse); library(gridExtra); library(ggthemes)

theme_set(theme_few())

seasonalSims = read_csv("data/SeasonalModelSims.csv", 
                       col_names = c("time", "observation", "eta", "gamma", 
                                     sapply(1:12, function(i) paste("state", i, sep = "_"))),
                       n_max = 200)

#####################
# Plot seasonal Sims #
#####################

p1 = seasonalSims %>%
  select(time, eta, observation) %>%
  gather(key, value, -time) %>%
  ggplot(aes(x = time, y = value, linetype = key)) +
  geom_line() +
  theme(legend.position = "bottom")

p2 = seasonalSims %>%
  select(time, contains("state")) %>%
  gather(key, value, -time) %>%
  ggplot(aes(x = time, y = value, colour = key)) +
  geom_line()
  # facet_wrap(~key, ncol = 1)

grid.arrange(p1, p2)

####################
# seasonal Filtered #
####################

# I think I need to add the complex conjugate to the seasonal vector, so the states are identifiable

seasonalFiltered = read_csv("data/SeasonalModelFiltered.csv", 
                           col_names = c("time", "observation", 
                                         "pred_eta", "lower_eta", "upper_eta",
                                         sapply(1:12, function(i) paste("pred_state", i, sep = "_")),
                                         sapply(1:12, function(i) c(paste("lower_state", i, sep = "_"), 
                                                                   paste("upper_state", i, sep = "_")))), skip = 1)

p1 = seasonalFiltered %>%
  select(-observation) %>%
  inner_join(seasonalSims, by = "time") %>%
  select(time, contains("eta")) %>%
  gather(key, value, -time, -upper_eta, -lower_eta) %>%
  ggplot(aes(x = time, y = value, colour = key)) +
  geom_line() +
  geom_ribbon(aes(ymin = lower_eta, ymax = upper_eta), alpha = 0.5, colour = NA)

p2 = seasonalFiltered %>%
  select(-observation) %>%
  inner_join(seasonalSims, by = "time") %>%
  select(time, contains("state_3")) %>%
  gather(key, value, -time, -contains("upper"), -contains("lower")) %>%
  ggplot(aes(x = time, y = value, colour = key)) +
  geom_line() +
  geom_ribbon(aes(ymin = lower_state_3, ymax = upper_state_3), alpha = 0.5, colour = NA) +
  theme(legend.position = "bottom")

p3 = seasonalFiltered %>%
  select(-observation) %>%
  inner_join(seasonalSims, by = "time") %>%
  select(time, contains("state_2")) %>%
  gather(key, value, -time, -contains("upper"), -contains("lower")) %>%
  ggplot(aes(x = time, y = value, colour = key)) +
  geom_line() +
  geom_ribbon(aes(ymin = lower_state_2, ymax = upper_state_2), alpha = 0.5, colour = NA) +
  theme(legend.position = "bottom")

# png("FilteringSeasonal.png")
grid.arrange(p1, p2, p3, layout_matrix = rbind(c(1, 1), c(2, 3)))
# dev.off()

###################
# Seasonal Params #
###################

params = c("v", sapply(1:12, function(i) paste0("m0", i, sep = "_")),
                sapply(1:12, function(i) paste0("c0", i, sep = "_")),
                sapply(1:12, function(i) paste0("mu", i, sep = "_")),
                sapply(1:12, function(i) paste0("sigma", i, sep = "_")))

actual_values = data_frame(params, 
                           actual_value = c(3.0, rep(0.5, 12), rep(0.12, 12),
                                            rep(0.1, 12), rep(0.5, 12)))

chain1 = read_csv("data/SeasonalModelParams-1.csv", col_names = c(params, "accepted")) %>%
  mutate(chain = 1, iteration = seq_len(n()))
chain2 = read_csv("data/SeasonalModelParams-2.csv", col_names = c(params, "accepted")) %>%
  mutate(chain = 1, iteration = seq_len(n()))

bind_rows(chain1, chain2) %>%
  plot_running_mean()

bind_rows(chain1, chain2) %>%
  traceplot()