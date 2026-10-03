# Build stage: compile the Hugo static site
# Docsy requires Go (Hugo modules) and Node (PostCSS/autoprefixer).
# The component docs (kubemoot/docs, etc.) are copied in by CI before
# this build context is created — see ci-docs.yaml and release-docs.yaml.
# Debian (glibc) base: the official hugo_extended linux-amd64 binary is glibc-
# linked and will not run on Alpine/musl ("hugo: not found" = missing ELF loader).
FROM golang:1.27-bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for PostCSS (Docsy dependency): the latest release of the major in
# .nvmrc, the single Node version source the workflows also read, checked against
# the release's published SHA-256 sums.
COPY .nvmrc /tmp/.nvmrc
RUN set -eu; \
    major="$(tr -d '[:space:]v' < /tmp/.nvmrc)"; \
    base="https://nodejs.org/dist/latest-v${major}.x"; \
    curl -fsSL "${base}/SHASUMS256.txt" -o /tmp/SHASUMS256.txt; \
    tarball="$(awk '/ node-v[0-9.]+-linux-x64\.tar\.gz$/ {print $2}' /tmp/SHASUMS256.txt)"; \
    test -n "${tarball}"; \
    curl -fsSL "${base}/${tarball}" -o "/tmp/${tarball}"; \
    (cd /tmp && grep " ${tarball}\$" SHASUMS256.txt | sha256sum -c -); \
    tar -xzf "/tmp/${tarball}" -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE; \
    rm -f "/tmp/${tarball}" /tmp/SHASUMS256.txt; \
    node --version; npm --version

# Install Hugo extended (required for Docsy SCSS pipeline)
ENV HUGO_VERSION=0.156.0
RUN curl -sL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    | tar -xzf - -C /usr/local/bin hugo

WORKDIR /site

# Copy dependency manifests first for layer caching
COPY go.mod go.sum package.json package-lock.json ./

# Install Node deps (PostCSS toolchain)
RUN npm ci

# Fetch Hugo module dependencies (Docsy theme)
RUN hugo mod get

# Copy the full site source (includes _docs/kubemoot from the CI sparse checkout)
COPY . .

# The default hugo.toml mount is ../kubemoot/docs (so plain `hugo server` works
# in the local umbrella). Make that path resolve in-container by placing the
# CI-checked-out component docs there.
RUN mkdir -p /kubemoot && cp -r _docs/kubemoot/docs /kubemoot/docs

# Build for the site host ROOT. Docsy serves cleanly at a host root: assets at /css
# and the docs section at /docs/<page> both resolve, with no /docs/docs/ doubling.
ARG SITE_URL=https://kubemoot.org/
RUN hugo --gc --minify --baseURL "${SITE_URL}"

# Serve stage: nginx serving the static output, fully non-root.
# nginx-unprivileged runs as uid 101 and listens on 8080, so the container needs
# neither root nor the NET_BIND_SERVICE capability (see chart securityContext).
FROM nginxinc/nginx-unprivileged:1.31-alpine

COPY --from=builder /site/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/docs/ || exit 1
