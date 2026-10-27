# Mermaid Patterns

These are copy-ready starting points for the `architecture-diagrams` skill. Replace the generic names with the exact `C-` names from the component catalogue, and delete the nodes that don't apply. The syntax is deliberately conservative (`flowchart`, `subgraph`, `sequenceDiagram`, `stateDiagram-v2`), so it renders in most Mermaid versions.

**Syntax rules used throughout**

- `%% Title:` is the first line inside each block, and a `*Caption: …*` sentence follows each block.
- Node IDs are plain alphanumerics (`C05`). Labels are quoted: `C05["C-05 Policy Engine"]`.
- Never put parentheses, brackets, or braces inside an unquoted label. Never use `end` as a node ID.
- Edge labels are quoted: `-->|"HTTPS · workload identity · Confidential"|`.
- Trust zones are `subgraph TBn["TB-n Zone name"]`.
- Shapes: `["…"]` service · `[("…")]` data store · `{"…"}` decision or policy gate · `(["…"])` external actor or system · `[["…"]]` model endpoint · `{{"…"}}` queue, topic, or event bus.

---

## 0. Legend

```mermaid
%% Title: Legend — shapes and edge labels
flowchart LR
  L1["Service or component"]
  L2[("Data store")]
  L3{"Policy gate or decision"}
  L4(["External actor or system"])
  L5[["Model endpoint"]]
  L6{{"Queue, topic, or event bus"}}
  L1 -->|"protocol · identity · classification"| L2
```
*Caption: Shapes and edge-label format used in every diagram in this document.*

## 1. System context

```mermaid
%% Title: System context — Assistant system
flowchart LR
  U(["Employee user"])
  OPS(["Operations team"])
  subgraph SYS["Assistant system"]
    APP["AI Assistant"]
  end
  IDP(["EXT Identity Provider"])
  MP(["EXT Model Provider"])
  BIZ(["EXT Business System of Record"])
  DOCS(["EXT Document Repository"])
  U -->|"Asks questions, approves actions · HTTPS · SSO"| APP
  OPS -->|"Monitors, administers"| APP
  APP -->|"Authenticates users · OIDC"| IDP
  APP -->|"Inference requests · HTTPS · workload identity"| MP
  APP -->|"Reads and writes records · REST · delegated user"| BIZ
  APP -->|"Retrieves content · REST · service identity"| DOCS
```
*Caption: The assistant serves employees and depends on four external systems, two of which receive confidential data.*

## 2. Container / application components

```mermaid
%% Title: Containers — Assistant system
flowchart TB
  U(["Employee user"])
  subgraph SYS["Assistant system"]
    C01["C-01 Web Client"]
    C02["C-02 API Gateway"]
    C03["C-03 Orchestrator"]
    C04["C-04 Policy Engine"]
    C05["C-05 Retrieval Service"]
    C06["C-06 Tool Adapter"]
    C07["C-07 Approval Service"]
    C08[("C-08 Vector Index")]
    C09[("C-09 Audit Log")]
  end
  C10[["C-10 Model Gateway"]]
  BIZ(["EXT Business System"])
  U --> C01
  C01 -->|"HTTPS · user token"| C02
  C02 -->|"gRPC · user context"| C03
  C03 -->|"Authorize step"| C04
  C03 -->|"Query · user entitlements"| C05
  C05 --> C08
  C03 -->|"Prompt · Confidential"| C10
  C03 -->|"Tool call"| C06
  C06 -->|"Check approval token"| C07
  C06 -->|"REST · delegated user"| BIZ
  C03 -->|"Append events"| C09
  C06 -->|"Append events"| C09
```
*Caption: The orchestrator coordinates retrieval, model calls, and tools, while policy and approval checks sit outside the model path.*

## 3. Component (inside one container)

```mermaid
%% Title: Components — C-03 Orchestrator
flowchart LR
  IN["Request Handler"]
  subgraph C03["C-03 Orchestrator"]
    CTX["Context Builder"]
    PLN["Planner Loop"]
    BUD["Budget Guard<br/>steps, time, tokens"]
    TR["Tool Router"]
    OUT["Response Validator"]
  end
  POL{"C-04 Policy Engine"}
  MOD[["C-10 Model Gateway"]]
  TA["C-06 Tool Adapter"]
  IN --> CTX --> PLN
  PLN --> BUD
  PLN -->|"Inference"| MOD
  PLN --> TR
  TR -->|"Authorize"| POL
  POL -->|"Allow"| TA
  PLN --> OUT
```
*Caption: Inside the orchestrator, every tool call is authorized by the external policy engine and every loop iteration is metered by the budget guard.*

## 4. Deployment

```mermaid
%% Title: Deployment — Production, primary region
flowchart TB
  subgraph REG["Region A - primary"]
    subgraph Z1["Zone 1"]
      K1["Container cluster node pool<br/>C-02, C-03, C-05, C-06"]
    end
    subgraph Z2["Zone 2"]
      K2["Container cluster node pool<br/>C-02, C-03, C-05, C-06"]
    end
    DB[("Managed vector store<br/>zone-redundant")]
    LOG[("Audit log store<br/>immutable retention")]
    KV[("Secrets manager")]
  end
  subgraph REGB["Region B - recovery"]
    BK[("Backups and replicas")]
  end
  MG[["Model endpoint<br/>in-region"]]
  K1 --> DB
  K2 --> DB
  K1 --> MG
  K2 --> MG
  K1 -->|"Workload identity"| KV
  DB -->|"Async replication · RPO target"| BK
  LOG -->|"Backup"| BK
```
*Caption: Stateless services run across two zones in the primary region, and stateful stores replicate to a recovery region to meet the RPO target.*

## 5. Sequence: side-effecting request with approval

```mermaid
%% Title: Sequence — Request that changes a business record
sequenceDiagram
  autonumber
  actor U as User
  participant G as API Gateway
  participant O as Orchestrator
  participant P as Policy Engine
  participant R as Retrieval Service
  participant M as Model Gateway
  participant A as Approval Service
  participant T as Tool Adapter
  participant B as Business System
  U->>G: Request with user token
  G->>O: Request plus verified user context
  O->>R: Search with user entitlements
  R-->>O: Permitted passages only
  O->>M: Prompt with passages marked untrusted
  M-->>O: Proposed action and arguments
  O->>P: Authorize proposed action for this user
  alt Policy denies
    P-->>O: Deny with reason
    O-->>U: Explain refusal
  else Policy allows and approval required
    P-->>O: Allow, approval required
    O->>A: Create approval bound to exact parameters
    A-->>U: Show action diff and evidence
    U->>A: Approve
    A-->>O: Single-use approval token
    O->>T: Execute with approval token
    T->>A: Verify token and parameter hash
    T->>B: Write record as delegated user
    B-->>T: Result
    T-->>O: Result
    O-->>U: Confirmation
  end
  Note over O,T: Every step is written to the audit log with a correlation ID
```
*Caption: The model proposes the action, but deterministic policy and a parameter-bound approval decide whether it executes.*

## 6. Data flow with classification

```mermaid
%% Title: Data flow — Ingestion and retrieval
flowchart LR
  SRC(["EXT Document Repository"])
  ING["C-11 Ingestion Pipeline"]
  RED["C-12 Classification and Redaction"]
  EMB[["C-13 Embedding Model"]]
  IDX[("C-08 Vector Index")]
  RET["C-05 Retrieval Service"]
  ORC["C-03 Orchestrator"]
  SRC -->|"Documents plus ACLs · Confidential"| ING
  ING --> RED
  RED -->|"Redacted text · Internal"| EMB
  EMB -->|"Vectors plus ACL metadata"| IDX
  ORC -->|"Query plus user entitlements"| RET
  RET -->|"Filtered query"| IDX
  IDX -->|"Permitted chunks · Internal"| RET
  RET --> ORC
```
*Caption: Classification and redaction run before embedding, and entitlements are enforced at query time, not only at ingestion.*

## 7. Trust boundary / security

```mermaid
%% Title: Trust boundaries — Assistant system
flowchart LR
  subgraph TB1["TB-1 Internet and user devices"]
    U(["User"])
    WEB(["EXT Web content"])
  end
  subgraph TB2["TB-2 Edge"]
    C02["C-02 API Gateway"]
  end
  subgraph TB3["TB-3 Application zone"]
    C03["C-03 Orchestrator"]
    C04{"C-04 Policy Engine"}
    C06["C-06 Tool Adapter"]
    C07["C-07 Approval Service"]
  end
  subgraph TB4["TB-4 Data zone"]
    C08[("C-08 Vector Index")]
    C09[("C-09 Audit Log")]
  end
  subgraph TB5["TB-5 External model provider"]
    C10[["C-10 Model Endpoint"]]
  end
  subgraph TB6["TB-6 Enterprise systems"]
    BIZ(["EXT Business System"])
  end
  U -->|"DF-01 · HTTPS · user token · untrusted input"| C02
  C02 -->|"DF-02 · mTLS · verified user context"| C03
  C03 -->|"DF-03 · prompt · Confidential"| C10
  C03 -->|"DF-04 · query · entitlements"| C08
  WEB -->|"DF-05 · fetched content · untrusted"| C03
  C03 --> C04
  C04 -->|"DF-06 · allowed call only"| C06
  C06 -->|"DF-07 · delegated user · approval token"| BIZ
  C06 --> C07
  C03 -->|"DF-08 · audit events"| C09
```
*Caption: Untrusted input enters at DF-01 and DF-05, and side effects reach enterprise systems only through the policy-gated tool adapter at DF-07.*

## 8a. Agent execution and control flow

```mermaid
%% Title: Agent control flow — bounded tool-using agent
flowchart TD
  S(["Request received"]) --> I{"Input policy check"}
  I -->|"Deny"| X1["Exit: refuse with reason"]
  I -->|"Allow"| P["Plan next step<br/>model call"]
  P --> B{"Within bounds?<br/>max 8 steps, 60 s, token budget"}
  B -->|"No"| X2["Exit: bound exceeded,<br/>hand off to human"]
  B -->|"Yes"| D{"Next action type"}
  D -->|"Final answer"| V{"Output validation<br/>schema, grounding, policy"}
  V -->|"Fail"| X3["Exit: safe fallback response"]
  V -->|"Pass"| OK(["Respond to user"])
  D -->|"Tool call"| A{"Policy engine:<br/>tool allowed for this user?"}
  A -->|"Deny"| P
  A -->|"Allow, read-only"| T["Execute tool"]
  A -->|"Allow, side effect"| H{"Human approval<br/>bound to parameters"}
  H -->|"Rejected or timed out"| X4["Exit: action not taken,<br/>user informed"]
  H -->|"Approved"| T
  T -->|"Success"| P
  T -->|"Error, retry within limit"| P
  T -->|"Error, retries exhausted"| X5["Exit: tool failure,<br/>escalate to human"]
```
*Caption: Every iteration passes the bound check, every tool call passes the policy engine, side effects need parameter-bound approval, and each failure has an explicit exit.*

## 8b. Agent and approval state machine

```mermaid
%% Title: Agent run states
stateDiagram-v2
  [*] --> Received
  Received --> Planning : input policy allows
  Received --> Refused : input policy denies
  Planning --> AwaitingTool : tool call authorized
  Planning --> AwaitingApproval : side effect requested
  Planning --> Completed : final answer validated
  Planning --> Escalated : step or time bound exceeded
  AwaitingApproval --> AwaitingTool : approved
  AwaitingApproval --> Cancelled : rejected or timed out
  AwaitingTool --> Planning : tool result returned
  AwaitingTool --> Escalated : retries exhausted
  Completed --> [*]
  Refused --> [*]
  Cancelled --> [*]
  Escalated --> [*]
```
*Caption: The run reaches a terminal state on every path, and only the approved path leads to a side-effecting tool call.*

## 9. Integration / event flow

```mermaid
%% Title: Event flow — asynchronous document processing
flowchart LR
  SRC(["EXT Source System"])
  Q1{{"Inbound topic"}}
  W["C-14 Processing Worker"]
  DLQ{{"Dead-letter queue"}}
  Q2{{"Result topic"}}
  SINK(["EXT Downstream System"])
  STORE[("C-15 Idempotency Store")]
  SRC -->|"Event · at-least-once"| Q1
  Q1 --> W
  W -->|"Check and record event ID"| STORE
  W -->|"Max retries exceeded"| DLQ
  W -->|"Result event · schema v1"| Q2
  Q2 --> SINK
```
*Caption: At-least-once delivery is made safe by an idempotency store, and poison messages go to a dead-letter queue instead of retrying forever.*

## 10. Environment / network topology

```mermaid
%% Title: Network topology — production
flowchart TB
  NET(["Corporate network and VPN"])
  subgraph VNET["Application virtual network"]
    subgraph SNE["Subnet: ingress"]
      WAF["WAF and API Gateway"]
    end
    subgraph SNA["Subnet: application"]
      APP["Orchestrator and services"]
    end
    subgraph SND["Subnet: data - private endpoints"]
      DS[("Data stores")]
    end
    EG["Egress proxy<br/>domain allow-list"]
  end
  MP[["Model endpoint<br/>private connectivity"]]
  EXT(["Allow-listed external APIs"])
  NET -->|"HTTPS 443"| WAF
  WAF --> APP
  APP -->|"Private endpoint"| DS
  APP -->|"Private link"| MP
  APP --> EG
  EG -->|"HTTPS 443 · allow-listed domains only"| EXT
```
*Caption: All outbound internet traffic leaves through an allow-listing egress proxy, and data stores are reachable only through private endpoints.*

## 11a. CI/CD workflow

```mermaid
%% Title: CI/CD — code, prompt, and model changes
flowchart LR
  PR["Pull request<br/>code, prompt, tool, or model version"] --> CI["Build, unit and contract tests"]
  CI --> SEC["SCA, SBOM, secret scan"]
  SEC --> EV{"Offline evaluation<br/>and adversarial suite"}
  EV -->|"Below threshold"| BLK["Blocked"]
  EV -->|"Pass"| STG["Deploy to staging"]
  STG --> LT{"Load and integration tests"}
  LT -->|"Fail"| BLK
  LT -->|"Pass"| APR{"Release approval"}
  APR -->|"Approved"| CAN["Canary in production"]
  CAN --> MON{"Rollback triggers breached?"}
  MON -->|"Yes"| RB["Automatic rollback"]
  MON -->|"No"| GA["Progressive rollout to 100%"]
```
*Caption: Prompt and model changes go through the same evaluation, security, and canary gates as code changes.*

## 11b. Operational workflow: incident and rollback

```mermaid
%% Title: Operations — quality or cost incident
flowchart TD
  AL["Alert fires<br/>SLO, quality, or cost threshold"] --> TRI{"On-call triage<br/>per runbook"}
  TRI -->|"Quality regression"| FF["Disable feature flag<br/>or route to fallback"]
  TRI -->|"Cost spike"| TH["Throttle at gateway quota"]
  TRI -->|"Security event"| KS["Kill switch: disable tools,<br/>revoke credentials"]
  FF --> RV["Roll back prompt or model version"]
  TH --> INV["Investigate source"]
  KS --> IR["Security incident process"]
  RV --> PIR["Post-incident review<br/>update tests and runbook"]
  INV --> PIR
  IR --> PIR
```
*Caption: Each alert class maps to a pre-defined containment action, and every incident ends by updating the tests and runbooks.*
