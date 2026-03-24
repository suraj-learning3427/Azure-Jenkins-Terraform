# Jenkins CI/CD Setup Guide

## Prerequisites
- Jenkins running on the Azure VM (port 8080)
- Connected to the VM via Firezone VPN
- Your GitHub repo URL ready

---

## Step 1 — First Login

1. Open browser: `http://<jenkins-vm-private-ip>:8080`
2. SSH into the VM and get the initial password:
   ```bash
   sudo cat /jenkins/jenkins_home/secrets/initialAdminPassword
   ```
3. Paste the password into Jenkins, click **Continue**
4. Click **Install suggested plugins** and wait
5. Create your admin user, click **Save and Finish**

---

## Step 2 — Install Extra Plugins

Go to **Manage Jenkins → Plugins → Available plugins**, search and install:

| Plugin | Why |
|--------|-----|
| AnsiColor | Coloured Terraform output |
| Timestamper | Timestamps on every log line |
| Pipeline: Stage View | Visual pipeline stages |

Click **Install** then **Restart Jenkins**.

---

## Step 3 — Add Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials → Add Credential**

Add each one as **Secret text** with these exact IDs:

| Credential ID | Value |
|---------------|-------|
| `terraform-cloud-token` | Your Terraform Cloud API token (from app.terraform.io → User Settings → Tokens) |
| `azure-client-id` | Azure service principal App ID |
| `azure-client-secret` | Azure service principal password |
| `azure-subscription-id` | Your Azure subscription ID |
| `azure-tenant-id` | Your Azure tenant ID |

> To get Azure service principal values, run in Azure CLI:
> ```bash
> az ad sp create-for-rbac --name jenkins-sp --role Contributor \
>   --scopes /subscriptions/<your-subscription-id>
> ```
> This outputs `appId` (client-id), `password` (client-secret), `tenant` (tenant-id).

---

## Step 4 — Install Terraform on the Jenkins VM

SSH into the Jenkins VM and run:

```bash
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform version
```

---

## Step 5 — Create the Pipeline Job

1. Jenkins dashboard → **New Item**
2. Name it `azure-infrastructure`, choose **Pipeline**, click **OK**
3. Under **General**:
   - Tick **GitHub project**, enter your repo URL
4. Under **Build Triggers**:
   - Tick **GitHub hook trigger for GITScm polling**
5. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/<your-org>/<your-repo>.git`
   - Credentials: add your GitHub token if repo is private
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
6. Click **Save**

---

## Step 6 — Add GitHub Webhook

In your GitHub repo → **Settings → Webhooks → Add webhook**:

- Payload URL: `http://<jenkins-vm-private-ip>:8080/github-webhook/`
- Content type: `application/json`
- Events: **Just the push event**
- Click **Add webhook**

> Note: GitHub needs to reach your Jenkins URL. Since Jenkins is on a private IP,
> you either need to expose it via a public IP/Application Gateway, or trigger
> builds manually for now.

---

## Step 7 — Run Your First Build

1. Go to your `azure-infrastructure` job
2. Click **Build Now**
3. Click the build number → **Console Output** to watch it run

The pipeline will:
- Init and validate Terraform
- Run `terraform plan` and save the output
- On `main` branch: pause and ask for your approval before applying

---

## Pipeline Stages

```
Checkout → Init → Validate → Plan → [Approval] → Apply → Outputs
                                         ↑
                              Only on main branch
```

- **Plan** runs on every branch (safe — no changes made)
- **Approval** pauses and shows the plan summary — you click Apply
- **Apply** only runs after you approve

---

## Viewing Plan Output

After a Plan stage runs:
- Click the build → **Artifacts** → `plan.txt` to see the full Terraform plan
- After apply: `apply.txt` shows what was created/changed/destroyed
