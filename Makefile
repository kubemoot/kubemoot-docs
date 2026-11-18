# Terminal recordings: VHS renders each tape in tapes/ to GIF and WebM under
# static/recordings/. Needs vhs (https://github.com/charmbracelet/vhs), ttyd and ffmpeg.
TAPES := $(wildcard tapes/*.tape)
RECORDINGS := $(filter-out tapes/settings.tape,$(TAPES))

.PHONY: recordings validate-tapes check-tools

# The pinned tool versions are in tapes/tool-versions; scripts/install-tape-tools.sh
# installs vhs and ttyd from their release tags with a checksum check.
# Records against the cluster your kubectl points at. The quickstart tape also
# needs KUBEMOOT_CHECKOUT, the path of a kubemoot checkout at the latest release.
recordings: check-tools
	@mkdir -p static/recordings
	@for t in $(RECORDINGS); do echo "vhs $$t"; vhs "$$t" || exit 1; done

# Fails when vhs, ttyd or ffmpeg differ from tapes/tool-versions.
check-tools:
	@scripts/check-tapes.sh --tools

# Checks vhs and ttyd, then parses every tape without running it.
validate-tapes:
	@scripts/check-tapes.sh --validate
