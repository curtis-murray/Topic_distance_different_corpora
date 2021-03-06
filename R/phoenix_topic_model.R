library(lubridate)
library(tidyverse)
library(tidytext)
library(topicmodels)
library(highcharter)
library(htmltools)
library(htmlwidgets)

max_docs <- 4000

paths <- list.files(path = "data/Scrape/", pattern="*.csv")
#paths <- list.files(path = "data/Scrape/", pattern="*.csv")

for(path in paths){
  
  sub = path %>% str_remove("data/Scrape/") %>% str_remove(".csv")
  Posts <- tibble(path = path) %>% 
    mutate(Sub = str_replace(path, ".csv", "")) %>% 
    mutate(path = paste("data/Scrape/", path, sep = "")) %>% 
    #mutate(path = paste("data/Scrape/", path, sep = "")) %>% 
    group_by(Sub) %>% 
    mutate(posts = map("data", ~read_csv(path) %>% select(`Post ID`, Title, `Publish Date`, Content) %>% 
                         mutate(`Publish Date` = as_date(`Publish Date`)))) %>% 
    unnest() %>% 
    ungroup()
  
  more_stop_words <- c("im", "didnt", "shouldnt", "cant", "wont", "amp",
                       "https", "http", "x200b", "www.reddit.com",
                       "utm_name", "ios_app", "utm_medium")
  
  clean_posts <- Posts %>% 
    group_by_all() %>% 
    summarise() %>% 
    ungroup() %>% 
    filter(!is.na(Content)) %>% 
    mutate(Content = str_replace_all(Content, "’", "'")) %>%
    mutate(Content = str_replace_all(Content, "\\.\\.\\.", " ")) %>% 
    mutate(Content = str_replace_all(Content, "[^a-z ]", "")) %>% 
    filter(!is.na(Content)) %>% 
    select(Sub,Post_ID = `Post ID`, Title, Date = `Publish Date`, Content) %>% 
    as_tibble() %>% 
    group_by_all() %>% 
    summarise() %>% 
    ungroup() %>% 
    unnest_tokens(word, Content) %>% 
    anti_join(stop_words) %>% 
    filter(!(word %in% more_stop_words)) %>% 
    group_by(word) %>% 
    mutate(count = n()) %>% 
    filter(n() >= 5) %>% 
    ungroup() %>% 
    group_by(Post_ID) %>% 
    filter(n() >= 10) %>%
    #group_by(Sub, Post_ID, Title, Author, Date, Flair) %>% 
    group_by(Sub, Post_ID, Title, Date) %>% 
    summarise(Content = paste(word, collapse = " ")) %>% 
    ungroup() %>% 
    group_by(Sub, Post_ID, Title, Date, Content) %>% 
    summarise() %>% 
    ungroup() 
  
  write_csv(clean_posts, paste("data/Clean/",sub, ".csv",sep = ""))
}

