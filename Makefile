# Panel Methods: six lecture decks.
#
#   make            the six handouts into pdf/handout/ (Xu_1panel.pdf ... Xu_6synth.pdf)
#   make 05         one deck's handout (01 .. 06)
#   make animated   the versions with the stepped reveals into pdf/animated/ (same names)
#   make 05-modern  one deck's animated version
#   make clean      remove every build/ folder and the temporary handout sources
#
# The PDFs are not tracked by git. They are published from pdf/ to
# https://yiqingxu.org/public/panel-lectures/handout/ and .../animated/.
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
LATEXMK := latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=build

# 01-panel -> panel (the tex stem) and Xu_1panel (the published name)
stem = $(word 2,$(subst -, ,$(1)))
name = Xu_$(patsubst 0%,%,$(word 1,$(subst -, ,$(1))))$(call stem,$(1))

HANDOUT  := $(foreach d,$(DECKS),pdf/handout/$(call name,$(d)).pdf)
ANIMATED := $(foreach d,$(DECKS),pdf/animated/$(call name,$(d)).pdf)

.PHONY: all animated projection clean 01 02 03 04 05 06 $(DECKS)

all: $(HANDOUT)
animated: $(ANIMATED)
projection: animated

# make 05 == make pdf/handout/Xu_5modern.pdf
01: pdf/handout/Xu_1panel.pdf
02: pdf/handout/Xu_2did.pdf
03: pdf/handout/Xu_3fdid.pdf
04: pdf/handout/Xu_4twfe.pdf
05: pdf/handout/Xu_5modern.pdf
06: pdf/handout/Xu_6synth.pdf

define DECK_RULES
pdf/handout/$(call name,$(1)).pdf: $(1)/$(call stem,$(1)).tex common/preamble.tex common/theme.tex references.bib $$(wildcard $(1)/figs/*) $$(wildcard $(1)/preamble.tex)
	@mkdir -p pdf/handout
	sed -e '/^\\documentclass/s/\]{beamer}/,handout]{beamer}/' \
	    -e 's/^\\newcommand{\\handout}{0}/\\newcommand{\\handout}{1}/' \
	    $(1)/$(call stem,$(1)).tex > $(1)/$(call stem,$(1))_handout.tex
	cd $(1) && $$(LATEXMK) $(call stem,$(1))_handout.tex
	cp $(1)/build/$(call stem,$(1))_handout.pdf $$@
	rm -f $(1)/$(call stem,$(1))_handout.tex
	@pdfinfo $$@ 2>/dev/null | awk '/^Pages/{print "$$@: " $$$$2 " pages"}' || true

# animated version (one page per overlay step): make 05-modern
$(1): pdf/animated/$(call name,$(1)).pdf
pdf/animated/$(call name,$(1)).pdf: $(1)/$(call stem,$(1)).tex common/preamble.tex common/theme.tex references.bib $$(wildcard $(1)/figs/*) $$(wildcard $(1)/preamble.tex)
	@mkdir -p pdf/animated
	cd $(1) && $$(LATEXMK) $(call stem,$(1)).tex
	cp $(1)/build/$(call stem,$(1)).pdf $$@
	@pdfinfo $$@ 2>/dev/null | awk '/^Pages/{print "$$@: " $$$$2 " pages"}' || true
endef

$(foreach d,$(DECKS),$(eval $(call DECK_RULES,$(d))))

clean:
	rm -rf $(addsuffix /build,$(DECKS))
	rm -f $(foreach d,$(DECKS),$(d)/$(call stem,$(d))_handout.tex)
