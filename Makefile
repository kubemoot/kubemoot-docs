# Terminal recordings: VHS renders each tape in tapes/ to GIF and WebM under
# static/recordings/. Needs vhs (https://github.com/charmbracelet/vhs), ttyd and ffmpeg.
TAPES := $(wildcard tapes/*.tape)
RECORDINGS := $(filter-out tapes/settings.tape,$(TAPES))

.PHONY: recordings validate-tapes

# Records against the cluster your kubectl points at. The quickstart tape also
# needs KUBEMOOT_CHECKOUT, the path of a kubemoot checkout at the latest release.
recordings:
	@mkdir -p static/recordings
	@for t in $(RECORDINGS); do echo "vhs $$t"; vhs "$$t" || exit 1; done

# Parses every tape without running it, so a syntax error fails fast.
validate-tapes:
	@for t in $(RECORDINGS); do echo "validate $$t"; vhs validate "$$t" || exit 1; done
