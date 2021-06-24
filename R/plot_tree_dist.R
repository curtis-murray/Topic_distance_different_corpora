library(tidyverse)
library(tidytext)



weighted_d <- list.files("data/Tree_Distance/", full.names = TRUE) %>% 
  as_tibble() %>% 
  select(path = value) %>% 
  mutate(data = map(
    path, ~read_csv(.x, col_names = c("Sample", "d"))
  )
  ) %>% 
  unnest(data) %>% 
  left_join(read_csv("data/Sampling_Problem/Samples.info/samples_info.csv"), by = "Sample") %>% 
  select(-path) %>% 
  arrange(Sample) %>% 
  select(Sample, Sample_prop, Weighted = d)

p <- full_join(unweighted_d, weighted_d, by = c("Sample", "Sample_prop")) %>% 
  pivot_longer(names_to = "Distance", values_to = "d", cols = c(Unweighted, Weighted)) %>% 
  ggplot() + 
  geom_point(aes(x = Sample_prop, y = d, color = Distance), alpha = 0.3, show.legend = F) + 
  geom_smooth(aes(x = Sample_prop, y = d, color = Distance), se = F) + 
  labs(y = "Distance between Topic Structures",
       x = "Sampling Proportion") + 
  theme_minimal() + 
  lims(y = c(0,3), x = c(0,1)) +
  theme(legend.position = "bottom")


p %>% ggsave(filename = "Figures/Plots/Sampling_Problem/distance.pdf", 
             device = "pdf", 
             height = 6, 
             width=8)
