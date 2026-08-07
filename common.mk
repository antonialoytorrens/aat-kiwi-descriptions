# Shared configuration for Makefile and Makefile.docker.
# Parses settings.cfg and includes/profiles.xml so both makefiles agree on
# available distros, platforms, and profiles without duplicating the logic.

# Static configuration
include settings.cfg

# DISTROS, sourced from keys of RELEASES in settings.cfg
empty :=
space := $(empty) $(empty)
DISTROS := $(foreach r,$(RELEASES),$(word 1,$(subst :, ,$(r))))
DISTRO_ALT := $(subst $(space),|,$(DISTROS))

# Listings
PROFILES := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -E '_($(DISTRO_ALT))$$' | grep -v '^common_')
PLATFORMS := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -Ev '_($(DISTRO_ALT))$$' | grep -v '^common_' | grep -Ev '^(workstation|server)$$' | grep -Ev '^($(DISTRO_ALT))_')
