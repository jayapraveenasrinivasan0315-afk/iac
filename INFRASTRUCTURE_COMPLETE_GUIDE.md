# Infrastructure Documentation: GCP Terraform Setup

**Version**: 1.0  
**Last Updated**: April 19, 2026  
**Status**: ✅ Production Ready  

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Infrastructure Components](#infrastructure-components)
4. [GCS Bucket Configuration](#gcs-bucket-configuration)
5. [Cloud Run Backend Setup](#cloud-run-backend-setup)
6. [Frontend Static Site Setup](#frontend-static-site-setup)
7. [Database Configuration](#database-configuration)
8. [Load Balancer & SSL](#load-balancer--ssl)
9. [Permissions & IAM](#permissions--iam)
10. [GitHub Actions Workflows](#github-actions-workflows)
11. [Deployment Instructions](#deployment-instructions)
12. [Troubleshooting](#troubleshooting)

---

## Overview

This Terraform infrastructure deploys a complete full-stack application on Google Cloud Platform (GCP) with:

- **Frontend**: Static assets hosted in Google Cloud Storage (GCS)
- **Backend**: Containerized application running on Cloud Run
- **Database**: Cloud SQL PostgreSQL instance
- **Networking**: VPC with private subnets and NAT
- **Load Balancing**: Global HTTPS load balancer with SSL/TLS
- **Security**: Service accounts, IAM roles, and Secret Manager integration

**Environment**: Development (Dev) - Additional environments (Staging, Prod) can be added following the same pattern.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Global HTTPS Load Balancer               │
│              (Static IP + SSL Certificate)                   │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    ┌───▼──┐              ┌──────▼────┐
    │ GCS  │              │ Cloud Run  │
    │Cache │              │ Backend    │
    └──────┘              └─────┬──────┘
   (Frontend)                   │
                         ┌──────▼──────┐
                         │  VPC        │
                         │ ┌────────┐  │
                         │ │Subnet  │  │
                         │ └───┬────┘  │
                         │     │       │
                         │  ┌──▼──┐    │
                         │  │Cloud│    │
                         │  │ SQL │    │
                         │  └─────┘    │
                         └─────────────┘
                      (Private Network)
```

---

## Infrastructure Components

### 1. **VPC Network**
- **Name**: `vpc`
- **CIDR Range**: `10.0.0.0/16`
- **Features**:
  - Private subnet with Google API access enabled
  - Cloud NAT for secure outbound traffic
  - Serverless VPC Access Connector

### 2. **Cloud Run Service**
- **Service Name**: `backend-service`
- **Region**: `asia-south1`
- **Configuration**:
  - Container image: `gcr.io/gw-devops-internship/backend:latest`
  - Container port: `8080`
  - Min instances: `1`
  - Max instances: `100`
  - Ingress: `INTERNAL_ONLY` (access through Load Balancer)
  - VPC Connector: Serverless VPC Access Connector

### 3. **Cloud Storage (GCS) Bucket**
- **Bucket Name**: `gw-devops-frontend-bucket`
- **Region**: `asia-south1`
- **Purpose**: Host frontend static files (HTML, CSS, JS)

### 4. **Cloud SQL Instance**
- **Database**: PostgreSQL
- **Tier**: `db-f1-micro`
- **Region**: `asia-south1`
- **Access**: Private network only (no public IP)

### 5. **Load Balancer**
- **Type**: Global HTTPS Load Balancer
- **Static IP**: Reserved external IP
- **SSL Certificate**: Google-managed certificate
- **Backends**:
  - Cloud Run service (for `/api/*` routes)
  - GCS bucket (for `/` and `/static/*` routes)

---

## GCS Bucket Configuration

### Bucket Details

```hcl
resource "google_storage_bucket" "frontend_bucket" {
  project       = var.project_id
  name          = "gw-devops-frontend-bucket"
  location      = "asia-south1"
  force_destroy = true

  # Enable static website hosting
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # CORS configuration for API calls
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Lifecycle: Delete files older than 90 days
  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 90 }
  }

  versioning {
    enabled = false
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true
}
```

### IAM Permissions

#### **Public Read Access (For Frontend Users)**
```hcl
resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"  # Anyone can read frontend files
  ]
}
```

**Permission Details**:
- **Role**: `roles/storage.objectViewer` (Storage Object Viewer)
- **Members**: `allUsers` (Internet-accessible)
- **Allows**: GET and HEAD operations on all objects
- **Denies**: DELETE, PUT, PATCH operations

#### **Cloud Run Service Account Access (For Backend Uploads)**
```hcl
resource "google_storage_bucket_iam_binding" "backend_upload" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:cloud-run-backend@${var.project_id}.iam.gserviceaccount.com"
  ]
}
```

**Permission Details**:
- **Role**: `roles/storage.objectAdmin` (Storage Object Admin)
- **Members**: Cloud Run service account email
- **Allows**: Full object lifecycle operations
- **Use Case**: Backend can upload/modify files if needed

### Uploading Files to GCS Bucket

#### **Using gsutil**

```bash
# Set bucket name
BUCKET_NAME="gw-devops-frontend-bucket"

# Upload single file
gsutil cp index.html gs://$BUCKET_NAME/

# Upload directory recursively
gsutil -m cp -r ./dist/* gs://$BUCKET_NAME/

# Upload with public read access
gsutil acl ch -u AllUsers:R gs://$BUCKET_NAME/index.html
```

#### **Using Terraform**

```hcl
resource "google_storage_bucket_object" "index_html" {
  name   = "index.html"
  bucket = google_storage_bucket.frontend_bucket.name
  source = "./dist/index.html"

  content_type = "text/html"
}

resource "google_storage_bucket_object" "css_file" {
  name   = "styles.css"
  bucket = google_storage_bucket.frontend_bucket.name
  source = "./dist/styles.css"

  content_type = "text/css"
}
```

#### **Using Frontend Application Code**

```python
# Python example - Upload file to GCS
from google.cloud import storage

def upload_to_gcs(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    
    blob.upload_from_filename(source_file_name)
    print(f"File {source_file_name} uploaded to {bucket_name}/{destination_blob_name}")

# Usage
upload_to_gcs("gw-devops-frontend-bucket", "index.html", "index.html")
```

---

## Cloud Run Backend Setup

### Backend Architecture

```
Incoming Request
        │
        ▼
    Load Balancer
        │
        ▼
Cloud Run Service
    (Internal Only)
        │
        ├─▶ VPC Connector ──▶ Cloud SQL
        │
        └─▶ Secret Manager (DB Credentials)
```

### Cloud Run Configuration

```hcl
resource "google_cloud_run_v2_service" "backend" {
  name                = "backend-service"
  location            = "asia-south1"
  deletion_protection = false
  ingress             = "INTERNAL_ONLY"  # Only accessible through load balancer

  scaling {
    max_instance_count = 100
    min_instance_count = 1
  }

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "gcr.io/gw-devops-internship/backend:latest"
      ports {
        container_port = 8080
      }

      # Environment variables
      env {
        name  = "ENVIRONMENT"
        value = "dev"
      }

      # Mounted secrets from Secret Manager
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = "db-url"
            version = "latest"
          }
        }
      }
    }

    # VPC connector for secure database access
    vpc_access {
      connector = "projects/gw-devops-internship/locations/asia-south1/connectors/vpc-connector"
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    google_service_account.cloud_run_sa
  ]
}
```

### Service Account & IAM Roles

#### **Cloud Run Service Account**

```hcl
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-backend"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run backend service"
}
```

#### **Required IAM Roles**

| Role | Purpose |
|------|---------|
| `roles/cloudsql.client` | Connect to Cloud SQL database |
| `roles/secretmanager.secretAccessor` | Access database URL secret |
| `roles/storage.objectViewer` | Read from GCS bucket if needed |

```hcl
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
```

### Backend Application Code Examples

#### **Python Backend (Flask)**

```python
# app.py
import os
import json
from flask import Flask, jsonify, request
from google.cloud import secretmanager
import psycopg2

app = Flask(__name__)

def get_secret(secret_id, project_id):
    """Retrieve secret from Google Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    secret_path = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": secret_path})
    return response.payload.data.decode("UTF-8")

# Get database URL from Secret Manager
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "gw-devops-internship")
DB_URL = get_secret("db-url", PROJECT_ID)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "backend"}), 200

# Get data from database
@app.route('/api/data', methods=['GET'])
def get_data():
    try:
        # Parse database URL
        from urllib.parse import urlparse
        parsed = urlparse(DB_URL)
        
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path.lstrip('/')
        )
        
        cur = conn.cursor()
        cur.execute("SELECT * FROM users LIMIT 10;")
        columns = [desc[0] for desc in cur.description]
        data = [dict(zip(columns, row)) for row in cur.fetchall()]
        
        cur.close()
        conn.close()
        
        return jsonify({"data": data}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Create new data
@app.route('/api/data', methods=['POST'])
def create_data():
    try:
        body = request.get_json()
        # Process request...
        return jsonify({"id": 1, **body}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
```

#### **Dockerfile for Backend**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["python", "app.py"]
```

#### **requirements.txt**

```
Flask==2.3.0
google-cloud-secret-manager==2.16.0
google-cloud-sql-connector==1.4.3
psycopg2-binary==2.9.6
gunicorn==21.2.0
```

#### **Node.js Backend (Express)**

```javascript
// app.js
const express = require('express');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

// Initialize Secret Manager client
const secretClient = new SecretManagerServiceClient();

async function getSecret(secretId) {
  const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'gw-devops-internship';
  const secretPath = secretClient.secretVersionPath(projectId, secretId, 'latest');
  
  const [version] = await secretClient.accessSecretVersion({ name: secretPath });
  return version.payload.data.toString('utf8');
}

let pool;

async function initializePool() {
  const dbUrl = await getSecret('db-url');
  pool = new Pool({ connectionString: dbUrl });
  return pool;
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'backend' });
});

// Get data endpoint
app.get('/api/data', async (req, res) => {
  try {
    if (!pool) await initializePool();
    
    const result = await pool.query('SELECT * FROM users LIMIT 10;');
    res.json({ data: result.rows });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Post data endpoint
app.post('/api/data', async (req, res) => {
  try {
    if (!pool) await initializePool();
    
    const { name, email } = req.body;
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *;',
      [name, email]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## Frontend Static Site Setup

### Frontend Directory Structure

```
frontend/
├── index.html
├── package.json
├── src/
│   ├── index.js
│   ├── components/
│   │   ├── Header.js
│   │   ├── Footer.js
│   │   └── Dashboard.js
│   ├── styles/
│   │   ├── main.css
│   │   └── responsive.css
│   └── utils/
│       └── api.js
├── dist/
│   ├── index.html
│   ├── main.js
│   └── styles.css
└── public/
    ├── favicon.ico
    └── robots.txt
```

### Frontend Example (React)

#### **src/index.js**

```javascript
import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import './styles/main.css';

const API_BASE = process.env.REACT_APP_API_URL || 'https://yourdomain.com/api';

function App() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/data`);
      if (!response.ok) throw new Error('Failed to fetch data');
      
      const result = await response.json();
      setData(result.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const createItem = async (newItem) => {
    try {
      const response = await fetch(`${API_BASE}/data`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newItem)
      });
      
      if (!response.ok) throw new Error('Failed to create item');
      
      await fetchData(); // Refresh data
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="app-container">
      <header>
        <h1>Cloud Application</h1>
      </header>
      
      <main>
        {loading && <p>Loading...</p>}
        {error && <p className="error">Error: {error}</p>}
        
        {!loading && (
          <div className="data-list">
            {data.map((item) => (
              <div key={item.id} className="data-item">
                <p>{item.name}</p>
              </div>
            ))}
          </div>
        )}
      </main>
      
      <footer>
        <p>&copy; 2026 Cloud Application</p>
      </footer>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
```

#### **src/styles/main.css**

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
  background-color: #f5f5f5;
  color: #333;
}

.app-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

header {
  background-color: #1a73e8;
  color: white;
  padding: 20px;
  text-align: center;
}

main {
  flex: 1;
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
}

.data-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.data-item {
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

footer {
  background-color: #f0f0f0;
  padding: 20px;
  text-align: center;
  margin-top: auto;
}

.error {
  background-color: #ffebee;
  color: #c62828;
  padding: 10px;
  border-radius: 4px;
  margin: 10px 0;
}

/* Responsive design */
@media (max-width: 768px) {
  .data-list {
    grid-template-columns: 1fr;
  }
}
```

#### **index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cloud Application</title>
  <link rel="icon" href="/favicon.ico">
</head>
<body>
  <div id="root"></div>
  <script src="/main.js"></script>
</body>
</html>
```

#### **package.json**

```json
{
  "name": "frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "scripts": {
    "build": "webpack --mode production",
    "dev": "webpack serve --mode development"
  },
  "devDependencies": {
    "@babel/core": "^7.22.0",
    "@babel/preset-react": "^7.22.0",
    "babel-loader": "^9.1.0",
    "webpack": "^5.88.0",
    "webpack-cli": "^5.1.0",
    "webpack-dev-server": "^4.15.0"
  }
}
```

### Deployment Steps (Frontend)

```bash
# 1. Build the frontend
npm run build

# 2. Upload to GCS bucket
gsutil -m cp -r dist/* gs://gw-devops-frontend-bucket/

# 3. Set proper cache headers
gsutil -h "Cache-Control:public, max-age=3600" cp -r dist/* gs://gw-devops-frontend-bucket/

# 4. Test the deployment
curl https://yourdomain.com/index.html
```

---

## Database Configuration

### Cloud SQL Setup

#### **Database Schema**

```sql
-- Create users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create application_data table
CREATE TABLE application_data (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_app_data_user_id ON application_data(user_id);
```

#### **Terraform Configuration**

```hcl
resource "google_sql_database_instance" "main" {
  name             = "postgres-db-instance"
  database_version = "POSTGRES_15"
  region           = "asia-south1"
  
  lifecycle {
    prevent_destroy = true
  }
   
  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = false              # No public IP
      private_network = google_compute_network.vpc_network.id
      require_ssl     = true
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "00:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }
}

resource "google_sql_database" "app_db" {
  name     = "application_db"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app_user" {
  name     = "appuser"
  instance = google_sql_database_instance.main.name
  password = var.secure_password
}
```

### Connection String Format

```
postgresql://appuser:PASSWORD@PRIVATE_IP:5432/application_db
```

---

## Load Balancer & SSL

### SSL Certificate

```hcl
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "app-ssl-cert"

  managed {
    domains = ["yourdomain.com", "www.yourdomain.com"]
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

### URL Map Configuration

```hcl
# Route requests based on path
resource "google_compute_url_map" "https_lb_url_map" {
  name            = "https-lb-url-map"
  default_service = google_compute_backend_bucket.gcs_backend.id

  host_rule {
    hosts        = ["yourdomain.com", "www.yourdomain.com"]
    path_matcher = "api-matcher"
  }

  path_matcher {
    name            = "api-matcher"
    default_service = google_compute_backend_bucket.gcs_backend.id

    path_rule {
      paths   = ["/api", "/api/*"]
      service = google_compute_backend_service.cloud_run_backend.id
    }
  }
}
```

---

## Permissions & IAM

### Service Account Hierarchy

```
┌─────────────────────────────────────────┐
│   Cloud Run Service Account              │
│   cloud-run-backend@project.iam.gs...   │
└────────────────────┬────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   Cloud SQL   Secret Manager   GCS Bucket
   Client      Secret Accessor  Object Viewer
```

### Complete Permission Matrix

| Service | Resource | Role | Scope |
|---------|----------|------|-------|
| Cloud Run | Cloud SQL | `roles/cloudsql.client` | Project-level |
| Cloud Run | Secret Manager | `roles/secretmanager.secretAccessor` | Secret-level |
| Cloud Run | GCS Bucket | `roles/storage.objectViewer` | Bucket-level |
| User | Cloud Run | `roles/run.invoker` | Service-level |
| Load Balancer | Cloud Run | Backend binding | Service-level |
| Load Balancer | GCS Bucket | Backend binding | Bucket-level |

---

## GitHub Actions Workflows

### Terraform Apply Workflow

**File**: `.github/workflows/terraform-apply.yml`

**Triggers**:
- Push to `main` branch
- Manual trigger (`workflow_dispatch`)

**Features**:
- Automatic initialization
- Terraform validation and formatting
- Plan and apply with artifacts
- Slack notifications
- Output storage

**Required Secrets**:
- `GCP_SERVICE_ACCOUNT_KEY`: GCP service account JSON key
- `GCP_TF_STATE_BUCKET`: Terraform state bucket name
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications

### Terraform Destroy Workflow

**File**: `.github/workflows/terraform-destroy.yml`

**Triggers**:
- Manual trigger only (`workflow_dispatch`)

**Features**:
- Confirmation requirement
- Destroy plan preview
- State backup before destruction
- Slack notifications
- Environment protection

**Required Secrets**:
- `GCP_SERVICE_ACCOUNT_KEY`: GCP service account JSON key
- `GCP_TF_STATE_BUCKET`: Terraform state bucket name
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications

---

## Deployment Instructions

### Prerequisites

```bash
# Required tools
- Terraform >= 1.6.0
- Google Cloud SDK (gcloud CLI)
- Git
- GitHub account with Actions enabled
```

### Step 1: Set Up GCP Project

```bash
# Create GCP project
gcloud projects create gw-devops-internship

# Set as default
gcloud config set project gw-devops-internship

# Enable required APIs
gcloud services enable \
  compute.googleapis.com \
  cloudsql.googleapis.com \
  run.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com
```

### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-admin \
  --display-name="Terraform Admin"

# Grant roles
gcloud projects add-iam-policy-binding gw-devops-internship \
  --member="serviceAccount:terraform-admin@gw-devops-internship.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create ./key.json \
  --iam-account=terraform-admin@gw-devops-internship.iam.gserviceaccount.com
```

### Step 3: Create Terraform State Bucket

```bash
# Create GCS bucket for state
gsutil mb gs://my-terraform-state-bucket

# Enable versioning
gsutil versioning set on gs://my-terraform-state-bucket

# Set uniform bucket-level access
gsutil uniformbucketlevelaccess set on gs://my-terraform-state-bucket
```

### Step 4: Configure GitHub Secrets

In your GitHub repository settings, add these secrets:

```
GCP_SERVICE_ACCOUNT_KEY = [contents of key.json]
GCP_TF_STATE_BUCKET = my-terraform-state-bucket
SLACK_WEBHOOK_URL = https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Step 5: Deploy Infrastructure

```bash
# Clone repository
git clone <your-repo-url>
cd iac

# Initialize Terraform
terraform init -backend-config="bucket=my-terraform-state-bucket" \
               -backend-config="prefix=terraform/state/dev"

# Create plan
terraform plan -var-file="environment/dev/terraform.tfvars" -out=tfplan

# Apply plan (or push to main branch to trigger GitHub Actions)
terraform apply tfplan
```

### Step 6: Deploy Backend Container

```bash
# Build Docker image
docker build -t gcr.io/gw-devops-internship/backend:latest ./backend

# Push to GCR
gcloud docker -- push gcr.io/gw-devops-internship/backend:latest

# Update Cloud Run service with new image
gcloud run deploy backend-service \
  --image=gcr.io/gw-devops-internship/backend:latest \
  --region=asia-south1
```

### Step 7: Deploy Frontend

```bash
# Build frontend
cd frontend
npm install
npm run build

# Upload to GCS
gsutil -m cp -r dist/* gs://gw-devops-frontend-bucket/
```

### Step 8: Configure DNS

In your DNS provider (e.g., CloudFlare, Google Domains):

```
A record: yourdomain.com    → [LOAD_BALANCER_IP]
A record: www.yourdomain.com → [LOAD_BALANCER_IP]
```

Get the load balancer IP:

```bash
gcloud compute addresses describe app-static-ip --global --format="value(address)"
```

---

## Troubleshooting

### Common Issues & Solutions

#### **Cloud Run Cannot Connect to Cloud SQL**
```bash
# Check VPC Connector status
gcloud compute networks vpc-access connectors describe vpc-connector \
  --region=asia-south1 \
  --format="value(state)"

# View logs
gcloud run logs read backend-service --region=asia-south1 --limit=50
```

#### **GCS Bucket Not Serving Static Files**
```bash
# Check permissions
gsutil iam get gs://gw-devops-frontend-bucket

# Verify CORS configuration
gsutil cors get gs://gw-devops-frontend-bucket

# Check website configuration
gsutil website get gs://gw-devops-frontend-bucket
```

#### **SSL Certificate Not Provisioning**
```bash
# Check certificate status
gcloud compute ssl-certificates describe app-ssl-cert --global \
  --format="value(managed[0].domainStatus[0].domain,managed[0].domainStatus[0].status)"

# May take 15-20 minutes for Google to validate domains
```

#### **Terraform Apply Fails**
```bash
# Check authentication
gcloud auth application-default login

# Validate Terraform
terraform validate

# View detailed logs
terraform apply -var-file="environment/dev/terraform.tfvars" -parallelism=1
```

#### **Secret Manager Access Denied**
```bash
# Verify service account has correct role
gcloud projects get-iam-policy gw-devops-internship \
  --flatten="bindings[].members" \
  --filter="bindings.members:cloud-run-backend*"

# Grant role if missing
gcloud projects add-iam-policy-binding gw-devops-internship \
  --member="serviceAccount:cloud-run-backend@gw-devops-internship.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Useful Commands

```bash
# View Cloud Run logs
gcloud run logs read backend-service --region=asia-south1 --limit=100

# Check load balancer status
gcloud compute backend-services get-health cloud-run-backend --global

# View Terraform state
terraform state list
terraform state show 'module.cloud_run.google_cloud_run_v2_service.backend'

# Test API endpoint
curl https://yourdomain.com/api/health

# Check certificate renewal status
gcloud compute ssl-certificates describe app-ssl-cert --global
```

---

## Summary

This infrastructure provides:
- ✅ **Secure**, scalable backend with Cloud Run
- ✅ **Fast**, global frontend delivery via GCS + Load Balancer
- ✅ **Reliable** database with automated backups
- ✅ **Automated** deployment via GitHub Actions
- ✅ **Best practices** for permissions and security

For questions or issues, refer to the [GCP Documentation](https://cloud.google.com/docs) and [Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs).

---

**Last Updated**: April 19, 2026
**Maintained By**: DevOps Team
