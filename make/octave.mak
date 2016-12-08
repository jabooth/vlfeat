# file: octave.mak
# description: Build MEX files for GNU Octave
# author: Andrea Vedaldi

# Copyright (C) 2007-12 Andrea Vedaldi and Brian Fulkerson.
# All rights reserved.
#
# This file is part of the VLFeat library and is made available under
# the terms of the BSD license (see the COPYING file).

# Octave support is experimental. Currently, the MEX files compile
# successfully but a number of bugs and subtle MATLAB
# imcompatibilities make VLFeat not fully functional.
#
# Octave support is enabled if $(MKOCTFILE) is executable. Therefore
# setting MKOCTFILE to the empty string disables Octave support.

OCTAVE ?= octave
MKOCTFILE ?=
OCTAVE_ENABLE ?= $(strip $(shell type -P $(MKOCTFILE) 2>&1 >/dev/null && \
                   $(MKOCTFILE) -p OCTAVE_LIBS 2>&1 | \
                   grep octave))

# if expand to empty string, set to empty string for use with ifdef
ifeq ($(OCTAVE_ENABLE),)
OCTAVE_ENABLE=
endif

ifdef OCTAVE_ENABLE
all: octave-mex-all
endif

# cleaning rules are defined even if OCTAVE_ENABLE is off, so that we can clean
# up previous build products
clean: octave-mex-clean
archclean: octave-mex-archclean
distclean: octave-mex-distclean

info: octave-mex-info

OCTAVE_MEX_SUFFIX := mex
OCTAVE_MEX_BINDIR := toolbox/mex/octave/$(MEX_SUFFIX)
OCTAVE_MEX_INC    := -Itoolbox -I.
OCTAVE_MEX_CFLAGS = $(LINK_DLL_CFLAGS) $(OCTAVE_MEX_INC)
OCTAVE_MEX_LDFLAGS = $(LINK_DLL_LDFLAGS) -lm

# --------------------------------------------------------------------
#                                                                Build
# --------------------------------------------------------------------

.PHONY: octave-all octave-mex-all octave-mex-dir octave-info
.PHONY: octave-clean octave-archclean octave-distclean
no_dep_targets += octave-info
no_dep_targets += octave-clean octave-archclean octave-distclean

octave_mex_src := $(shell find $(VLDIR)/toolbox -name "*.c")
octave_mex_tgt := $(addprefix $(OCTAVE_MEX_BINDIR)/,\
                  $(notdir $(mex_src:.c=.$(OCTAVE_MEX_SUFFIX)) ) )
octave_mex_dep := $(octave_mex_tgt:.$(OCTAVE_MEX_SUFFIX)=.d)
octave_mex_obj := $(notdir $(mex_src:.c=.o))
octave_mex_dll := $(OCTAVE_MEX_BINDIR)/lib$(DLL_NAME).$(DLL_SUFFIX)

ifdef OCTAVE_ENABLE
arch_bins += $(octave_mex_tgt) $(octave_mex_dll)
comm_bins +=
deps += $(octave_mex_dep)
endif

vpath vl_%.c $(shell find $(VLDIR)/toolbox -type d)

octave-mex-all: $(octave_mex_tgt) matlab-noprefix

# generate octave-mex-dir target
$(eval $(call gendir, octave-mex, $(OCTAVE_MEX_BINDIR)))

$(OCTAVE_MEX_BINDIR)/%.d : %.c $(octave-mex-dir)
	$(call C,MKOCTFILE) \
	    $(OCTAVE_MEX_INC) -M "$(<)"
	@mv "$(notdir $(<:.c=.d))" $(OCTAVE_MEX_BINDIR)

$(octave_mex_dll) : $(dll_tgt)
	cp -v "$(<)" "$(@)"

$(OCTAVE_MEX_BINDIR)/%.$(OCTAVE_MEX_SUFFIX) %.o : %.c $(octave-mex-dir) $(octave_mex_dll)
	CFLAGS="$(STD_CFLAGS)" \
	LDFLAGS="$(STD_LDFLAGS)" \
	 $(MKOCTFILE) \
	    --mex -v \
	    --output "$(@)" \
	    $(OCTAVE_MEX_CFLAGS) "$(<)" \
	    $(OCTAVE_MEX_LDFLAGS)
	@rm -f "$(<:.c=.o)"

octave-mex-info:
	$(call echo-title,Octave support)
	$(if $(OCTAVE_ENABLE),\
	  @echo "OCTAVE support enabled (MKOCTFILE found)",\
	  @echo "OCTAVE support disabled (MKOCTFILE not found)")
	$(call dump-var,octave_mex_src)
	$(call dump-var,octave_mex_tgt)
	$(call dump-var,octave_mex_dep)
	$(call echo-var,OCTAVE)
	$(call echo-var,MKOCTFILE)
	$(call echo-var,OCTAVE_MEX_BINDIR)
	$(call echo-var,OCTAVE_MEX_CFLAGS)
	$(call echo-var,OCTAVE_MEX_LDFLAGS)
	@echo

octave-mex-clean:
	rm -f $(octave_mex_dep) $(octave_mex_obj)

octave-mex-archclean: octave-clean
	rm -f $(octave_mex_tgt)

octave-mex-distclean: octave-archclean
	rm -rf toolbox/mex/octave

# Emacs:
# Local variables:
# mode: Makefile
# End:
