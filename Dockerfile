FROM grafana/grafana:latest

# Set working directory
WORKDIR /usr/share/grafana

# Expose the default Grafana port
EXPOSE 3000

# Use the default Grafana entrypoint
# The official image already has the correct entrypoint configured
