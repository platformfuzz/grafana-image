# grafana-image

![CI](https://github.com/platformfuzz/grafana-image/actions/workflows/ci.yml/badge.svg)
![Build and Release](https://github.com/platformfuzz/grafana-image/actions/workflows/build-and-release.yml/badge.svg)

Build and serve Grafana in Docker images.

## Overview

This repository contains Docker images based on the official Grafana image. The images are automatically built and published to GitHub Container Registry (GHCR) via GitHub Actions.

## Available Images

This repository provides a Docker image for serving Grafana. Mount your configuration and dashboards via volumes.

**Package:** [ghcr.io/platformfuzz/grafana-image](https://github.com/platformfuzz/grafana-image/pkgs/container/grafana-image)

## Quick Start

The image allows you to run Grafana with your own configuration.

**Prerequisites:**

Your Grafana configuration should be mounted as volumes:

- `/etc/grafana/grafana.ini` - Grafana configuration file
- `/var/lib/grafana` - Grafana data directory (dashboards, datasources, etc.)

**Pull and run:**

```bash
docker pull ghcr.io/platformfuzz/grafana-image:latest
docker run -p 3000:3000 \
  -v $(pwd)/grafana.ini:/etc/grafana/grafana.ini \
  -v $(pwd)/grafana-data:/var/lib/grafana \
  ghcr.io/platformfuzz/grafana-image:latest
```

Then open your browser to `http://localhost:3000` to access Grafana (default credentials: admin/admin). The health check endpoint is available at `http://localhost:3000/api/health`.

## Local Testing

Since Grafana already exposes a `/api/health` endpoint, you can test the image directly:

```bash
# Build the image
docker build -t grafana-image:latest .

# Run the container with test configuration
docker run -d --name grafana-test \
  -p 3000:3000 \
  -v $(pwd)/test/grafana/grafana.ini:/etc/grafana/grafana.ini \
  grafana-image:latest

# Wait a few seconds for Grafana to start, then verify it's running
curl http://localhost:3000/api/health

# Check container logs
docker logs grafana-test

# Stop and remove the container
docker stop grafana-test
docker rm grafana-test
```

Then open your browser to `http://localhost:3000` to access Grafana (default credentials: admin/admin).

### Using the Build Script

Alternatively, use the provided build script:

```bash
# Make the script executable (if needed)
chmod +x scripts/build.sh

# Build using the script
./scripts/build.sh
```

## CI/CD

The GitHub Actions workflow builds and pushes the image to GHCR on push to main or when tags are created.

### Automated Dependency Updates

Dependabot automatically monitors and creates pull requests for:

- **Docker base image** (`grafana/grafana`) - checks weekly for security patches and updates

**Fully Automated Process:**

1. Dependabot creates PRs with commit messages following the conformance format (`chore(deps): ...`)
2. CI workflow validates the build
3. Commit message conformance check validates the PR
4. Auto-merge workflow automatically merges PRs that pass all checks
5. Merging triggers the build-and-release workflow to build and push the new image

No manual intervention required - the entire update process is automated.

## Project Structure

```plaintext
.
├── Dockerfile                 # Image definition
├── .dockerignore             # Files excluded from Docker build
├── .github/
│   ├── workflows/
│   │   └── build-and-release.yml  # CI/CD workflow
│   └── dependabot.yml        # Automated dependency updates
├── test/                     # Test configuration for local testing
│   └── grafana/
│       └── grafana.ini
├── scripts/
│   └── build.sh              # Local build script
└── README.md                 # This file
```

## Included Packages

The Docker image includes:

- Official Grafana image (latest)
- Standard Grafana installation
- Port 3000 exposed

Grafana exposes a `/api/health` endpoint that can be used for health monitoring.

## License

MIT License - see [LICENSE](LICENSE) file for details.
