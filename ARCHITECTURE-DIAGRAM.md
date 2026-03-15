# Multi-Cloud VPN-Protected SSO-Enabled Jenkins Platform
## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    DEVELOPER WORKSTATION                                             │
│                                                                                                      │
│   ┌─────────────┐    git push     ┌──────────────────┐                                              │
│   │   VS Code   │ ─────────────►  │  GitHub Repo     │                                              │
│   │  Terraform  │                 │  ┌─────────────┐ │                                              │
│   │    Code     │                 │  │  /gcp/      │ │                                              │
│   └─────────────┘                 │  │  /azure/    │ │                                              │
│                                   │  └─────────────┘ │                                              │
│   ┌─────────────┐                 └────────┬─────────┘                                              │
│   │  Firezone   │                          │ webhook trigger                                         │
│   │  VPN Client │                          ▼                                                        │
│   └──────┬──────┘                 ┌──────────────────┐                                              │
│          │ WireGuard tunnel        │  Terraform Cloud  │                                              │
│          │                        │  ┌─────────────┐ │                                              │
└──────────┼────────────────────────┤  │  Workspace  │ │                                              │
           │                        │  │  GCP / AZ   │ │                                              │
           │                        │  ├─────────────┤ │                                              │
           │                        │  │ auto plan   │ │                                              │
           │                        │  │ manual appr │ │                                              │
           │                        │  │ auto apply  │ │                                              │
           │                        │  ├─────────────┤ │                                              │
           │                        │  │  Variables  │ │                                              │
           │                        │  │ GCP SA key  │ │                                              │
           │                        │  │ AZ SP creds │ │                                              │
           │                        │  │ FZ tokens   │ │                                              │
           │                        │  └─────────────┘ │                                              │
           │                        └────────┬─────────┘                                              │
           │                                 │ terraform apply                                         │
           │                    ┌────────────┴────────────┐                                           │
           │                    │                         │                                            │
           │                    ▼                         ▼                                            │
           │                                                                                           │
┌──────────┼──────────────────────────┐   ┌──────────────────────────────────────┐                   │
│  AZURE   │                          │   │  GOOGLE CLOUD PLATFORM (GCP)         │                   │
│          │                          │   │                                       │                   │
│  ┌───────┴──────────────────────┐   │   │  ┌───────────────────────────────┐   │                   │
│  │  VNet: 192.168.0.0/16        │   │   │  │  VPC: 10.0.0.0/16             │   │                   │
│  │                              │   │   │  │                               │   │                   │
│  │  ┌─────────────────────┐     │   │   │  │  ┌────────────────────────┐   │   │                   │
│  │  │  subnet-vpn          │     │   │   │  │  │  subnet-vpn            │   │   │                   │
│  │  │  192.168.3.0/24      │     │   │   │  │  │  10.0.3.0/24           │   │   │                   │
│  │  │                      │     │   │   │  │  │                        │   │   │                   │
│  │  │  ┌────────────────┐  │     │   │   │  │  │  ┌──────────────────┐  │   │   │                   │
│  │  │  │ Firezone GW VM │◄─┼─────┼───┼───┼──┼──┼──┤ Firezone GW VM   │  │   │   │                   │
│  │  │  │ (public IP)    │  │     │   │   │  │  │  │ (public IP)      │  │   │   │                   │
│  │  │  │ Standard_B2s   │  │     │   │   │  │  │  │ e2-medium        │  │   │   │                   │
│  │  │  │ WireGuard:51820│  │     │   │   │  │  │  │ WireGuard:51820  │  │   │   │                   │
│  │  │  │ Docker+Firezone│  │     │   │   │  │  │  │ Docker+Firezone  │  │   │   │                   │
│  │  │  └────────────────┘  │     │   │   │  │  │  └──────────────────┘  │   │   │                   │
│  │  └─────────────────────┘     │   │   │  │  └────────────────────────┘   │   │                   │
│  │                              │   │   │  │                               │   │                   │
│  │  ┌─────────────────────┐     │   │   │  │  ┌────────────────────────┐   │   │                   │
│  │  │  subnet-jenkins      │     │   │   │  │  │  subnet-jenkins        │   │   │                   │
│  │  │  192.168.0.0/24      │     │   │   │  │  │  10.0.0.0/24           │   │   │                   │
│  │  │                      │     │   │   │  │  │                        │   │   │                   │
│  │  │  ┌────────────────┐  │     │   │   │  │  │  ┌──────────────────┐  │   │   │                   │
│  │  │  │  Jenkins VM    │  │     │   │   │  │  │  │   Jenkins VM     │  │   │   │                   │
│  │  │  │  (NO public IP)│  │     │   │   │  │  │  │  (NO public IP)  │  │   │   │                   │
│  │  │  │  Standard_D2s  │  │     │   │   │  │  │  │  e2-standard-2   │  │   │   │                   │
│  │  │  │  Port 8080     │  │     │   │   │  │  │  │  Port 8080       │  │   │   │                   │
│  │  │  │  SAML/OIDC SSO │  │     │   │   │  │  │  │  SAML/OIDC SSO  │  │   │   │                   │
│  │  │  └────────────────┘  │     │   │   │  │  │  └──────────────────┘  │   │   │                   │
│  │  └─────────────────────┘     │   │   │  │  └────────────────────────┘   │   │                   │
│  │                              │   │   │  │                               │   │                   │
│  │  ┌──────────────────────┐    │   │   │  │  ┌────────────────────────┐   │   │                   │
│  │  │  Azure Private DNS   │    │   │   │  │  │  GCP Cloud DNS         │   │   │                   │
│  │  │  learningmyway.space │    │   │   │  │  │  internal.company      │   │   │                   │
│  │  │  jenkins-az.internal │    │   │   │  │  │  jenkins-gcp.internal  │   │   │                   │
│  │  └──────────────────────┘    │   │   │  │  └────────────────────────┘   │   │                   │
│  └──────────────────────────────┘   │   │  └───────────────────────────────┘   │                   │
│                                     │   │                                       │                   │
│  NSG Rules:                         │   │  Firewall Rules:                      │                   │
│  - Allow 51820/UDP (WireGuard)      │   │  - Allow 51820/UDP (WireGuard)        │                   │
│  - Allow 22/TCP (SSH, mgmt only)    │   │  - Allow 22/TCP (SSH, mgmt only)      │                   │
│  - Block 8080 from internet         │   │  - Block 8080 from internet           │                   │
└─────────────────────────────────────┘   └───────────────────────────────────────┘                   │
                                                                                                       │
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┘
│                          IDENTITY & SSO LAYER
│
│  ┌──────────────────────────────────────────────────────────────────────────────┐
│  │                    Microsoft Entra ID (Azure AD)  ← Primary IdP              │
│  │                                                                               │
│  │   ┌─────────────────────────┐      ┌──────────────────────────────────────┐  │
│  │   │  App Registration       │      │  Workload Identity Federation        │  │
│  │   │  Jenkins-Azure (SAML)   │      │  Azure AD ──────────────► GCP        │  │
│  │   │  Jenkins-GCP   (SAML)   │      │  (already configured)                │  │
│  │   └─────────────────────────┘      └──────────────────────────────────────┘  │
│  │                                                                               │
│  │   SSO Flow:                                                                   │
│  │   User → Jenkins URL → Redirect to Entra ID → Login → SAML assertion         │
│  │        → Jenkins grants access (both GCP and Azure instances)                 │
│  └──────────────────────────────────────────────────────────────────────────────┘
│
└──────────────────────────────────────────────────────────────────────────────────────────────────────

```

---

## End-to-End Flow

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER CI/CD WORKFLOW                                  │
│                                                                                   │
│  1. Dev writes Terraform in VS Code                                               │
│         │                                                                         │
│         ▼                                                                         │
│  2. git push → GitHub (gcp/ or azure/ folder)                                    │
│         │                                                                         │
│         ▼  webhook                                                                │
│  3. Terraform Cloud detects change → runs terraform plan                          │
│         │                                                                         │
│         ▼                                                                         │
│  4. Plan shown in TF Cloud UI → Manual approval required                          │
│         │                                                                         │
│         ▼  approved                                                               │
│  5. Terraform Cloud runs terraform apply                                          │
│         │                                                                         │
│         ├──────────────────────────────────────────────────────┐                 │
│         ▼                                                       ▼                 │
│  GCP Workspace                                         Azure Workspace            │
│  - GCP SA key (TF Cloud var)                          - AZ SP creds (TF var)     │
│  - Firezone token (TF Cloud var)                      - Firezone token (TF var)  │
│  - State stored in TF Cloud                           - State stored in TF Cloud │
│                                                                                   │
└──────────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────────┐
│                         USER VPN + JENKINS ACCESS FLOW                            │
│                                                                                   │
│  1. User opens Firezone client on laptop                                          │
│         │                                                                         │
│         ▼                                                                         │
│  2. Connects to Firezone portal → authenticates via Entra ID SSO                 │
│         │                                                                         │
│         ▼                                                                         │
│  3. WireGuard tunnel established to nearest Firezone Gateway                     │
│         │                                                                         │
│         ├──────────────────────────────────────────────────────┐                 │
│         ▼                                                       ▼                 │
│  4a. Browse jenkins-az.internal.company:8080          4b. Browse jenkins-gcp.internal.company:8080  │
│         │                                                       │                 │
│         ▼                                                       ▼                 │
│  5. Jenkins redirects to Entra ID SAML login                                     │
│         │                                                                         │
│         ▼                                                                         │
│  6. User logs in once → access granted to both Jenkins instances                 │
│                                                                                   │
│  ✗ Without VPN: jenkins-az/gcp.internal.company → NOT reachable                 │
│                                                                                   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## Terraform Repo Structure

```
repo/
├── gcp/
│   ├── main.tf              # GCP VPC, subnets, firewall rules
│   ├── variables.tf
│   ├── terraform.tfvars     # non-sensitive vars (sensitive in TF Cloud)
│   ├── outputs.tf
│   └── modules/
│       ├── firezone-gateway/ # GCP Firezone VM module
│       └── jenkins-vm/       # GCP Jenkins private VM module
│
├── azure/
│   ├── main.tf              # Azure VNet, subnets, NSGs
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── modules/
│       ├── firezone-gateway/ # Azure Firezone VM module (existing)
│       └── jenkins-vm/       # Azure Jenkins private VM module
│
└── README.md
```

---

## Terraform Cloud Workspaces

| Workspace       | Cloud | Trigger         | Variables                              |
|-----------------|-------|-----------------|----------------------------------------|
| `jenkins-gcp`   | GCP   | push to `gcp/`  | `GOOGLE_CREDENTIALS`, `firezone_token`, `firezone_id` |
| `jenkins-azure` | Azure | push to `azure/`| `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `firezone_token`, `firezone_id` |

---

## Key Design Decisions

| Component         | Choice                        | Reason                                      |
|-------------------|-------------------------------|---------------------------------------------|
| Primary IdP       | Microsoft Entra ID            | Already federated to GCP via WIF            |
| VPN               | Firezone (WireGuard)          | Existing modules, lightweight               |
| Jenkins SSO       | SAML plugin                   | Supported by Entra ID natively              |
| State backend     | Terraform Cloud               | No local tfstate, team collaboration        |
| DNS (Azure)       | Azure Private DNS             | jenkins-az.internal.company                 |
| DNS (GCP)         | Cloud DNS private zone        | jenkins-gcp.internal.company                |
| Jenkins access    | VPN-only (no public IP)       | Security requirement                        |
