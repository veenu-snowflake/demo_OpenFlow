# OpenFlow: Connecting SharePoint to Snowflake

## What This Does

- Syncs files from SharePoint document libraries into Snowflake
- Supports syncing to an internal Stage (for raw files) or to Cortex Search (for AI-powered search)
- Uses OAuth-based authentication via Microsoft Entra ID (Azure AD)

---

## High-Level Flow

```
SharePoint (Document Libraries)
    |
    |  Microsoft Graph API (OAuth)
    v
OpenFlow Runtime (SPCS)
    |
    |  Snowpipe Streaming / Stage Write
    v
Snowflake (Internal Stage or Cortex Search)
```

---

## Connector Variants

| Flow Name | Where Files Go | ACL Support |
|-----------|---------------|-------------|
| `unstructured-sharepoint-to-stage-no-cortex` | Internal Stage | Yes |
| `unstructured-sharepoint-to-stage-no-cortex-no-acl` | Internal Stage | No |
| `unstructured-sharepoint-cdc` | Cortex Search | Yes |
| `unstructured-sharepoint-cdc-no-acl` | Cortex Search | No |

- **ACL variants** preserve SharePoint access control metadata (who can see what)
- **No-ACL variants** are simpler if you don't need permission enforcement

---

## Key Difference from PostgreSQL: No Network Policy Needed (for Auth)

- **PostgreSQL requires a Network Rule + EAI** because it connects to a customer-managed database host on a specific port. SPCS needs explicit permission to reach that external host.
- **SharePoint uses OAuth authentication** via Microsoft's public endpoints (`login.microsoftonline.com`, `graph.microsoft.com`). The connector authenticates using a Client ID + Client Secret registered in Microsoft Entra ID.
- **However, an EAI is still required for SPCS deployments** -- not for a network policy in the traditional database sense, but because SPCS still needs permission to reach Microsoft's public domains. The difference is:
  - **Postgres:** EAI opens access to YOUR private database host (unique per customer)
  - **SharePoint:** EAI opens access to Microsoft's standard public endpoints (same for everyone)

---

## Prerequisites on the SharePoint / Microsoft Entra ID Side

### Step 1: Create an App Registration in Microsoft Entra ID

- Go to [Microsoft Entra Admin Center](https://entra.microsoft.com)
- Navigate to **App registrations** > **New registration**
- Give it a name (e.g., `Snowflake-OpenFlow-SharePoint`)
- Set supported account type (typically: Single tenant)
- No redirect URI needed
- Note down:
  - **Application (Client) ID** -- you'll need this
  - **Directory (Tenant) ID** -- you'll need this

### Step 2: Create a Client Secret

- In the App Registration, go to **Certificates & secrets**
- Click **New client secret**
- Set an expiry (recommended: 12-24 months)
- **Copy the secret value immediately** -- it won't be shown again

### Step 3: Grant API Permissions

- In the App Registration, go to **API permissions**
- Add permissions for **Microsoft Graph**:
  - `Sites.Read.All` (Application type) -- to read SharePoint sites
  - `Files.Read.All` (Application type) -- to read files
- **Grant admin consent** (requires a Global Admin or Privileged Role Admin)
- The status should show "Granted for [your tenant]"

### Step 4: (ACL Variants Only) Upload a Certificate

- If using an ACL-enabled connector variant, you also need:
  - A **PEM certificate** uploaded to the App Registration
  - The corresponding **PEM private key** configured in the connector

### Step 5: Get Your SharePoint Site URL

- Navigate to your SharePoint site in a browser
- The URL format is: `https://<tenant>.sharepoint.com/sites/<sitename>`
- Example: `https://contoso.sharepoint.com/sites/engineering-docs`

---

## Step-by-Step: Snowflake Side Setup

### Step 1: Create an EAI for Microsoft Endpoints (SPCS Only)

**Why is an EAI still needed?**
- Even though SharePoint uses OAuth (not a direct database connection), SPCS containers are still sandboxed
- The container needs to reach Microsoft's login and API endpoints
- Without the EAI, you'll get `UnknownHostException` when the connector tries to authenticate or fetch files

**What's different from Postgres?**
- Postgres EAI: Opens a specific host:port to YOUR database
- SharePoint EAI: Opens standard Microsoft endpoints (same for all customers)
- No customer-specific network policy / firewall rule needed on the SharePoint side -- it's all OAuth

**Create the Network Rule:**
```sql
USE ROLE SECURITYADMIN;

CREATE NETWORK RULE sharepoint_openflow_network_rule
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = (
    'login.microsoftonline.com:443',
    'login.microsoft.com:443',
    'graph.microsoft.com:443',
    '*.sharepoint.com:443'
  );
```

> Note: The wildcard `*.sharepoint.com` covers `<tenant>.sharepoint.com` for any tenant. Snowflake wildcards match a single subdomain level, which is sufficient here.

**Verify:**
```sql
DESCRIBE NETWORK RULE sharepoint_openflow_network_rule;
```

**Create the EAI:**
```sql
CREATE EXTERNAL ACCESS INTEGRATION sharepoint_openflow_eai
  ALLOWED_NETWORK_RULES = (sharepoint_openflow_network_rule)
  ENABLED = TRUE
  COMMENT = 'External Access Integration for OpenFlow SharePoint connectivity';
```

**Verify:**
```sql
DESCRIBE INTEGRATION sharepoint_openflow_eai;
```

**Grant to runtime role:**
```sql
GRANT USAGE ON INTEGRATION sharepoint_openflow_eai TO ROLE <your_runtime_role>;
```

**Attach to Runtime (UI step):**
1. Go to OpenFlow Control Plane in Snowsight
2. Find your Runtime > click **"..."** > **"External access integrations"**
3. Select `sharepoint_openflow_eai`
4. Click **Save**

---

### Step 2: Deploy the SharePoint Connector

- Use the OpenFlow Control Plane UI or nipyapi CLI
- Choose the appropriate flow name based on your needs (see Connector Variants table above)
- The connector is deployed from the Snowflake Connector Registry

---

### Step 3: Configure Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Sharepoint Site URL | `https://<tenant>.sharepoint.com/sites/<sitename>` | Full site URL |
| Sharepoint Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | From Entra Admin Center |
| Sharepoint Client ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | From App Registration |
| Sharepoint Client Secret | `(your secret)` | Sensitive -- cannot be read back |
| Sharepoint Application Certificate | `(PEM content)` | ACL variants only |
| Sharepoint Application Private Key | `(PEM content)` | ACL variants only, sensitive |
| Sharepoint Source Folder | `/` or `/path/to/folder` | Optional -- blank or `/` for root |
| File Extensions To Ingest | `pdf,docx` or empty | Optional -- empty string for all files |
| Sharepoint Document Library Name | `Documents` | Optional -- specific library name |
| Destination Database | `MY_TARGET_DB` | Snowflake database |
| Destination Schema | `MY_SCHEMA` | Snowflake schema |
| Snowflake Role | `<runtime_role>` | Must have appropriate permissions |
| Snowflake Warehouse | `MY_WH` | Used for processing |
| Snowflake Authentication Strategy | `SNOWFLAKE_SESSION_TOKEN` | For SPCS deployments |

**No asset uploads required** -- this connector uses text parameters only (unlike Postgres, which needs a JDBC driver).

---

### Step 4: Verify and Enable Controllers

```bash
# Verify controllers (before enabling)
nipyapi --profile <profile> ci verify_config --process_group_id "<pg-id>" --verify_processors=false
```

- Fix any errors before proceeding
- Enable controllers via lifecycle commands
- **Known issue (SPCS):** `StandardPrivateKeyService` may show as INVALID. This is expected -- it's for BYOC KEY_PAIR auth and is unused on SPCS. Ignore it.

---

### Step 5: Verify and Start Processors

```bash
# Verify processors (after controllers are enabled)
nipyapi --profile <profile> ci verify_config --process_group_id "<pg-id>" --verify_controllers=false
```

- Start the flow once verification passes

---

### Step 6: Validate Data is Flowing

```bash
nipyapi --profile <profile> ci get_status --process_group_id "<pg-id>"
```

Expected:
- `running_processors` > 0
- `invalid_processors` = 0
- `bulletin_errors` = 0

**Check destination in Snowflake:**

For Stage connectors:
```sql
LIST @MY_TARGET_DB.MY_SCHEMA.<stage_name>;
```

For Cortex Search connectors:
```sql
SELECT COUNT(*) FROM MY_TARGET_DB.MY_SCHEMA.DOCS_CHUNKS;
```

---

## Quick Reference: Steps in Order

### Microsoft Entra ID (Do First)

1. Create App Registration -- note down **Client ID** and **Tenant ID**
2. Create Client Secret -- copy the value immediately
3. Grant API permissions (`Sites.Read.All`, `Files.Read.All`) and get admin consent
4. (ACL only) Upload certificate and keep private key ready
5. Note your SharePoint Site URL

### Snowflake (Do Second)

```sql
-- 1. Create Network Rule (SPCS only)
USE ROLE SECURITYADMIN;
CREATE NETWORK RULE sharepoint_openflow_network_rule
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = (
    'login.microsoftonline.com:443',
    'login.microsoft.com:443',
    'graph.microsoft.com:443',
    '*.sharepoint.com:443'
  );

-- 2. Verify
DESCRIBE NETWORK RULE sharepoint_openflow_network_rule;

-- 3. Create EAI
CREATE EXTERNAL ACCESS INTEGRATION sharepoint_openflow_eai
  ALLOWED_NETWORK_RULES = (sharepoint_openflow_network_rule)
  ENABLED = TRUE;

-- 4. Verify
DESCRIBE INTEGRATION sharepoint_openflow_eai;

-- 5. Grant to runtime role
GRANT USAGE ON INTEGRATION sharepoint_openflow_eai TO ROLE <your_runtime_role>;

-- 6. Attach EAI to Runtime via UI (manual step)
```

### OpenFlow (Do Third)

1. Deploy connector from registry
2. Configure parameters (Site URL, Tenant ID, Client ID, Client Secret, etc.)
3. Verify controllers > Enable controllers
4. Verify processors > Start flow
5. Validate data in Snowflake

---

## Postgres vs SharePoint: Side-by-Side Comparison

| Aspect | PostgreSQL | SharePoint |
|--------|-----------|------------|
| **Authentication** | Username + Password (JDBC) | OAuth (Client ID + Client Secret) |
| **EAI Required?** | Yes -- to reach your private database host | Yes -- to reach Microsoft's public endpoints |
| **Network Rule** | Specific to YOUR host:port | Standard Microsoft domains (same for everyone) |
| **Source-side network config** | Must allow inbound from SPCS (security group / firewall) | Not needed -- OAuth is outbound-only |
| **JDBC Driver** | Must upload `.jar` as asset | Not needed |
| **Replication Identity** | Must set on each table | Not applicable |
| **Publication** | Must create in PostgreSQL | Not applicable |
| **Primary Keys** | Required on every table | Not applicable |
| **Destination** | Snowflake tables (auto-created) | Internal Stage or Cortex Search |

---

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| `UnknownHostException` | EAI not configured or not attached | Create/verify EAI with Microsoft domains, attach to runtime |
| Authentication failed | Invalid Client Secret or expired | Regenerate secret in Entra, update parameter |
| No files syncing | Wrong Source Folder path | Verify folder path matches the actual SharePoint library structure |
| `StandardPrivateKeyService` INVALID | Expected on SPCS | Ignore -- this controller is for BYOC only |
| Admin consent not granted | API permissions pending | Get a Global Admin to grant consent in Entra |
| Wrong files syncing | File extension filter misconfigured | Check `File Extensions To Ingest` parameter (empty = all files) |

---

## Key Concepts Summary

- **OAuth via Entra ID:** SharePoint uses Client ID + Client Secret for authentication. No database passwords or JDBC connections involved.
- **EAI still required:** Even though it's OAuth, SPCS needs explicit permission to reach any external host, including Microsoft's.
- **No source-side firewall changes:** Unlike Postgres where you must allow inbound connections, SharePoint auth is outbound-only from SPCS to Microsoft's cloud.
- **No JDBC driver needed:** The connector communicates via Microsoft Graph API over HTTPS, so no driver upload is required.
- **ACL support is optional:** Choose an ACL variant if you need to preserve SharePoint permission metadata in Snowflake. Otherwise, use the simpler no-ACL variant.
