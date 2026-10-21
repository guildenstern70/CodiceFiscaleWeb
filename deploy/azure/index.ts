import * as pulumi from "@pulumi/pulumi";
import * as resources from "@pulumi/azure-native/resources";
import * as containerregistry from "@pulumi/azure-native/containerregistry";
import * as containerinstance from "@pulumi/azure-native/containerinstance";
import * as random from "@pulumi/random";
import * as command from "@pulumi/command";
import * as path from "path";
import * as fs from "fs";
import * as crypto from "crypto";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const config = new pulumi.Config();
const azConfig = new pulumi.Config("azure-native");

// Resource group name requested by user
const resourceGroupName = config.get("resourceGroupName") || "Elixir-FiscalCode-Resouce";
const location = azConfig.get("location") || config.get("location") || "westeurope";

// Image settings
const imageRepository = config.get("repository") || "codice-fiscale-web";
const imageTag = config.get("imageTag") || "latest";

// Deployment mode: whether Pulumi automatically builds and pushes the image with Podman
const autoBuildAndPush = config.getBoolean("autoBuildAndPush") ?? true;

// Find project root directory containing Dockerfile and mix.exs
function findProjectRoot(startDir: string): string {
    let current = path.resolve(startDir);
    while (current !== path.dirname(current)) {
        if (fs.existsSync(path.join(current, "Dockerfile")) && fs.existsSync(path.join(current, "mix.exs"))) {
            return current;
        }
        current = path.dirname(current);
    }
    throw new Error(`Could not find project root containing Dockerfile and mix.exs starting from ${startDir}`);
}

const projectRootDir = findProjectRoot(__dirname);

// ---------------------------------------------------------------------------
// 1. Unique Identifiers & Secrets
// ---------------------------------------------------------------------------
// ACR names must be 5-50 alphanumeric characters (no hyphens) and globally unique.
const randomSuffix = new random.RandomString("unique-suffix", {
    length: 6,
    special: false,
    upper: false,
});

const defaultAcrName = pulumi.interpolate`elixirfisc${randomSuffix.result}acr`;
const registryName = config.get("registryName") || defaultAcrName;

// DNS name label for public FQDN (alphanumeric and hyphens, globally unique per Azure region)
const configuredDnsPrefix = config.get("dnsPrefix");
const dnsNameLabel = configuredDnsPrefix
    ? pulumi.interpolate`${configuredDnsPrefix}`
    : pulumi.interpolate`elixir-fiscal-code-${randomSuffix.result}`;

// Generate or read Phoenix SECRET_KEY_BASE (min 64 chars)
const secretKeyBaseConfig = config.getSecret("secretKeyBase");
const generatedSecretKey = new random.RandomPassword("phxSecretKeyBase", {
    length: 64,
    special: false,
}, { additionalSecretOutputs: ["result"] });
const secretKeyBase = secretKeyBaseConfig || generatedSecretKey.result;

// ---------------------------------------------------------------------------
// 2. Azure Resource Group
// ---------------------------------------------------------------------------
const resourceGroup = new resources.ResourceGroup("resourceGroup", {
    resourceGroupName: resourceGroupName,
    location: location,
    tags: {
        ManagedBy: "Pulumi",
        Application: "CodiceFiscaleWeb",
        Environment: pulumi.getStack(),
    },
});

// ---------------------------------------------------------------------------
// 3. Azure Container Registry (ACR)
// ---------------------------------------------------------------------------
const registry = new containerregistry.Registry("acr", {
    resourceGroupName: resourceGroup.name,
    registryName: registryName,
    location: resourceGroup.location,
    sku: {
        name: "Basic",
    },
    adminUserEnabled: true,
    tags: {
        ManagedBy: "Pulumi",
        Application: "CodiceFiscaleWeb",
    },
});

// Retrieve ACR admin credentials to push images and configure ACI pull secret
const acrCredentials = containerregistry.listRegistryCredentialsOutput({
    resourceGroupName: resourceGroup.name,
    registryName: registry.name,
});

const adminCredentials = acrCredentials.apply(creds => {
    const username = creds.username;
    if (!username) {
        throw new Error("Unable to retrieve ACR admin username.");
    }
    const passwords = creds.passwords;
    if (!passwords || passwords.length === 0 || !passwords[0].value) {
        throw new Error("Unable to retrieve ACR admin password.");
    }
    return {
        username: username,
        password: passwords[0].value,
    };
});

const adminUsername = adminCredentials.username;
const adminPassword = adminCredentials.password;

// Target image full tag in ACR
const targetImageUri = pulumi.interpolate`${registry.loginServer}/${imageRepository}:${imageTag}`;

// Expected public FQDN for Azure Container Instance: <dnsNameLabel>.<location>.azurecontainer.io
const aciFqdn = pulumi.interpolate`${dnsNameLabel}.${resourceGroup.location}.azurecontainer.io`;
const phxHost = config.get("phxHost") || aciFqdn;

// ---------------------------------------------------------------------------
// 4. Podman Image Build & Push to ACR
// ---------------------------------------------------------------------------
let buildAndPushCommand: command.local.Command | undefined;

const buildInputsHash = crypto
    .createHash("sha256")
    .update(fs.readFileSync(path.join(projectRootDir, "Dockerfile")))
    .update(fs.readFileSync(path.join(projectRootDir, "config", "prod.exs")))
    .update(fs.readFileSync(path.join(projectRootDir, "config", "runtime.exs")))
    .digest("hex");

if (autoBuildAndPush) {
    buildAndPushCommand = new command.local.Command("podman-build-and-push", {
        triggers: [buildInputsHash],
        create: pulumi.all([targetImageUri, registry.loginServer, adminUsername, adminPassword, phxHost]).apply(
            ([imageUri, loginServer, user, pass, host]) => `
                set -e
                echo "==> [Step 1/3] Building Podman image with linux/amd64 and PHX_HOST=${host}..."
                podman build \
                    --platform linux/amd64 \
                    -t "${imageUri}" \
                    --build-arg PHX_HOST="${host}" \
                    -f "${projectRootDir}/Dockerfile" \
                    "${projectRootDir}"

                echo "==> [Step 2/3] Logging in to Azure Container Registry (${loginServer})..."
                echo "${pass}" | podman login "${loginServer}" -u "${user}" --password-stdin

                echo "==> [Step 3/3] Uploading container image to ACR (${imageUri})..."
                podman push "${imageUri}"

                echo "==> Image successfully uploaded to ACR!"
            `
        ),
        environment: {
            PODMAN_IGNORE_CGROUPSV1_WARNING: "true",
        },
    }, {
        dependsOn: [registry],
    });
}

// ---------------------------------------------------------------------------
// 5. Azure Container Instance (ACI)
// ---------------------------------------------------------------------------
// Requirements:
// - 1 vcpu
// - 1.5 GiB memory
// - 0 gpus
// - Pull from ACR and run Phoenix app on HTTP port 80
const containerGroup = new containerinstance.ContainerGroup("elixirFiscalCodeAci", {
    resourceGroupName: resourceGroup.name,
    containerGroupName: "elixir-fiscal-code-aci",
    location: resourceGroup.location,
    osType: "Linux",
    restartPolicy: "Always",
    ipAddress: {
        type: "Public",
        ports: [
            {
                port: 80,
                protocol: "TCP",
            },
        ],
        dnsNameLabel: dnsNameLabel,
    },
    imageRegistryCredentials: [
        {
            server: registry.loginServer,
            username: adminUsername,
            password: adminPassword,
        },
    ],
    containers: [
        {
            name: "elixir-fiscal-code",
            image: targetImageUri,
            resources: {
                requests: {
                    cpu: 1.0,           // 1 vcpu
                    memoryInGB: 1.5,     // 1.5 GiB memory
                    // 0 GPUs (gpu property omitted)
                },
            },
            ports: [
                {
                    port: 80,
                    protocol: "TCP",
                },
            ],
            environmentVariables: [
                { name: "MIX_ENV", value: "prod" },
                { name: "PHX_SERVER", value: "true" },
                { name: "PORT", value: "80" },
                { name: "PHX_HOST", value: phxHost },
                { name: "PHX_SCHEME", value: "http" },
                { name: "PHX_URL_PORT", value: "80" },
                {
                    name: "PHX_CHECK_ORIGIN",
                    value: pulumi.interpolate`//${aciFqdn},//${aciFqdn}:80,//localhost,http://${aciFqdn},https://${aciFqdn}`,
                },
                { name: "DATABASE_PATH", value: "/app/codice_web.db" },
                { name: "IMAGE_BUILD_HASH", value: buildInputsHash },
                { name: "SECRET_KEY_BASE", secureValue: secretKeyBase },
            ],
        },
    ],
    tags: {
        ManagedBy: "Pulumi",
        Application: "CodiceFiscaleWeb",
    },
}, {
    // Crucial: ensure image exists in ACR before ACI attempts to pull it,
    // and replace container group when build changes so ACI pulls the latest image and updates ports
    dependsOn: buildAndPushCommand ? [buildAndPushCommand] : [registry],
    replaceOnChanges: ["*"],
    deleteBeforeReplace: true,
});

// ---------------------------------------------------------------------------
// 6. Outputs
// ---------------------------------------------------------------------------
export const resourceGroupNameOutput = resourceGroup.name;
export const registryNameOutput = registry.name;
export const registryLoginServer = registry.loginServer;
export const containerImage = targetImageUri;
export const containerGroupName = containerGroup.name;
export const containerDnsLabel = dnsNameLabel;
export const containerFqdn = aciFqdn;
export const containerIp = containerGroup.ipAddress.apply(ip => ip?.ip);
export const applicationUrl = pulumi.interpolate`http://${aciFqdn}`;
