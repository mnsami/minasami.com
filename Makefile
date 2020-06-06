JEKYLL ?= bundle exec jekyll
PROJECT = "Mina Nabil Sami personal-blog"

all: install clean build lint run

test: install clean build lint

install:
	@echo "\n==> Installing gems, jekyll-plugins ..."
	gem install jekyll bundler
	bundle install

build:
	@echo "\n==> Building ${PROJECT} site ..."
	$(JEKYLL) b

lint:
	@echo "\n==> Linting: running html-proofer ..."
	bundle exec htmlproofer ./_site --disable-external --check-opengraph --check-html --url-ignore "#"

clean:
	@echo "\n==> Clean all ..."
	$(JEKYLL) clean

run:
	@echo "\n==> Serving ${PROJECT} website ..."
	$(JEKYLL) s

rsync:
	@echo "\n===> Sync to prod ..."
	scp -r ./_site/* root@admcgroup:/mnt/vdb/medigroupnl/.


.PHONY: build clean lint all rsync test install run
