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
│       ├── grafana.ini       # Base test config
│       └── grafana.ini.saml.example  # SAML config template
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

## SAML Authentication

The base Grafana image supports SAML authentication through configuration. SAML works with any SAML 2.0-compliant identity provider (IdP), including:

- Azure AD / Microsoft Entra ID
- Okta
- Auth0
- OneLogin
- Google Workspace
- AWS SSO
- Keycloak
- And other SAML 2.0-compliant providers

This documentation includes detailed Azure AD Enterprise Application setup instructions as a reference example.

### Configuration Methods

You can configure SAML authentication in two ways:

#### 1. Environment Variables (Recommended)

Use `GF_AUTH_SAML_*` environment variables. This is the recommended method for containerized deployments.

**Pattern:** `GF_<SECTION>_<KEY>` where section and key are uppercase with dots/dashes replaced by underscores.

**Example:**

```bash
docker run -p 3000:3000 \
  -e GF_AUTH_SAML_ENABLED=true \
  -e GF_AUTH_SAML_CERTIFICATE_PATH=/etc/grafana/certs/certificate.cert \
  -e GF_AUTH_SAML_PRIVATE_KEY_PATH=/etc/grafana/certs/private_key.pem \
  -e GF_AUTH_SAML_IDP_METADATA_PATH=/etc/grafana/saml/metadata.xml \
  -e GF_AUTH_SAML_ASSERTION_ATTRIBUTE_NAME=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name \
  -e GF_AUTH_SAML_ASSERTION_ATTRIBUTE_LOGIN=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress \
  -e GF_AUTH_SAML_ASSERTION_ATTRIBUTE_EMAIL=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress \
  -e GF_AUTH_SAML_ASSERTION_ATTRIBUTE_GROUPS=http://schemas.microsoft.com/ws/2008/06/identity/claims/groups \
  -v $(pwd)/certs:/etc/grafana/certs \
  -v $(pwd)/saml:/etc/grafana/saml \
  ghcr.io/platformfuzz/grafana-image:latest
```

**Note:** Attribute names may vary by IdP. Adjust based on your provider's SAML assertion attributes.

**Optional Graph API settings** (for users with >150 groups, Azure AD only):

```bash
  -e GF_AUTH_SAML_CLIENT_ID=your-azure-ad-app-registration-client-id \
  -e GF_AUTH_SAML_CLIENT_SECRET=your-azure-ad-app-registration-client-secret \
  -e GF_AUTH_SAML_TOKEN_URL=https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token \
  -e GF_AUTH_SAML_FORCE_USE_GRAPH_API=true \
```

#### 2. Configuration File (Alternative)

Use `grafana.ini` with `[auth.saml]` section. See `test/grafana/grafana.ini.saml.example` for a complete template.

```bash
docker run -p 3000:3000 \
  -v $(pwd)/grafana.ini:/etc/grafana/grafana.ini \
  -v $(pwd)/certs:/etc/grafana/certs \
  -v $(pwd)/saml:/etc/grafana/saml \
  ghcr.io/platformfuzz/grafana-image:latest
```

**Note:** Environment variables override configuration file settings.

### Certificate Requirements

**Certificates are REQUIRED** for SAML authentication. Most identity providers require signed SAML requests for security.

#### Certificate Options

1. **Self-signed certificates** (Acceptable, commonly used)
   - Your IdP trusts the certificate because you explicitly upload it during configuration
   - Suitable for development and many production environments
   - Generate with OpenSSL:

    ```bash
    openssl req -x509 -newkey rsa:4096 \
      -keyout private_key.pem \
      -out certificate.cert \
      -days 365 -nodes
    ```

2. **CA-signed certificates** (Recommended for production)
   - Better for organizations with certificate lifecycle management requirements
   - Provides better auditability and compliance alignment
   - Use certificates from your organization's internal CA or PKI infrastructure

3. **SSL/TLS certificates**
   - Can be used if you have both certificate and private key in PEM format

4. **NOT compatible: AWS Certificate Manager (ACM)**
   - ACM doesn't provide private key access, which is required for SAML signing

#### Certificate Specifications

- Minimum 2048-bit RSA (4096-bit recommended)
- Valid for at least 1 year
- PEM format (`.pem`, `.crt`, `.cert` files)

#### Required Volume Mounts

Certificates and metadata must be mounted as volumes (required even when using environment variables):

- `/etc/grafana/certs/certificate.cert` - Grafana's SP certificate (self-signed or CA-signed)
- `/etc/grafana/certs/private_key.pem` - Grafana's SP private key
- `/etc/grafana/saml/metadata.xml` - Identity Provider metadata XML (downloaded from your IdP)

### Identity Provider Setup

The configuration steps vary by IdP. Below are detailed instructions for Azure AD Enterprise Applications as a reference example. For other providers, consult your IdP's documentation for SAML configuration.

#### Azure AD Enterprise Application (Example)

1. **Create/Configure Enterprise Application in Azure Portal:**
   - Navigate to Azure Active Directory > Enterprise Applications
   - Create a new application or use an existing one
   - Select "SAML-based sign-on" or "Single sign-on"

2. **Configure SAML SSO Endpoints:**
   - **Identifier (Entity ID):** `https://<your-grafana-url>/saml/metadata`
   - **Reply URL (ACS):** `https://<your-grafana-url>/saml/acs`
   - **Sign on URL:** `https://<your-grafana-url>`
   - **Logout URL:** `https://<your-grafana-url>/saml/slo`

3. **Download Federation Metadata XML:**
   - In the Enterprise Application, go to "SAML Signing Certificate" section
   - Download the "Federation Metadata XML"
   - Save this file and mount it as `/etc/grafana/saml/metadata.xml`

4. **Upload Grafana SP Certificate:**
   - In the Enterprise Application SAML configuration, upload your Grafana SP certificate
   - This is the certificate file you generated (not the private key)

#### Other Identity Providers

For other SAML providers (Okta, Auth0, OneLogin, etc.), the general steps are:

1. Configure your IdP with Grafana as a Service Provider (SP)
2. Set the Entity ID (Identifier) to: `https://<your-grafana-url>/saml/metadata`
3. Set the Reply URL (ACS URL) to: `https://<your-grafana-url>/saml/acs`
4. Set the Sign on URL to: `https://<your-grafana-url>`
5. Set the Logout URL to: `https://<your-grafana-url>/saml/slo`
6. Download the IdP metadata XML file
7. Upload your Grafana SP certificate to the IdP (if required)
8. Configure attribute mappings based on your IdP's SAML assertion attributes

### Optional: Microsoft Graph API Setup (Azure AD Only)

If your users belong to more than 150 groups, you'll need to use Microsoft Graph API for group retrieval:

1. **Create Azure AD App Registration:**
   - Navigate to Azure Active Directory > App registrations
   - Create a new app registration (separate from the Enterprise Application)
   - Note the Client ID

2. **Grant API Permissions:**
   - Add permissions: `GroupMember.Read.All` and `User.Read.All`
   - Grant admin consent

3. **Create Client Secret:**
   - Create a new client secret
   - Note the secret value (it's only shown once)

4. **Configure in Grafana:**
   - Set `GF_AUTH_SAML_CLIENT_ID` to your app registration client ID
   - Set `GF_AUTH_SAML_CLIENT_SECRET` to your client secret
   - Set `GF_AUTH_SAML_TOKEN_URL` to `https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token`
   - Set `GF_AUTH_SAML_FORCE_USE_GRAPH_API=true`

### Common Environment Variables

| Setting | Environment Variable | Description |
|---------|---------------------|-------------|
| `enabled` | `GF_AUTH_SAML_ENABLED` | Enable SAML authentication (true/false) |
| `certificate_path` | `GF_AUTH_SAML_CERTIFICATE_PATH` | Path to SP certificate |
| `private_key_path` | `GF_AUTH_SAML_PRIVATE_KEY_PATH` | Path to SP private key |
| `idp_metadata_path` | `GF_AUTH_SAML_IDP_METADATA_PATH` | Path to IdP metadata XML |
| `assertion_attribute_name` | `GF_AUTH_SAML_ASSERTION_ATTRIBUTE_NAME` | User display name attribute |
| `assertion_attribute_login` | `GF_AUTH_SAML_ASSERTION_ATTRIBUTE_LOGIN` | Login identifier attribute |
| `assertion_attribute_email` | `GF_AUTH_SAML_ASSERTION_ATTRIBUTE_EMAIL` | Email attribute |
| `assertion_attribute_groups` | `GF_AUTH_SAML_ASSERTION_ATTRIBUTE_GROUPS` | Group membership attribute |
| `client_id` | `GF_AUTH_SAML_CLIENT_ID` | Graph API app registration client ID |
| `client_secret` | `GF_AUTH_SAML_CLIENT_SECRET` | Graph API app registration client secret |
| `token_url` | `GF_AUTH_SAML_TOKEN_URL` | Graph API token endpoint |
| `force_use_graph_api` | `GF_AUTH_SAML_FORCE_USE_GRAPH_API` | Enable Graph API (true/false) |

For a complete list of SAML configuration options, see the [Grafana SAML documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-access/configure-authentication/saml/saml-configuration-options/).

## License

MIT License - see [LICENSE](LICENSE) file for details.
