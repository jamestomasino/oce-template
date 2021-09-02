mkfile_path:=$(abspath $(lastword $(MAKEFILE_LIST)))
current_dir:=$(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

# Overridable Config
SRC_DIR ?= src
DST_DIR ?= public
NODE_MODULES ?= node_modules
PORT ?= $(shell python -c 'from random import randint; print(randint(1023, 65535));')

# Reference to node binaries without installing globally
sass := $(NODE_MODULES)/.bin/sass
imagemin := $(NODE_MODULES)/.bin/imagemin

ifeq ($(VERBOSE),1)
  MUTE :=
else
  MUTE := @
endif

# Identify main slide html & jpg files for build, PDF slides
SRC_SLIDEHTML_FILES != find $(SRC_DIR)/slides -name '*.html'
DST_SLIDEHTML_FILES := $(SRC_SLIDEHTML_FILES:$(SRC_DIR)/slides/%.html=$(DST_DIR)/%.html)
SRC_SLIDEJPG_FILES != find $(SRC_DIR)/slides -name '*.jpg'
DST_SLIDEJPG_FILES := $(SRC_SLIDEJPG_FILES:$(SRC_DIR)/slides/%.jpg=$(DST_DIR)/%.jpg)
SRC_SLIDEPDF_FILES != find $(SRC_DIR)/slides -name '*.pdf'
DST_SLIDEPDF_FILES := $(SRC_SLIDEPDF_FILES:$(SRC_DIR)/slides/%.pdf=$(DST_DIR)/%.pdf)
SRC_SLIDEJS_FILES != find $(SRC_DIR)/slides -name '*.js'
DST_SLIDEJS_FILES := $(SRC_SLIDEJS_FILES:$(SRC_DIR)/slides/%.js=$(DST_DIR)/js/slides/%.js)

# Sass source files & css transpiled files
SRC_SASS_FILES != find $(SRC_DIR)/scss/ -regex '[^_]*.scss'
DST_CSS_FILES := $(SRC_SASS_FILES:$(SRC_DIR)/scss/%.scss=$(DST_DIR)/css/%.css)

# fonts
SRC_IMAGES_FILES != find $(SRC_DIR)/images
DST_IMAGES_FILES := $(SRC_IMAGES_FILES:$(SRC_DIR)/images/%=$(DST_DIR)/images/%)

# fonts
SRC_FONTS_FILES != find $(SRC_DIR)/fonts -name '*.woff2'
DST_FONTS_FILES := $(SRC_FONTS_FILES:$(SRC_DIR)/fonts/%.woff2=$(DST_DIR)/fonts/%.woff2)

# Macros
copy = cp $< $@
mkdir = $(MUTE)mkdir -p $(dir $@)

help:
	@echo "targets:"
	@awk -F '#' '/^[a-zA-Z0-9_-]+:.*?#/ { print $0 }' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)#\(.*\)/  \1|-\3/p' \
	| column -t  -s '|'

build: $(NODE_MODULES) $(DST_JS_FILES) $(DST_CSS_FILES) $(DST_SLIDEHTML_FILES) $(DST_SLIDEJPG_FILES) $(DST_SLIDEPDF_FILES) $(DST_FONTS_FILES) $(DST_IMAGES_FILES) $(DST_SLIDEJS_FILES) ## Build all files to output folder

package: $(current_dir).zip ## Prepare zip package for OCE upload

serve: build ## Watch project for file changes and rebuild with local server
	@rm -f index.html
	@touch index.html
	@for slide in $(DST_DIR)/*.html; do \
		printf "<a href=\"%s\">%s</a><br>\\n" "$$slide" "$$slide" >> index.html; \
	done
	bash -c "trap 'kill %1; rm -f index.html' EXIT; python3 -m http.server $(PORT) & ag -p ../.gitignore -l | entr make build"

clean: ## Clean project
	rm -rf $(DST_DIR)

.PHONY: help package build clean

#
# -------------------------------------------------------------
#

$(DST_DIR)/%.html: $(SRC_DIR)/slides/%.html $(SRC_DIR)/includes/**/*
	$(mkdir)
	m4 $(SRC_DIR)/macros $< > $@

$(DST_DIR)/js/slides/%.js: $(SRC_DIR)/slides/%.js $(SRC_DIR)/includes/**/*
	$(mkdir)
	m4 $(SRC_DIR)/macros $< > $@

$(DST_DIR)/%.jpg: $(SRC_DIR)/slides/%.jpg
	$(mkdir)
	$(imagemin) $< > $@

$(DST_DIR)/%.pdf: $(SRC_DIR)/slides/%.pdf
	$(mkdir)
	cp $< $@

$(DST_DIR)/css/%.css: $(SRC_DIR)/scss/%.scss
	$(mkdir)
	$(sass) $< $@

$(DST_DIR)/fonts/%.woff2: $(SRC_DIR)/fonts/%.woff2
	$(mkdir)
	cp $< $@

$(DST_DIR)/images/%: $(SRC_DIR)/images/%
	$(mkdir)
	$(imagemin) $< > $@

$(current_dir).zip: build
	cd $(DST_DIR) && zip -9 -r "$(current_dir).zip" *.html *.jpg css/ images/ js/ fonts/

$(NODE_MODULES): package.json yarn.lock
	yarn install --modules-folder ./$(NODE_MODULES)
	touch $(NODE_MODULES) # fixes watch bug if you manually ran yarn
