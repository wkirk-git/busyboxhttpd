ARG ALPINE_VERSION=3.22.1

FROM alpine:${ALPINE_VERSION} AS builder

ARG BUSYBOX_VERSION=1.37.0

# Install all dependencies required for compiling busybox
RUN apk add gcc musl-dev make perl autoconf

# Download busybox sources
RUN wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && tar xf busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && mv /busybox-${BUSYBOX_VERSION} /busybox

WORKDIR /busybox

# Copy the busybox build config (limited to httpd)
COPY .config .

# Compile
RUN make && ./make_single_applets.sh

# Create a non-root user to own the files and run our server
RUN adduser -D static

# Switch to the scratch image
FROM scratch

EXPOSE 3000

# Copy over the user
COPY --from=builder /etc/passwd /etc/passwd

# Copy the static binary
COPY --from=builder /busybox/busybox_HTTPD /busybox-httpd

# Use our non-root user
USER static
WORKDIR /home/static

# Uploads a blank default httpd.conf
# This is only needed in order to set the `-c` argument in this base file
# and save the developer the need to override the CMD line in case they ever
# want to use a httpd.conf
COPY httpd.conf index.html favicon.ico .
# Copy the static website
# Use the .dockerignore file to control what ends up inside the image!
# NOTE: Commented out since this will also copy the .config file
# COPY . .

# Run busybox httpd
CMD ["/busybox-httpd", "-f", "-v", "-p", "3000", "-c", "httpd.conf"]
