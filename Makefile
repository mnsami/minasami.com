JEKYLL_CMD ?= bundle exec jekyll
PROJECT = "Mina Nabil Sami personal-blog"

all: install clean build lint run

test: install clean build lint

install:
	@echo "\n==> Installing gems, jekyll-plugins ..."
	gem install jekyll bundler
	bundle install

build:
	@echo "\n==> Building ${PROJECT} site ..."
	$(JEKYLL_CMD) b

lint:
	@echo "\n==> Linting: running html-proofer ..."
	bundle exec htmlproofer ./_site --disable-external --check-opengraph --check-html --url-ignore "#"

clean:
	@echo "\n==> Clean all ..."
	$(JEKYLL_CMD) clean

serve:
	@echo "\n==> Serving ${PROJECT} website ..."
	$(JEKYLL_CMD) s

dev-serve:
	@echo "\n==> Serving ${PROJECT} website in draft mode ..."
	$(JEKYLL_CMD) s --drafts

run: clean build serve

dev: clean build dev-serve

rsync:
	@echo "\n===> Sync to prod ..."
	scp -r ./_site/* root@admcgroup:/mnt/vdb/medigroupnl/.


.PHONY: build clean lint all rsync test install run serve
