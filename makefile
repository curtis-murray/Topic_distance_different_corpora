scrape_from_reddit:
	jupyter nbconvert --to=python Python/scrape_posts.ipynb
	python Python/scrape_posts.py
