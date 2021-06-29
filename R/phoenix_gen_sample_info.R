library(tidyverse)

#sub_info <- 
#  list.files(path = "data/Scrape/") %>% str_remove(".csv") %>% as_tibble() %>% 
#  transmute(sub = value, sub_id = 1:n())

sub_info <- read_csv("subs") %>% colnames() %>% as_tibble() %>% 
  transmute(sub = value, sub_id = 1:n())

sub_info %>%   
  write_csv(path = "data/Subs.info/sub_info.csv")

paste("n_sub=", nrow(sub_info), sep = "") %>% 
	write(file = "n_sub")
