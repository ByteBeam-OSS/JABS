# Use Debian Slim as the base image
FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt-get update && apt-get install -y \
    rsync \
    tar \
    wget \
    curl \
    sendmail \
    cron \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Copy scripts
COPY scripts /scripts

# Copy runtime symlinks for cron jobs
COPY runtime /runtime

# Create symlinks for cron
RUN ln -s /runtime/daily/* /etc/cron.daily/ && \
    ln -s /runtime/weekly/* /etc/cron.weekly/ && \
    ln -s /runtime/monthly/* /etc/cron.monthly/

# Ensure all scripts are executable
RUN chmod -R +x /scripts /runtime

# Start cron in the foreground
CMD ["cron", "-f"]
