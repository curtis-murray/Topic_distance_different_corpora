library(tidyverse)
library(Matrix)
library(matrixStats)
library(stringr)
library(tidytext)
library(dtplyr)
library(data.table)
# ----------------------------------------------------------------
# Loading Data
# <- read_csv("data/Cities/Topic_Model/Samples/Network/adj.csv")

# ----------------------------------------------------------------
# Functions

# ----------------------------------------------------------------

# Get the full (relative to Phoenix folder) paths of the p_w_tw (prob(word|topic))
p_w_tw_all_path <- list.files(path = "data/Samples/", pattern="p_w_tw*")
p_w_tw_all_path <- paste("data/Samples/", p_w_tw_all_path, sep = "")

words_all_all_path <- list.files(path = "data/Samples/", pattern = "words_all*")
words_all_all_path <-paste("data/Samples/", words_all_all_path, sep = "")

# Get the full vocab
# Vocab <- read_csv(words_all_all_path[str_detect(words_all_all_path, "Full")]) %>% 
# 	select(word = `0`)

Vocab_sub <- read_csv("data/clean_posts.csv") %>% 
	unnest_tokens(word, Content) %>% 
	group_by(Sub,word) %>%
	summarise(count = n()) %>% 
	mutate(freq = count/sum(count))

Vocab_full <- read_csv("data/clean_posts.csv") %>% 
  unnest_tokens(word, Content) %>% 
  group_by(word) %>%
  summarise(count = n()) %>% 
  mutate(freq = count/sum(count)) %>% 
	arrange(word) %>% 
	mutate(word_ID_full = 1:n()) %>% 
  mutate(Sub = "full")

Vocab <- Vocab_full %>% select(-word_ID_full) %>% bind_rows(Vocab_sub) %>% 
  left_join(Vocab_full %>% select(word, word_ID_full), by = "word")

write_csv(Vocab, "data/Vocab/Vocab.csv")

# Read all p_w_tw files and get adjacency word-topic matrix, join words, construct full word-topic matrix

probs <- tibble(p_w_tw_all_path = p_w_tw_all_path) %>% 
	mutate(Sub = str_extract(p_w_tw_all_path, "(?<=_)[A-Za-z]{1,}(?=.csv)"),
				 Level = str_extract(p_w_tw_all_path, "(?<=p_w_tw)\\d{1,}"),
	) %>% 
	map_at(c("Level"), as.double) %>% 
	as_tibble() %>% 
	arrange(Sub) %>% 
	mutate(
		mat = map(
			p_w_tw_all_path, 
			~read_csv(.x) %>%
				select(word_ID = X1, everything()) %>%
				mutate(word_ID = word_ID + 1) %>% 
				gather("topic", "p", -word_ID) %>% 
				mutate(topic = as.numeric(topic) + 1) %>% 
				filter(p > 0)
		)) %>% 
	ungroup()

words_all <- tibble(words_all_all_path = words_all_all_path) %>% 
	mutate(Sub = str_extract(words_all_all_path, "(?<=_)[A-Za-z]+(?=.csv)")) %>% 
	as_tibble() %>% 
	mutate(
		words = map(
			words_all_all_path,
			~read_csv(.x) %>% 
				mutate(word_ID = X1 + 1, word = `0`) %>% 
				select(word_ID, word)
		)) %>% 
	group_by(Sub) %>% 
	select(-words_all_all_path) %>% 
	ungroup() %>% 
	arrange(Sub)

# Do we want ALL the vocab in the sampled topic structures? 
# Penalty could be added after easily. Lets try that.

tidy_topics_full <- probs %>% 
	left_join(words_all, by = c("Sub")) %>% 	
	dplyr::mutate(tidy_topics = 
									map2(mat, words, ~.x %>%
											 	full_join(.y, by = "word_ID") %>%
											 	left_join(Vocab, by = "word")     # TODO: change to full if necessary
									)
	) %>% 
	select(Sub, Level, tidy_topics) %>% 
	ungroup()

tidy_topics_full %>% 
	unnest(tidy_topics) %>% 
	group_by(Sub, word_ID_full) %>% 
	arrange(Level) %>% 
	summarise(topic = paste(topic, collapse = "-")) %>% 
	write_csv("data/Tidy_Topics/tidy_topics_str.csv")
