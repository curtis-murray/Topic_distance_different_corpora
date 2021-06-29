#!/bin/bash

source n_sub

for i in $(seq 1 $n_sub)
do
	echo $(date -u) "Scraping sub $i" &
	python Python/scrape_posts.py $i &
done
