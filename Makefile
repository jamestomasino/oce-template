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
SRC_SLIDESASS_FILES != find $(SRC_DIR)/slides -name '*.scss'
DST_SLIDECSS_FILES := $(SRC_SLIDESASS_FILES:$(SRC_DIR)/slides/%.scss=$(DST_DIR)/css/slides/%.css)

# Sass source files & css transpiled files
SRC_SASS_FILES != find $(SRC_DIR)/scss/ -regex '[^_]*.scss'
SRC_SASSINCLUDE_FILES != find $(SRC_DIR)/scss/ -name '_*.scss'
DST_CSS_FILES := $(SRC_SASS_FILES:$(SRC_DIR)/scss/%.scss=$(DST_DIR)/css/%.css)

# global js
SRC_JS_FILES != find $(SRC_DIR)/js
DST_JS_FILES := $(SRC_JS_FILES:$(SRC_DIR)/js/%=$(DST_DIR)/js/%)

# global images
SRC_IMAGES_FILES != find $(SRC_DIR)/images
DST_IMAGES_FILES := $(SRC_IMAGES_FILES:$(SRC_DIR)/images/%=$(DST_DIR)/images/%)

# global fonts
SRC_FONTS_FILES != find $(SRC_DIR)/fonts -name '*.woff2'
DST_FONTS_FILES := $(SRC_FONTS_FILES:$(SRC_DIR)/fonts/%.woff2=$(DST_DIR)/fonts/%.woff2)

# Macros
copy = cp $< $@
mkdir = $(MUTE)mkdir -p $(dir $@)

help:
	$(MUTE)echo "targets:"
	$(MUTE)awk -F '#' '/^[a-zA-Z0-9_-]+:.*?#/ { print $0 }' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)#\(.*\)/  \1|-\3/p' \
	| column -t  -s '|'

build: $(NODE_MODULES) $(DST_JS_FILES) $(DST_CSS_FILES) $(DST_SLIDEHTML_FILES) $(DST_SLIDEJPG_FILES) $(DST_SLIDEPDF_FILES) $(DST_FONTS_FILES) $(DST_IMAGES_FILES) $(DST_SLIDEJS_FILES) $(DST_JS_FILES) $(DST_SLIDECSS_FILES) ## Build all files to output folder

package: $(current_dir).zip ## Prepare zip package for OCE upload

serve: build ## Watch project for file changes and rebuild with local server
	$(MUTE)rm -f index.html
	$(MUTE)touch index.html
	$(MUTE)for slide in $(DST_DIR)/*.html; do \
		n=$${slide#$(DST_DIR)/}; \
		n=$${n%.html}; \
		printf "<a href=\"%s\">%s</a><br>\\n" "$$slide" "$$n" >> index.html; \
	done
	$(MUTE)bash -c "trap 'kill %1; rm -f index.html' EXIT; python3 -m http.server $(PORT) & ag -p .gitignore -l | entr make build"

clean: ## Clean project
	rm -rf $(DST_DIR)

.PHONY: help build package serve clean

#
# -------------------------------------------------------------
#

$(DST_DIR)/%.html: $(SRC_DIR)/slides/%.html $(SRC_DIR)/includes/**/*
	$(mkdir)
	m4 --prefix-builtins $(SRC_DIR)/macros $< > $@

$(DST_DIR)/js/slides/%.js: $(SRC_DIR)/slides/%.js $(SRC_DIR)/includes/**/*
	$(mkdir)
	m4 --prefix-builtins $(SRC_DIR)/macros $< > $@

$(DST_DIR)/js/%.js: $(SRC_DIR)/js/%.js $(SRC_DIR)/includes/**/*
	$(mkdir)
	m4 --prefix-builtins $(SRC_DIR)/macros $< > $@

$(DST_DIR)/%.jpg: $(SRC_DIR)/slides/%.jpg
	$(mkdir)
	$(imagemin) --plugin.mozjpeg.quality=60 $< > $@

$(DST_DIR)/%.pdf: $(SRC_DIR)/slides/%.pdf
	$(mkdir)
	$(copy)

$(DST_DIR)/css/slides/%.css: $(SRC_DIR)/slides/%.scss
	$(mkdir)
	$(sass) --style=compressed $< $@

$(DST_DIR)/css/%.css: $(SRC_DIR)/scss/%.scss $(SRC_SASSINCLUDE_FILES)
	$(mkdir)
	$(sass) --style=compressed $< $@

$(DST_DIR)/fonts/%.woff2: $(SRC_DIR)/fonts/%.woff2
	$(mkdir)
	$(copy)

$(DST_DIR)/images/%: $(SRC_DIR)/images/%
	$(mkdir)
	$(imagemin) --plugin.pngquant.quality={0.1,0.2} --plugin.mozjpeg.quality=60 $< > $@

$(current_dir).zip: build
	cd $(DST_DIR) && zip -9 -r "$(current_dir).zip" *.html *.jpg css/ images/ js/ fonts/

$(NODE_MODULES): package.json yarn.lock
	yarn install --modules-folder ./$(NODE_MODULES)
	touch $(NODE_MODULES) # fixes watch bug if you manually ran yarn
