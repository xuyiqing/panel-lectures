# Panel Methods: six lecture decks.
#
#   make            build the six handout PDFs into pdf/
#   make 05         one deck's handout (01 .. 06)
#   make projection the projection versions (with overlays) into <deck>/build/
#   make clean      remove every build/ folder and the temporary handout sources
#
# Requires TeX Live 2023 or later with latexmk and biber; pdflatex is enough (no XeLaTeX).
# Handouts are built from a throwaway copy of the deck source with the beamer
# `handout` class option and \handout set to 1 (the decks branch on it for a few
# figure choices). Build artifacts go to <deck>/build/, which git ignores.

# biber on macOS can fail with a "usage: lipo" message while the Xcode license is
# unaccepted; pointing DEVELOPER_DIR at the Command Line Tools avoids it.
ifeq ($(shell uname),Darwin)
export DEVELOPER_DIR ?= /Library/Developer/CommandLineTools
endif

DECKS   := 01-panel 02-did 03-fdid 04-twfe 05-modern 06-synth
HANDOUT := $(addprefix pdf/,$(addsuffix .pdf,$(DECKS)))
LATEXMK := latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=build

# 01-panel -> panel (the tex stem is the folder name after the number)
stem = $(word 2,$(subst -, ,$(1)))

.PHONY: all projection clean 01 02 03 04 05 06 $(DECKS)

all: $(HANDOUT)

# make 05 == make pdf/05-modern.pdf
01: pdf/01-panel.pdf
02: pdf/02-did.pdf
03: pdf/03-fdid.pdf
04: pdf/04-twfe.pdf
05: pdf/05-modern.pdf
06: pdf/06-synth.pdf

define HANDOUT_RULE
pdf/$(1).pdf: $(1)/$(call stem,$(1)).tex common/preamble.tex common/theme.tex references.bib $$(wildcard $(1)/figs/*) $$(wildcard $(1)/preamble.tex)
	@mkdir -p pdf
	sed -e '/^\\documentclass/s/\]{beamer}/,handout]{beamer}/' \
	    -e 's/^\\newcommand{\\handout}{0}/\\newcommand{\\handout}{1}/' \
	    $(1)/$(call stem,$(1)).tex > $(1)/$(call stem,$(1))_handout.tex
	cd $(1) && $$(LATEXMK) $(call stem,$(1))_handout.tex
	cp $(1)/build/$(call stem,$(1))_handout.pdf $$@
	rm -f $(1)/$(call stem,$(1))_handout.tex
	@pdfinfo $$@ 2>/dev/null | awk '/^Pages/{print "$$@: " $$$$2 " pages"}' || true

# projection version: make 05-modern
$(1): $(1)/build/$(call stem,$(1)).pdf
$(1)/build/$(call stem,$(1)).pdf: $(1)/$(call stem,$(1)).tex common/preamble.tex common/theme.tex references.bib $$(wildcard $(1)/figs/*) $$(wildcard $(1)/preamble.tex)
	cd $(1) && $$(LATEXMK) $(call stem,$(1)).tex
endef

$(foreach d,$(DECKS),$(eval $(call HANDOUT_RULE,$(d))))

projection: $(foreach d,$(DECKS),$(d)/build/$(call stem,$(d)).pdf)

clean:
	rm -rf $(addsuffix /build,$(DECKS))
	rm -f $(foreach d,$(DECKS),$(d)/$(call stem,$(d))_handout.tex)
