---
title: Internals
weight: 90
# Excluded from the published site. This chapter aggregates source-research notes
# and internal assessments that are not adopter-facing reference. The build keys
# drop the section landing page, and the cascade drops every aggregated child page
# (mounted from kubemoot/docs/internals), so the whole chapter is omitted from the
# rendered docs while the files remain in their repositories.
build:
  render: never
  list: never
cascade:
  - build:
      render: never
      list: never
---
Internal working notes. Not part of the published documentation.
