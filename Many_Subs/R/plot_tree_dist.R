library(tidyverse)
library(tidytext)

weighted_d <- list.files("data/Tree_Distance", full.names = TRUE) %>% 
  as_tibble() %>% 
  select(path = value) %>% 
  mutate(data = map(
    path, ~read_csv(.x, col_names = c("Sub1", "Sub2", "d"))
  )
  ) %>% 
  unnest(data)

ids <- tibble(Sub = c(weighted_d %>% pull(Sub1), weighted_d %>% pull(Sub2)) %>% unique()) %>% 
  mutate(id = 1:n())


weighted_d %>% 
  select(-path) %>% 
  left_join(ids, by = c("Sub1"="Sub")) %>% 
  left_join(ids, by = c("Sub2"="Sub")) ->
  edge_list

D = matrix(0, nrow(ids), nrow(ids))
D[cbind(edge_list$id.x, edge_list$id.y)] = edge_list$d

D = D %>% t() + D
rownames(D) <- ids$Sub
colnames(D) <- ids$Sub

write.table(D, file="../Meeting Reports/Meeting_Book/files/heatmap")

library(superheat)

pdf(file="Figures/heatmap.pdf",width = 14, height = 11, onefile = F)
D %>% superheat(
  #heat.lim = c(-1,1),
  pretty.order.rows = T,
  pretty.order.cols = T,
  row.dendrogram = T,
  clustering.method = "hierarchical",
  #left.label.text.col = my_colouring$colour,
  left.label.col = "white",
  left.label.text.alignment = "left",
  #bottom.label.text.col = my_colouring$colour,
  bottom.label.col = "white",
  bottom.label.text.angle = 90,
  bottom.label.text.alignment = "right",
  grid.hline.col = "white",
  grid.hline.size = 0.5,
  grid.vline.col = "white",
  grid.vline.size = 0.5,
  #yt.plot.type = "bar",
  #yt = ordered_data$p,
  #yt.axis.name = "Overall Density",
  #heat.pal = c("blue", "white", "red"),
  heat.pal = c("white", "red"),
  left.label.text.size = 4,
  bottom.label.text.size = 3.4,
  yt.plot.size = 0.1
)
dev.off()
library(heatmaply)
heatmaply(D,colors = c("white", "red"), grid_gap = 1, 
          dendrogram = "both",show_dendrogram = c(T,F), 
          revC=T,main = "Distances between subreddits",
          file = "Figures/heatmap.html", dend_hoverinfo = F)

posts <- read_csv("data/clean_posts.csv") %>% 
  group_by(Sub) %>% 
  summarise(count = n()) %>%
  mutate(size = count/max(count)) %>% 
  select(sub = "Sub", size)

library(tsne)
library(umap)

data_mds <- D %>% cmdscale() %>% 
  as_tibble() %>%
  mutate(sub = rownames(D)) %>% 
  left_join(posts) 

p_mds <- data_mds %>% 
  ggplot() + 
  geom_point(aes(V1,V2,size = size),show.legend = F) + 
  ggrepel::geom_label_repel(aes(V1,V2, label = sub)) + 
  theme_void()

p_mds

p_mds %>% ggsave(filename = "Figures/p_mds.pdf",device = "pdf", width = 6, height = 4)
p_mds %>% ggsave(filename = "../Meeting Reports/Meeting_Book/files/Figures/p_mds.png",device = "png", width = 6, height = 4)

data_tsne <- D %>% tsne(perplexity = 2) %>% 
  as_tibble() %>%
  mutate(sub = rownames(D)) %>% 
  left_join(posts) 

p_tsne <- data_tsne %>% 
  ggplot() + 
  geom_point(aes(V1,V2,size = size),show.legend = F) + 
  ggrepel::geom_label_repel(aes(V1,V2, label = sub)) + 
  theme_void()

p_tsne

p_tsne %>% ggsave(filename = "Figures/p_tsne.pdf",device = "pdf", width = 6, height = 4)
p_tsne %>% ggsave(filename = "../Meeting Reports/Meeting_Book/files/Figures/p_tsne.png",device = "png", width = 6, height = 4)


custom.config = umap.defaults
custom.config$n_neighbors = 3

data_umap <-  D %>% umap(config = custom.config) %>% .$layout %>%  
  as_tibble() %>%
  mutate(sub = rownames(D)) %>% 
  left_join(posts) 

p_umap <- data_umap %>% 
  ggplot() + 
  geom_point(aes(V1,V2,size = size),show.legend = F) + 
  ggrepel::geom_label_repel(aes(V1,V2, label = sub)) + 
  theme_void() 

p_umap

p_umap %>% ggsave(filename = "Figures/p_umap.pdf",device = "pdf", width = 6, height = 4)
p_umap %>% ggsave(filename = "../Meeting Reports/Meeting_Book/files/Figures/p_umap.png",device = "png", width = 6, height = 4)
