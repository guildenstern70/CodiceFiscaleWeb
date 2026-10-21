# Azure Deployment Guide for Codice Fiscale Web

This directory contains the Infrastructure as Code (IaC) setup using **Pulumi (TypeScript)** and **Podman** to build, publish, and deploy the **Codice Fiscale Web** Phoenix application to **Azure Container Instances (ACI)** backed by an **Azure Container Registry (ACR)**.

---

## Architecture Overview

```
                      +----------------------------------------------------+
                      | Azure Resource Group: "Elixir-FiscalCode-Resouce"  |
                      |                                                    |
[Podman Build] ---->  |   +--------------------------+                     |
                      |   | Azure Container Registry | (ACR)               |
                      |   | (Basic SKU, Admin auth)  |                     |
                      |   +------------+-------------+                     |
                      |                |                                   |
                      |                | Pulls image                       |
                      |                v                                   |
                      |   +--------------------------------------------+   |
                      |   | Azure Container Instance (ACI)             |   |
                      |   | - 1.0 vCPU, 1.5 GiB RAM, 0 GPU             |   |
                      |   | - Port: 4000 (TCP)                         |   |
                      |   | - Public FQDN & IP                         |   |
                      |   | - Phoenix LiveView with SQLite DB          |   |
                      |   +--------------------------------------------+   |
                      +----------------------------------------------------+
                                               ^
                                               | HTTP (Port 4000)
                                            Browser
```

### Resource Specifications
1. **Azure Resource Group**: Named `Elixir-FiscalCode-Resouce`.
2. **Azure Container Registry (ACR)**: Basic SKU with admin credentials enabled to push/pull container images.
3. **Podman Container Image**: Built using the project root [Dockerfile](../../Dockerfile) targeting `linux/amd64` and parameterized with `PHX_HOST`.
4. **Azure Container Instance (ACI)**:
   - **vCPU**: `1.0`
   - **Memory**: `1.5 GiB`
   - **GPU**: `0` (omitted)
   - **Port**: `4000` (Public IP + DNS label)
   - **Restart Policy**: `Always`
   - **Runtime Envs**: `MIX_ENV=prod`, `PHX_SERVER=true`, `PORT=4000`, `PHX_HOST`, `PHX_SCHEME=http`, `PHX_URL_PORT=4000`, `DATABASE_PATH=/app/codice_web.db`, `SECRET_KEY_BASE`, `PHX_CHECK_ORIGIN`.

---

## Directory Structure

```
deploy/azure/
├── DEPLOY.md             # This deployment documentation
├── Pulumi.yaml           # Pulumi project definition
├── Pulumi.dev.yaml       # Default stack configuration template
├── package.json          # Node dependencies & convenience scripts
├── tsconfig.json         # TypeScript compiler configuration
├── index.ts              # Pulumi TypeScript IaC definition
├── deploy.sh             # All-in-one automated deployment script
├── build-image.sh        # Standalone script to build the Podman image
├── push-image.sh         # Standalone script to authenticate & push to ACR
└── destroy.sh            # Teardown script to destroy all Azure resources
```

---

## Prerequisites

Before starting, ensure the following tools are installed on your machine:

1. **Azure CLI (`az`)**:
   - Check installation: `az --version`
   - Log in: `az login`
   - Verify active subscription:
     ```bash
     az account show
     ```
2. **Pulumi CLI**:
   - Check installation: `pulumi version`
   - Log in: `pulumi login` (local or Pulumi Cloud)
3. **Podman**:
   - Check installation: `podman --version`
   - **macOS Note**: Ensure the Podman machine is running:
     ```bash
     podman machine start
     ```
4. **Node.js & npm**:
   - Node 20+ and npm: `node -v && npm -v`

---

## Method 1: All-In-One Automated Deployment (Recommended)

The automated script validates prerequisites, sets up dependencies, builds the image for `linux/amd64`, provisions the Azure resources, uploads the image, and deploys the container in a single command.

### 1. Navigate to the deployment directory
```bash
cd deploy/azure
```

### 2. Run the deployment script
```bash
./deploy.sh
```
*(Or use `npm run deploy`)*

### 3. Access your application
Upon completion, the script outputs the public URL:
```text
=================================================================
 Deployment Complete!
=================================================================
Application URL:   http://elixir-fiscal-code-abc123.westeurope.azurecontainer.io:4000
Container FQDN:    elixir-fiscal-code-abc123.westeurope.azurecontainer.io
Resource Group:    Elixir-FiscalCode-Resouce
Container Group:   elixir-fiscal-code-aci
=================================================================
```

Open the `Application URL` in your web browser.

---

## Method 2: Step-by-Step Modular Workflow

If you prefer executing each step manually or want to inspect the process:

### Step 1: Install Dependencies
```bash
cd deploy/azure
npm install
npm run build
```

### Step 2: Select or Initialize Pulumi Stack
```bash
pulumi stack select dev --create
```

### Step 3: Option A - Direct Deployment with Pulumi
By default (`autoBuildAndPush: true`), `pulumi up` handles the Podman build and push automatically:
```bash
pulumi up --yes
```

### Step 3: Option B - Manual Podman Image Build & Push
If you prefer running Podman commands yourself:

1. Set `autoBuildAndPush` to false:
   ```bash
   pulumi config set elixir-fiscal-code-azure:autoBuildAndPush false
   ```

2. Provision the Resource Group and ACR:
   ```bash
   pulumi up --target "urn:pulumi:dev::elixir-fiscal-code-azure::azure-native:containerregistry:Registry::acr" --yes
   ```

3. Build the Podman container image:
   ```bash
   # Get the public FQDN configured for your stack
   ACR_SERVER="$(pulumi stack output registryLoginServer)"
   FQDN="$(pulumi stack output containerFqdn)"

   # Build targeting linux/amd64
   PHX_HOST="${FQDN}" ./build-image.sh
   ```

4. Push the image to ACR:
   ```bash
   ./push-image.sh "${ACR_SERVER}"
   ```

5. Complete the ACI deployment:
   ```bash
   pulumi up --yes
   ```

---

## Configuration Reference

You can customize the deployment settings via Pulumi config:

| Key | Description | Default | Command |
|---|---|---|---|
| `azure-native:location` | Azure region for resources | `westeurope` | `pulumi config set azure-native:location northeurope` |
| `resourceGroupName` | Name of the Azure Resource Group | `Elixir-FiscalCode-Resouce` | `pulumi config set elixir-fiscal-code-azure:resourceGroupName MyRG` |
| `dnsPrefix` | Custom DNS prefix for the container FQDN | `elixir-fiscal-code-<random>` | `pulumi config set elixir-fiscal-code-azure:dnsPrefix mycustomapp` |
| `secretKeyBase` | Phoenix Secret Key Base (secure string) | Auto-generated 64-char string | `pulumi config set --secret elixir-fiscal-code-azure:secretKeyBase <key>` |
| `imageTag` | Container image tag | `latest` | `pulumi config set elixir-fiscal-code-azure:imageTag v1.0.0` |
| `autoBuildAndPush` | Build & push via Pulumi local command | `true` | `pulumi config set elixir-fiscal-code-azure:autoBuildAndPush false` |

---

## Verification & Monitoring

### 1. Check Container Status
```bash
az container show \
  --resource-group "Elixir-FiscalCode-Resouce" \
  --name "elixir-fiscal-code-aci" \
  --output table
```

### 2. Stream Container Logs
Check application boot logs and runtime output:
```bash
az container logs \
  --resource-group "Elixir-FiscalCode-Resouce" \
  --name "elixir-fiscal-code-aci" \
  --follow
```

### 3. Health Check
```bash
curl -I http://<CONTAINER_FQDN>:4000/
```

---

## Cleanup / Destroying Resources

To avoid incurring cloud charges when you are done testing, destroy all resources:

```bash
cd deploy/azure
./destroy.sh
```
*(Or run `pulumi destroy --yes`)*

This cleanly removes:
- The Azure Container Instance (`elixir-fiscal-code-aci`)
- The Azure Container Registry and its images
- The Resource Group (`Elixir-FiscalCode-Resouce`)

---

## Troubleshooting & Tips

### 1. macOS / Apple Silicon Architecture (`exec format error`)
Azure Container Instances run on `linux/amd64` (x86_64). When building on an Apple Silicon Mac (M1/M2/M3/M4), building without specifying `--platform linux/amd64` produces an `arm64` image that fails to start on ACI.
- Both `index.ts` and `build-image.sh` automatically include `--platform linux/amd64`.

### 2. Podman Machine Connection
If you see `Error: unable to connect to Podman socket`:
```bash
podman machine start
```
Check status with `podman machine list`.

### 3. WebSocket / Phoenix LiveView Origin Mismatch
If LiveView disconnects or throws 403 Forbidden:
- Ensure `PHX_HOST` matches the container's public FQDN (e.g. `<dnsNameLabel>.<location>.azurecontainer.io`).
- In `index.ts`, `PHX_CHECK_ORIGIN` is configured with `//<fqdn>:4000` and `//<fqdn>` to allow WebSocket connections over both direct port access and reverse proxy scenarios.

### 4. Database Persistence
The application uses SQLite (`DATABASE_PATH=/app/codice_web.db`). The Docker image pre-compiles, migrates, and seeds the Italian municipalities database at build time (`mix ecto.migrate` and `mix run priv/repo/seeds.exs`), so the container starts instantly with the database fully populated.
