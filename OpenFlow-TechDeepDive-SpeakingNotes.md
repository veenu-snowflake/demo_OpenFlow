# OpenFlow Technical Deep Dive — Speaking Notes

> Slides 1-43 | Sales-ready pitch script
> Prepared for: Veenu Yadav | Region: APJ/SEAPAC | March 2026

---

## SLIDE 1: Title — OPENFLOW TECHNICAL DEEP DIVE

**[Hold 3 seconds. Let the room settle.]**

> "Good [morning/afternoon]. I'm Veenu, and today I'm going to show you how Snowflake is solving the hardest problem in data engineering — getting data in."

---

## SLIDE 2: Safe Harbor

**[Skim or skip depending on audience]**

> "Quick legal note — some features are GA, some are in preview. I'll call out the status as we go. Roadmap items are directional, not commitments. Let's get to the good stuff."

---

## SLIDE 3: AGENDA

> "Here's how the next 45 minutes will flow. Three acts:
>
> **Act 1 — The Why.** What is OpenFlow, what's NiFi under the hood, and the real question — what does OpenFlow solve that NiFi alone can't?
>
> **Act 2 — The How.** Architecture, connectors, deployment models, and how you monitor all of it.
>
> **Act 3 — The Proof.** Live demo and real-world use cases — CDC, streaming, SaaS, unstructured data for AI.
>
> Jump in with questions anytime. This is a conversation, not a monologue."

---

## SLIDE 4: OPENFLOW OVERVIEW (Section Divider)

**[Pause. Let the audience reset.]**

---

## SLIDE 5: Snowflake OpenFlow

> "One sentence: OpenFlow is Snowflake's fully managed data integration service — powered by Apache NiFi.
>
> The keyword is *managed*. You're not provisioning clusters, not managing ZooKeeper, not debugging Kubernetes networking. Snowflake does that.
>
> It's open and extensible — 276 open-source processors plus 88 Snowflake-built ones. Structured, unstructured, streaming, batch — every data type, every source.
>
> And you get deployment choice: Snowflake-hosted on SPCS, or BYOC — Bring Your Own Cloud — runtime in your AWS account.
>
> **Pitch line:** *Think of it as one platform to replace the three or four tools you're stitching together today.*"

---

## SLIDE 6: NiFi OVERVIEW (Section Divider)

**[Pause. Transition.]**

---

## SLIDE 7: OpenFlow is Built on Apache NiFi

> "Under the hood — Apache NiFi. Originally built by the NSA as 'Niagarafiles' in 2006. Open-sourced in 2014. Battle-tested at the world's most demanding organizations for over a decade.
>
> Here's the important part: Snowflake didn't just adopt NiFi. We acquired Datavolo — the company founded by the NiFi creators — in November 2024. The people who *built* NiFi now work at Snowflake.
>
> **Pitch line:** *You're not getting a fork of NiFi. You're getting NiFi from the source, with Snowflake's enterprise muscle behind it.*"

---

## SLIDE 8: What is Apache NiFi Known For?

> "Before I show you what OpenFlow adds, let me be fair to NiFi. Five things it's famous for:
>
> **Data provenance** — full chain of custody. Trace any record to its origin.
> **Back-pressure** — downstream slows down? NiFi buffers gracefully. No crashes.
> **Guaranteed delivery** — write-ahead logs. Zero data loss, even during failures.
> **Visual design** — drag-and-drop canvas. Your business analysts can actually read the pipeline.
> **Extensibility** — 276+ processors. If a connector doesn't exist, build one.
>
> So NiFi is powerful. The real question is...
>
> **Pitch line:** *If NiFi is this good, why do you need OpenFlow? Let me show you.*"

---

## SLIDE 9: WHAT OPENFLOW SOLVES (Section Divider)

> "This is the most important section. NiFi is a phenomenal engine. But running NiFi at enterprise scale, in production, with SLAs? That's a completely different game."

---

## SLIDE 10: OpenFlow Supercharges Apache NiFi

> "Four things that change when you go from NiFi to OpenFlow:
>
> **Cloud-Native Refresh.** NiFi 1.x needed ZooKeeper and JVM clusters. NiFi 2.x needs Kubernetes. Either way, that's a full-time ops team. OpenFlow? You click 'deploy' in Snowsight. Snowflake manages the K8s cluster, node scaling, image updates, health checks. You build flows, not infrastructure.
>
> **Simplified Security.** Self-managed NiFi means DIY authentication, DIY TLS, DIY secrets. Enterprise InfoSec teams hate that. OpenFlow inherits Snowflake Identity — OAuth2, RBAC with Admin/Editor/Viewer, PrivateLink, Tri-Secret Secure, Vault integration. Security comes built-in, not bolted on.
>
> **Extended for Modern AI.** This is the one no open-source NiFi user gets. OpenFlow has native connectors for unstructured data — SharePoint, S3, GCS — that land documents, images, audio, video directly into Snowflake for Cortex AI. RAG-powered chatbots, document intelligence, search — all fed by OpenFlow.
>
> **Secure, Continuous Unstructured Ingestion.** Not just a one-time load. Continuous sync with permission honoring from source systems. Your governance story stays intact.
>
> **Pitch line:** *NiFi is the engine. OpenFlow is the production-ready car — power steering, airbags, GPS, and a full maintenance contract. You wouldn't build a car from an engine. Don't build a data platform from raw NiFi.*"

---

## SLIDE 11: Snowflake for Data Engineering

> "Where does OpenFlow fit in the bigger picture?
>
> Think of the data lifecycle: Ingest → Transform → Orchestrate → Deliver.
>
> OpenFlow is your Extract and Load — the 'EL' in ELT. It lands raw data fast. Then Dynamic Tables, dbt, Snowpark, Stored Procedures handle the transformation inside Snowflake.
>
> **Pitch line:** *OpenFlow doesn't try to do everything. It does one thing brilliantly — get your data in. Then it hands off to the most powerful compute engine in the cloud.*"

---

## SLIDE 12: Why OpenFlow is Important (Platform View)

> "Four capabilities in one platform: Extract, Load, Preprocess, Activate.
>
> 'Preprocess' — row-level transforms in-flight. Mask PII before it even hits Snowflake. Filter, route, enrich.
>
> 'Activate' — reverse ETL. Push data *back* to SaaS systems, APIs, downstream consumers.
>
> And everything runs on one bill, one dashboard, one security model.
>
> **Pitch line:** *Today you pay Fivetran for ingestion, Hightouch for reverse ETL, and Datadog for monitoring. OpenFlow collapses all three into your existing Snowflake contract.*"

---

## SLIDE 13: Ingestion Options for Every Use Case

> "Snowflake now has a complete ingestion portfolio. Let me position each so there's no confusion:
>
> **Snowpipe** — file drops from S3/GCS/Azure. Serverless. ~30 second latency.
>
> **Snowpipe Streaming** — sub-5-second. Serverless. But you need a client app to push data.
>
> **OpenFlow** — enterprise-wide. CDC, streaming, SaaS, unstructured. The platform play when you need more than file drops.
>
> **ETL Partners** — Fivetran, Informatica. Leverage what you have.
>
> Here's a nuance I want you to take away: OpenFlow CDC connectors *use* Snowpipe Streaming under the hood for the ingestion phase — that part is free. What costs credits is the warehouse running the MERGE.
>
> **Pitch line:** *OpenFlow isn't competing with Snowpipe. It's built on top of it. You get the best of both.*"

---

## SLIDE 14: OPENFLOW ARCHITECTURE (Section Divider)

**[Pause. Transition to architecture.]**

> "Now let's pop the hood."

---

## SLIDE 15: OpenFlow Architecture

> "Three layers — simple:
>
> **Control Plane** — fully managed in your Snowflake account. This is mission control. Manage deployments, install connectors, set up alerts. Always on.
>
> **Connectors** — 18 GA and growing. Database, streaming, SaaS, unstructured. Broad and getting broader every quarter.
>
> **Deployment Options** — Snowflake-hosted (SPCS) or customer-hosted (BYOC). BYOC has two flavors: Snowflake-managed VPC or Bring Your Own VPC.
>
> Built on NiFi 2.x — cloud-native. No ZooKeeper. No JVM clustering headaches."

---

## SLIDE 16: Handling Global Data Movement

> "This diagram shows the big picture. Control Plane manages both SPCS and BYOC deployments. Each deployment runs runtimes where your flows execute.
>
> Real-world pattern: SPCS for your SaaS connectors (Salesforce, Workday — public endpoints). BYOC for your Oracle database sitting in a private subnet. Both managed from one Snowflake account.
>
> One rule: OpenFlow must be in the **same region** as your Snowflake account. The source can be anywhere — cross-region, on-prem, different cloud.
>
> **Pitch line:** *One control plane, multiple deployment models, any data source. That's the architecture.*"

---

## SLIDE 17: CONNECTORS & FLOWS (Section Divider)

**[Pause. Transition.]**

> "Let's talk about what you connect to."

---

## SLIDE 18: NiFi Processor vs OpenFlow Connector

> "Quick terminology:
>
> **Processor** — a single building block. 276 from Apache, 88 from Snowflake. Low-level.
>
> **Connector** — a curated, versioned, Snowflake-built flow composed of multiple processors. Pre-configured for performance, fault-tolerance, and simplicity. 18 GA today.
>
> **Pitch line:** *Processors are LEGO bricks. Connectors are the complete LEGO set with instructions. You can build custom, but most customers don't need to — connectors work out of the box.*"

---

## SLIDE 19: Deployments & Runtimes

> "Two concepts to remember:
>
> **Deployment** — the infrastructure envelope. BYOC = K8s cluster in your cloud. SPCS = compute pools in Snowflake.
>
> **Runtime** — where flows actually run. Multiple runtimes per deployment. Each gets its own NiFi UI, own sizing, own scaling, own security boundary.
>
> Analogy: Deployment is the building. Runtimes are floors. Each floor has its own badge, resources, and team. A noisy CDC flow on floor 3 won't impact the SaaS connector on floor 5.
>
> Sizing: Small = 1 vCPU, Medium = 4 vCPU, Large = 8 vCPU. Min nodes = 0 is valid — pay nothing when idle.
>
> **Pitch line:** *Isolate workloads, control costs, scale independently. That's what runtimes give you.*"

---

## SLIDE 20: OpenFlow Connectors — Four Categories

> "**Database** — zero-impact CDC. Reads the transaction log, not the database. Your production DB doesn't even notice. Deferred merge — Snowpipe Streaming captures changes in real-time, warehouse runs MERGE on your schedule. Postgres, MySQL, SQL Server, Oracle — all GA.
>
> **Streaming** — Kafka, Kinesis, Event Hub. Up to 10 GB/s. Auto-scaling. Write directly to Snowflake or Iceberg tables.
>
> **Unstructured** — SharePoint, S3, GCS, Azure Blob. Documents, images, audio, video — directly into Snowflake for Cortex AI. Maintains source permissions.
>
> **SaaS** — Salesforce, Google Sheets, Workday, ServiceNow. Initial + incremental sync. OAuth, API tokens, credentials.
>
> **Pitch line:** *Four connector categories, 18 GA connectors. One platform for every data type your organization has.*"

---

## SLIDE 21: Connector Roadmap

> "Google BigQuery, Azure Data Lake Storage, more SaaS connectors — all on the roadmap. These are directional. Check release notes for current availability.
>
> **Pitch line:** *The connector library is growing every quarter. If you don't see your source today, it's likely coming soon.*"

---

## SLIDE 22: Getting Started with Connectors

> "Four steps — this is how easy it is:
>
> One — discover and install from Snowsight. No CLI, no YAML files.
> Two — configure source and destination.
> Three — start the process group.
> Four — customize if you need to.
>
> For CDC, the initial snapshot happens automatically, then it switches to real-time change capture. You don't manage the cutover.
>
> **Pitch line:** *From zero to replicating data in under 15 minutes. I'll prove it in the demo.*"

---

## SLIDE 23: Inflight Transformations

> "OpenFlow handles row-level transforms *before* data lands in Snowflake: schema changes, filtering, PII masking, routing to different tables, enrichment via lookups or API calls, encryption.
>
> For the heavy stuff — aggregations, joins, window functions — use Snowflake's engine: Dynamic Tables, Snowpark, dbt, Tasks.
>
> **Pitch line:** *OpenFlow lands clean, masked, routed raw data. Snowflake transforms it into gold. Each tool does what it's best at.*"

---

## SLIDE 24: DEPLOYMENT MODELS (Section Divider)

**[Pause. Transition.]**

> "Let's talk about where this actually runs."

---

## SLIDE 25: SPCS vs BYOC

> "Two options, side by side:
>
> **Snowflake Hosted (SPCS)** — fastest to deploy. No infrastructure to manage. Perfect for public endpoints — Workday, Salesforce, SharePoint. Public Preview on AWS and Azure. GCP is roadmap.
>
> **Customer Hosted (BYOC)** — runtime in your AWS account. Snowflake manages it. Greater control over networking — VPC peering, PrivateLink, Direct Connect. GA on AWS. Azure and GCP roadmap.
>
> Three reasons to go BYOC: (1) private data sources behind firewalls, (2) data residency requirements, (3) leverage your existing AWS reserved instance pricing.
>
> **Pitch line:** *Public endpoints? SPCS in 10 minutes. Private databases? BYOC with full network control. You're not locked into one model.*"

---

## SLIDE 26: BYOC Options — Managed VPC vs BYO-VPC

> "Within BYOC, two flavors:
>
> **Snowflake Managed VPC** — Snowflake creates the VPC, subnets, gateways. Easiest setup.
>
> **Bring Your Own VPC** — you provide an existing VPC. More control. This is what you want when your database is already in a specific VPC.
>
> Real example: a financial services client has Oracle RDS in a private subnet in Mumbai. BYO-VPC lets us deploy OpenFlow into the same VPC. Zero data leaving the network boundary.
>
> **Pitch line:** *Your data, your VPC, your rules. Snowflake just manages the runtime inside it.*"

---

## SLIDE 27: Connectivity Decision Tree

> "Simple flowchart:
>
> Source on public internet? → **SPCS**. Done.
> Not public but supports PrivateLink? → **SPCS or BYOC**, your call.
> Behind a firewall, no PrivateLink? → **BYOC**. On-prem? Add Direct Connect.
>
> **Pitch line:** *No dead ends. Whatever your network topology, there's a path to Snowflake.*"

---

## SLIDE 28: Compliance Certifications

> "SOC 2, HIPAA, FedRAMP — targets are on this slide. Check the Snowflake Trust Center for latest status. Dates may shift.
>
> **Pitch line:** *Compliance is in motion. If you have specific requirements, let's map them together.*"

---

## SLIDE 29: BYOC Recommended Deployment Pattern

> "Best practice: separate deployments for pre-prod and prod. Multiple runtimes within each for workload isolation.
>
> Keep Snowflake account and BYOC deployment in the same cloud and region. Not required, but strongly recommended.
>
> **Pitch line:** *This is how enterprises run it. Dev and prod isolated. Teams isolated. Blast radius contained.*"

---

## SLIDE 30: Secure Data Pipelines — BYOC

> "This is the slide that wins over InfoSec teams.
>
> BYOC sits in the customer's VPC. PrivateLink to Snowflake. VPC peering to data source VPCs. Direct Connect to on-prem.
>
> Data flow: Source → OpenFlow (your VPC) → Snowflake (via PrivateLink). At no point does data touch the public internet.
>
> **Pitch line:** *Your CISO's two favorite words: 'private' and 'encrypted'. OpenFlow delivers both.*"

---

## SLIDE 31: Secure Data Pipelines — SPCS

> "For SPCS — similar security model but the runtime lives inside Snowflake's environment. PrivateLink available on Business Critical and VPS editions.
>
> Need to reach back to on-prem from SPCS? Transitive routing — your networking team sets that up.
>
> **Pitch line:** *Even on SPCS, you're not exposed. PrivateLink keeps everything internal.*"

---

## SLIDE 32: Multi-Cloud Data Pipelines

> "Ingest from any cloud. Land into Snowflake tables or Iceberg tables. Transform with dbt or Snowpark. Govern with Horizon Catalog.
>
> **Pitch line:** *OpenFlow is the universal on-ramp. It doesn't matter where your data lives today.*"

---

## SLIDE 33: OPENFLOW OBSERVABILITY (Section Divider)

> "Now the question every ops team asks: *how do I know it's working?*"

---

## SLIDE 34: Recommended Alerts

> "One command: `CREATE_RECOMMENDED_ALERTS`. Configure your email notification. Done.
>
> Out-of-the-box alert configurations — Snowflake monitors your OpenFlow pipelines and fires alerts when connectors have issues or miss performance targets.
>
> No manual Event Table queries. No custom scripts. No Grafana dashboards to build.
>
> **Pitch line:** *Monitoring shouldn't be a project. With OpenFlow, it's a one-line command.*"

---

## SLIDE 35: Connector Dashboard & CDC Replication Status

> "Snowsight → Ingestion → OpenFlow. One screen.
>
> See every deployed connector. Health. Performance. CDC replication status per table. Which tables are current, which are lagging, and why.
>
> Debug without opening the NiFi canvas.
>
> **Pitch line:** *Your data engineers get operational visibility without learning NiFi. That's hours saved every week.*"

---

## SLIDE 36: Log Explorer & Troubleshooting

> "When you need to go deeper — the Issues tab shows errors in plain English. Deep-link into Log Explorer with pre-set OpenFlow filters.
>
> For power users: NiFi UI remains your primary operational dashboard. SPCS logs via `SYSTEM$GET_SERVICE_LOGS`. BYOC gets CloudWatch too.
>
> **Pitch line:** *Three levels of depth: dashboard for execs, issues tab for engineers, raw logs for SREs. Everyone gets what they need.*"

---

## SLIDE 37: DEMO (Section Divider)

> "Enough slides. Let me show you the real thing.
>
> I'm going to replicate a live Postgres database to Snowflake using CDC — every insert, update, delete captured in real-time. Then I'll ingest SharePoint documents and show how Cortex AI makes them searchable.
>
> Watch how fast the data shows up."
>
> **[Run the demo]**
>
> "See that? A row was just inserted in Postgres. And it's already in Snowflake. That's CDC through OpenFlow. Near-real-time. Zero custom code."

---

## SLIDE 38: USE CASES (Section Divider)

> "Let me put this in the context of real problems you're solving today."

---

## SLIDE 39: CDC Replication — Before & After

> "**Before OpenFlow:** You'd stitch together AWS DMS to land in S3. Snowpipe to pick up files. Custom Python or dbt scripts to run the MERGE. Custom logic to handle deletes. Custom alerting when schemas change at 2 AM. Engineer-months of maintenance.
>
> **After OpenFlow:** One CDC connector. Reads the transaction log — zero impact on your production database. Snowpipe Streaming ingests in real-time. Deferred MERGE applies changes. Inserts, updates, deletes — all captured automatically. Schema evolution handled.
>
> Latency: P90 = 2 minutes. P95 = 5 minutes. P100 under 10 minutes, including the MERGE.
>
> **Pitch line:** *Every company we talk to has a DMS-to-S3-to-Snowpipe pipeline that breaks. OpenFlow replaces the entire thing with one connector.*"

---

## SLIDE 40: Unlocking Unstructured Data for AI

> "This is the AI use case — and it's the one that gets executives excited.
>
> **Before:** Untapped value sitting in SharePoint, file servers, cloud storage. Complex multi-vendor solutions. Pipeline latency. Orchestration nightmares.
>
> **After:** OpenFlow ingests documents, images, audio, video directly into Snowflake. Pair with Cortex Search for RAG-powered chatbots. Cortex AI for summarization, classification, extraction. Streamlit for the front-end.
>
> End-to-end governance — source system permissions are honored all the way through.
>
> **Pitch line:** *Your unstructured data is your biggest untapped asset. OpenFlow turns it into an AI-ready corpus in hours, not months.*"

---

## SLIDE 41: Streaming Analytics

> "**Before:** Kafka Connect with the Snowflake sink connector. You manage Connect clusters, handle failures, monitor lag. Or Amazon Firehose to S3 to Snowpipe — extra hops, extra latency.
>
> **After:** Kafka, Kinesis, Event Hub → OpenFlow → Snowflake. Direct. Up to 10 GB/s. Auto-scaling. No Connect clusters to manage.
>
> Dynamic Tables on top for continuous transformation. Dashboards and Streamlit apps consume in near real-time.
>
> **Pitch line:** *Streaming shouldn't require a streaming team. OpenFlow makes it an ops-free pattern.*"

---

## SLIDE 42: Customer 360 — Holistic Analytics

> "**Before:** Export SaaS data to disk. Upload to cloud storage. Snowpipe. Hope the schema didn't change. Repeat for every SaaS app. Join manually. Pray it works.
>
> **After:** Salesforce + ServiceNow + Workday → OpenFlow → Snowflake staging tables. Join with your transactional data. dbt or Dynamic Tables for transformation. One complete customer view.
>
> **Pitch line:** *Customer 360 is a vision everyone talks about. OpenFlow is how you actually build it — one platform, one billing, one governance model.*"

---

## SLIDE 43: THANK YOU

> "That's the story. OpenFlow — one managed platform to get every kind of data into Snowflake, securely, in near real-time.
>
> Three things I want you to remember:
>
> **One** — it's managed. You build flows, Snowflake runs the infrastructure.
> **Two** — it's flexible. SPCS or BYOC, public or private, structured or unstructured.
> **Three** — it's native. One bill, one dashboard, one security model. No third-party sprawl.
>
> I can have a proof of concept running with *your* data in under a day. Let's set that up.
>
> Questions?"

---
---

# BONUS SECTIONS (Not on slides — use in conversation)

---

## HIDDEN SLIDES TO PULL UP

### Slide 48: Security Detail (if InfoSec is in the room)

> "Let me pull up the security architecture:
>
> **Auth** — OAuth2 bridge to Snowflake Identity. SSO from Snowsight.
> **RBAC** — Admin, Editor, Viewer. Runtime isolation as blast radius containment.
> **Encryption** — TLS everywhere.
> **Secrets** — Vault, AWS Secrets Manager, Azure Key Vault.
> **PrivateLink** — for data and Control Plane API.
> **Tri-Secret Secure** — customer-managed keys for writes.
>
> **Pitch line:** *This isn't 'we support security.' This is 'security is inherited from Snowflake.' Your existing policies extend to OpenFlow automatically.*"

### Slide 71: Benchmarks (if asked about latency)

> "CDC benchmarks: P90 = 2 min, P95 = 5 min, P100 under 10 min including MERGE. One warehouse for merge. Snowpipe Streaming handles ingestion serverlessly."

---

## COST TALKING POINTS

> "OpenFlow looks expensive only because it's transparent. Three line items: compute pool, warehouse, Snowpipe Streaming. Other tools hide it in one opaque bill.
>
> Typical annual cost: **$5-6K** for a small CDC workload vs **$80-150K** for Fivetran or Informatica at equivalent scale.
>
> Always-on management pool: ~122 credits/month (~$366/month at Enterprise). That's the floor.
>
> Set min nodes to 0 — pay $0 compute when idle. ~10 min cooldown, ~2-3 min cold start.
>
> BYOC dual billing: AWS EC2 at your rates + Snowflake per vCPU-hour. 4 physical CPUs = 1 vCPU in billing.
>
> **Pitch line:** *When a customer asks 'how much,' I show them three line items. When Fivetran customers ask 'how much,' they get one number with no breakdown. Which one do you trust?*"

---

## OBJECTION HANDLERS

**"We already use DMS"**
> "DMS gets you to S3. Then what? Snowpipe, staging tables, custom MERGE scripts, schema evolution handling — that's all on your team. OpenFlow does it end-to-end. One connector. One bill."

**"We have a DIY CDC pipeline"**
> "How does it handle deletes? Schema changes? What happens when you need to scale to 100 tables? How many engineer-hours per month does maintenance cost? OpenFlow is the managed version of what your team built from scratch."

**"Fivetran is cheaper"**
> "At 10 tables with low volume, maybe. At 100+ tables or high throughput, OpenFlow's flat compute model wins every time. Plus: BYOC deployment, unstructured data, and no per-row pricing surprises."

**"Why not just run NiFi ourselves?"**
> "You can. But you'll need a K8s team, a security team, a monitoring stack, custom Snowpipe Streaming integration, and someone to build the MERGE logic. The question is: is your team's time better spent building flows or managing infrastructure?"

**"No primary key on source tables"**
> "CDC requires PK. For no-PK tables: JDBC full refresh (truncate & reload) or JDBC incremental (timestamp-based). Both patterns run in the same runtime — hybrid approach."

**"What about monitoring / Datadog / Splunk?"**
> "NiFi UI for ops, Snowsight dashboard for connector health, Event Table for alerts, SPCS service logs or CloudWatch for BYOC. No native Datadog/Splunk integration today — use log forwarding."

**"Is it production-ready?"**
> "BYOC is GA on AWS. 18 connectors are GA. Snowpipe Streaming — which powers the ingestion — moves petabytes daily for thousands of customers. This isn't a beta."

**"We're on Azure / GCP"**
> "SPCS is in Public Preview on AWS and Azure. BYOC is GA on AWS, Azure is roadmap. GCP is roadmap for both. If you're on Azure SPCS, we can start today."
