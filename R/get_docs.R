library(tidyverse)
library(tidytext)

data = read_csv("data/clean_posts.csv")

data %>% filter(type == "Science") %>% 
  write_csv("data/Clean/Science.csv")

data %>% filter(type == "Jane Austen") %>% 
  write_csv("data/Clean/Austen.csv")

data %>% filter(type == "Ed Sheeran") %>% 
  write_csv("data/Clean/Sheeran.csv")
