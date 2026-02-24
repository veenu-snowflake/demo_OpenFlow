# OpenFlow: Connecting PostgreSQL to Snowflake (CDC)

## What This Does

- Replicates data from PostgreSQL tables to Snowflake in near-real-time using Change Data Capture (CDC)
- Uses Debezium-based logical replication under the hood
- Runs on Snowpark Container Services (SPCS) inside your Snowflake account

---

## High-Level Flow

```
PostgreSQL (Source)
    |
    |  Logical Replication (WAL)
    v
OpenFlow Runtime (SPCS)
    |
    |  Snowpipe Streaming
    v
Snowflake (Destination Tables)
```

---

## Prerequisites on the PostgreSQL Side

Before touching anything in Snowflake, your PostgreSQL database must be prepared:

- **WAL level must be set to `logical`**
  - This enables PostgreSQL to stream row-level changes
  - Check current setting: `SHOW wal_level;`
  - If it shows `replica` or `minimal`, you need to change it to `logical`
  - For AWS RDS: Set the `rds.logical_replication` parameter to `1` in the Parameter Group, then reboot the instance
  - For self-managed Postgres: Update `postgresql.conf` with `wal_level = logical` and restart

- **A Publication must be created**
  - A publication tells Postgres which tables to expose for replication
  - Example:
    ```sql
    CREATE PUBLICATION my_openflow_pub FOR TABLE public.employees, public.orders;
    ```
  - Or for all tables:
    ```sql
    CREATE PUBLICATION my_openflow_pub FOR ALL TABLES;
    ```

- **A database user with replication privileges is required**
  - The user needs `REPLICATION` role and `SELECT` on the tables
  - Example:
    ```sql
    CREATE USER openflow_user WITH REPLICATION PASSWORD 'your_secure_password';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO openflow_user;
    ```

- **Every table being replicated MUST have a Primary Key**
  - CDC relies on primary keys to identify rows for updates and deletes
  - Tables without primary keys will enter a `FAILED` state

- **Replication Identity must be set on each table**
  - This tells Postgres what information to include in the WAL for UPDATE and DELETE operations
  - **Why?** Without replication identity, Postgres only sends the primary key in change events. If you need the full row (before and after values), you must set `REPLICA IDENTITY FULL`
  - Set it per table:
    ```sql
    ALTER TABLE public.employees REPLICA IDENTITY FULL;
    ALTER TABLE public.orders REPLICA IDENTITY FULL;
    ```
  - **Options:**
    - `DEFAULT` -- uses the primary key (sufficient for most cases)
    - `FULL` -- includes all columns in change events (recommended for OpenFlow)
    - `NOTHING` -- disables identity (will break CDC -- do NOT use)

- **Network access: Your PostgreSQL host must be reachable from Snowflake SPCS**
  - For AWS RDS: The security group must allow inbound connections on port 5432 from Snowflake's SPCS IP ranges
  - For self-managed: Firewall/pg_hba.conf must permit the connection

---

## Step-by-Step: Snowflake Side Setup

### Step 1: Create an External Access Integration (EAI)

**Why is an EAI needed?**
- OpenFlow runs inside SPCS (Snowpark Container Services), which is a sandboxed environment
- By default, SPCS containers cannot reach external hosts (your Postgres server)
- The EAI + Network Rule combination punches a controlled hole in the firewall, allowing SPCS to connect to your specific Postgres host on the specific port
- Without this, you will get `UnknownHostException` errors when the connector tries to reach your database

**Create the Network Rule:**
```sql
USE ROLE SECURITYADMIN;

CREATE NETWORK RULE postgres_openflow_network_rule
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('<your-postgres-host>:5432');
```
- Replace `<your-postgres-host>` with your actual hostname (e.g., `mydb.abc123.us-east-1.rds.amazonaws.com`)
- The port must be included (default: `5432`)

**Verify the Network Rule was created:**
```sql
DESCRIBE NETWORK RULE postgres_openflow_network_rule;
```

**Create the External Access Integration:**
```sql
USE ROLE SECURITYADMIN;

CREATE EXTERNAL ACCESS INTEGRATION postgres_openflow_eai
  ALLOWED_NETWORK_RULES = (postgres_openflow_network_rule)
  ENABLED = TRUE
  COMMENT = 'External Access Integration for OpenFlow PostgreSQL CDC connectivity';
```

**Verify the EAI:**
```sql
DESCRIBE INTEGRATION postgres_openflow_eai;
```

**Grant USAGE to the OpenFlow runtime role:**
```sql
GRANT USAGE ON INTEGRATION postgres_openflow_eai TO ROLE <your_runtime_role>;
```
- The runtime role can be found in the OpenFlow Control Plane UI or via infrastructure discovery

**Attach the EAI to your Runtime (UI step):**
1. Go to the OpenFlow Control Plane in Snowsight
2. Find your Runtime in the list
3. Click the **"..."** menu
4. Select **"External access integrations"**
5. Select `postgres_openflow_eai` from the dropdown
6. Click **Save**

> No runtime restart needed -- changes apply immediately.

---

### Step 2: Deploy the PostgreSQL Connector

- Use the OpenFlow Control Plane UI or nipyapi CLI
- Flow name: `postgresql`
- The connector is deployed from the Snowflake Connector Registry

---

### Step 3: Configure Parameters

After deployment, configure these parameters:

| Parameter | Value | Notes |
|-----------|-------|-------|
| PostgreSQL Connection URL | `jdbc:postgresql://<host>:5432/<dbname>` | Full JDBC URL |
| PostgreSQL Username | `openflow_user` | The replication user you created |
| PostgreSQL Password | `(your password)` | Sensitive -- cannot be read back |
| Publication Name | `my_openflow_pub` | Must match what you created in Postgres |
| Included Table Names | `public.employees,public.orders` | Comma-separated list |
| Destination Database | `MY_TARGET_DB` | Snowflake database for replicated data |
| Snowflake Role | `<runtime_role>` | Must have CREATE SCHEMA privileges |
| Snowflake Warehouse | `MY_WH` | Used for processing |
| Snowflake Authentication Strategy | `SNOWFLAKE_SESSION_TOKEN` | For SPCS deployments |

---

### Step 4: Upload the JDBC Driver

- The PostgreSQL JDBC driver must be uploaded as an asset
- Download from Maven Central:
  ```
  https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.7/postgresql-42.7.7.jar
  ```
- Upload it via the parameter asset upload (nipyapi or UI)

---

### Step 5: Verify and Enable Controllers

```bash
# Verify controllers (before enabling)
nipyapi --profile <profile> ci verify_config --process_group_id "<pg-id>" --verify_processors=false
```
- Fix any errors before proceeding
- Enable controllers via the lifecycle commands
- After enabling, all controllers should show `ENABLED` state

---

### Step 6: Verify and Start Processors

```bash
# Verify processors (after controllers are enabled)
nipyapi --profile <profile> ci verify_config --process_group_id "<pg-id>" --verify_controllers=false
```
- Start the flow once verification passes

---

### Step 7: Validate Data is Flowing

```bash
nipyapi --profile <profile> ci get_status --process_group_id "<pg-id>"
```

Expected:
- `running_processors` > 0
- `invalid_processors` = 0
- `bulletin_errors` = 0

**Check tables in Snowflake:**
```sql
-- PostgreSQL uses lowercase identifiers -- you MUST quote them in Snowflake
SELECT COUNT(*) FROM MY_TARGET_DB."public"."employees";
SELECT COUNT(*) FROM MY_TARGET_DB."public"."orders";
```

---

## Quick Reference: SQL Commands to Run on PostgreSQL (In Order)

```sql
-- 1. Check WAL level
SHOW wal_level;

-- 2. Create replication user
CREATE USER openflow_user WITH REPLICATION PASSWORD 'your_secure_password';

-- 3. Grant SELECT on tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO openflow_user;

-- 4. Set replication identity on each table
ALTER TABLE public.employees REPLICA IDENTITY FULL;
ALTER TABLE public.orders REPLICA IDENTITY FULL;

-- 5. Create publication
CREATE PUBLICATION my_openflow_pub FOR TABLE public.employees, public.orders;
```

## Quick Reference: SQL Commands to Run on Snowflake (In Order)

```sql
-- 1. Create Network Rule
USE ROLE SECURITYADMIN;
CREATE NETWORK RULE postgres_openflow_network_rule
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('<your-postgres-host>:5432');

-- 2. Verify Network Rule
DESCRIBE NETWORK RULE postgres_openflow_network_rule;

-- 3. Create EAI
CREATE EXTERNAL ACCESS INTEGRATION postgres_openflow_eai
  ALLOWED_NETWORK_RULES = (postgres_openflow_network_rule)
  ENABLED = TRUE;

-- 4. Verify EAI
DESCRIBE INTEGRATION postgres_openflow_eai;

-- 5. Grant to runtime role
GRANT USAGE ON INTEGRATION postgres_openflow_eai TO ROLE <your_runtime_role>;

-- 6. Attach EAI to Runtime via UI (manual step)
```

---

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| `UnknownHostException` | EAI not configured or not attached | Create/verify EAI, attach to runtime |
| `SocketTimeoutException` | Port not in Network Rule | Add `host:5432` to the network rule VALUE_LIST |
| Table in `FAILED` state | Missing primary key or replication identity | Add PK, set `REPLICA IDENTITY FULL`, then re-add table |
| No data appearing | Publication missing tables | Verify publication includes the table: `SELECT * FROM pg_publication_tables;` |
| Authentication errors | Wrong credentials or missing REPLICATION role | Verify user has REPLICATION privilege and correct password |
| Case-sensitivity issues | Snowflake uppercases by default, Postgres lowercases | Always quote lowercase identifiers in Snowflake: `"public"."tablename"` |

---

## Key Concepts Summary

- **EAI (External Access Integration):** Required because SPCS is sandboxed. Opens network access to your Postgres host.
- **Network Rule:** Defines the exact host:port that SPCS can reach. No wildcards needed for databases.
- **Publication:** Postgres-side mechanism that defines which tables are available for logical replication.
- **Replication Identity:** Tells Postgres what row data to include in WAL change events. Set to `FULL` for best results.
- **JDBC Driver:** Must be uploaded manually as an asset since the connector needs it to talk to Postgres.
- **Case Sensitivity:** Postgres identifiers are lowercase. Snowflake normalizes to uppercase. Always quote lowercase names when querying replicated data.
