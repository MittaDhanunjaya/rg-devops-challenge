# Recogizer DevOps/Cloud Engineer Technical Challenge

## Introduction:
The Documentation guides you to configure Monitoring solution for dockerized applications using Prometheus & Grafana. Also, An overview of the required dashboards to visualise and monitor via Grafana. At last, alerts are created wherever required.

## Pre-requisites:
1. Docker & Docker Compose installed on your system. 
2. Update the necessary packages
3. Edit the Docker configuration file and replace credsStore to credStore in ~/.docker/config.json (I got an error while using Docker Compose for the first time).

This documentation will be in two steps:
1. Setting up monitoring solution by using Prometheus & Grafana for our environment.
2. Building Dashboards and creating alerts wherever we feel necessary.

# Step 1:
Before configuring Prometheus & Grafana, we have to make a few adjustments to the Caddyfile configuration.
Since, Caddy should expose its admin interface on port 2019, we have to explicitly mention the admin:2019 in the configuration file. This endpoint allows to interact with the Caddy server, which can provide us the metrics which we need. 

```bash
{
	servers {
    	metrics
    }
    admin :2019
}

:80 {
  reverse_proxy http-dummy-service:8080
}
```

For ensuring consistency, a docker network ("backend") is applied to all the services in the compose file.


## Configuring Prometheus:

Prometheus is an open-source monitoring and alerting tool that is designed for reliability and scalability. It is primarily used to collect and store time-series data (metrics) from various sources, such as applications, services, and systems.
1. Install Prometheus on our server. 
2. Configure Prometheus to scrape metrics from your desired targets

## Configuring Grafana:

Grafana is an open-source visualization and monitoring platform that allows users to create, explore, and share dashboards and visualizations of time-series data. It supports various data sources, including Prometheus, allowing users to visualize metrics collected by Prometheus and other monitoring systems.
1. Install Grafana on our server.
2. Configure Grafana to connect to Prometheus as a data source.


## Additional tools/configurations:

1. Install Prometheus node-exporter for collecting all the system level metrics (CPU, memory, disk, etc.) from the host machine and makes them available for Prometheus..
2. Install push gateway for collecting short-lived service level batch jobs to an intermediate jobs which prometheus can scrape.

I am using Prometheus & Grafana official docker images from dockerhub in our docker-compose file along with volumes and some necessary environmental variables as you can see below:

```bash
#docker-compose.yaml
version: '3'
  
services:
  http-dummy-service:
    container_name: http-dummy
    image: rgjcastrillon/http-dummy-service:0.1.0
    ports:
      - 80:8080
    networks:
      - backend
  caddy:
    image: caddy:latest
    ports:
      - 8080:80
      - 2019:2019
    networks:
      - backend
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile

  prometheus:
    image: prom/prometheus:latest
    ports:
      - 9090:9090
    networks:
      - backend
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: unless-stopped
    ports:
      - 3000:3000
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=password
      - GF_SMTP_ENABLED=true
      - GF_SMTP_HOST=smtp.gmail.com:587
      - GF_SMTP_USER=someone@gmail.com
      - GF_SMTP_PASSWORD=<app_password>
      - GF_SMTP_FROM_ADDRESS=someone@gmail.com
      - GF_SMTP_TLS_ENABLED=true
      - GF_SMTP_SKIP_VERIFY=true  # Note: This is needed if you're using Gmail 
    networks:
      - backend
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/' 
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    expose:
      - 9100
    networks:
      - backend
  pushgateway:
    image: prom/pushgateway
    container_name: pushgateway
    restart: unless-stopped
    ports:
      - 9091:9091
    networks:
      - backend

networks:
  backend:
```
Prometheus.yml:

This file configures Prometheus to collect metrics from different sources:

1. Global Settings: Defines the global scrape interval, indicating how often Prometheus should scrape metrics from configured targets (every 5 seconds in this case).
2. Scrape Configurations: Specifies the jobs Prometheus should scrape metrics from:
3. caddy: Scrapes metrics exposed by the Caddy server on port 2019.
4. node-exporter: Collects system-level metrics from Node Exporter running on port 9100.
5. pushgateway: Gathers metrics pushed by batch jobs to the Pushgateway on port 9091.

```bash
#prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "caddy"
    static_configs:
      - targets: ["caddy:2019"]
  
  - job_name: “node-exporter”
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "pushgateway"
    static_configs:
      - targets: ["pushgateway:9091"]
```
Once, all the changes to the docker-compose, Caddyfile, and a new prometheus configuration has done, run the docker compose file by using "docker-compose up -d"
This command will download the required Docker images and start the containers defined in the docker-compose.yml file in detached mode (-d).

![docker-compose-up](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/1216b55d-c3c1-4161-943f-b9e9e4ca80fc)

Check your docker ps to check all the containers are up & running. 

![docker_ps](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/0c4b699e-bd1b-4293-a0cb-0903942c5861)

Once the containers are up and running, you can access prometheus via your web browser at http://localhost:9090 and grafana at http://localhost:3000.

You can check the below screenshots for prometheus & grafana webpages:

![prometheus_web_page](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/b2dda28a-343b-413d-8d20-474f333e8823)

![grafana_web_page](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/f32b953a-cff0-41b6-a1b4-11afb79a66e7)


# Step 2:

Our Second step is to create dashboards based on our requirements. But before creating dashboards, we have to add prometheus as a data source in grafana
After logging in to Grafana, add Prometheus as a data source:
Click on the gear icon (Connections) on the left sidebar, then select "Data Sources".
Click on "Add data source", select Prometheus, and configure it with the URL http://prometheus:9090.

![Screenshot 2024-03-10 at 19 54 58](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/95f1b163-32ed-4a5e-95a7-e1b82d8897ef)

## Dashboards:

I created multiple dashboards based on the monitoring requirements. They are:

### 1. CPU Usage Dashboards

This dashboard provides insights into CPU utilization across servers. It helps in monitoring the overall system load and identifying potential performance bottlenecks.

```bash
PromQL query: 100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle", instance="node-exporter:9100"}[$__rate_interval])))
```
### 2. Memory Usage Dashboards

This dashboard shows memory utilization across servers, helping to track memory usage trends and detect memory leaks.

```bash
PromQL query: (1 - ((node_memory_MemFree_bytes{instance="node-exporter:9100",job="node-exporter"} + node_memory_Buffers_bytes{instance="node-exporter:9100",job="node-exporter"} + node_memory_Cached_bytes{instance="node-exporter:9100",job="node-exporter"}) / node_memory_MemTotal_bytes{instance="node-exporter:9100", job="node-exporter"})) * 100
```

### 3. Disk Space Dashboards

Monitors disk space usage across servers to prevent potential outages due to disk space exhaustion.

```bash
(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100
```

### 4. Network Traffic Dashboards

Displays incoming and outgoing network traffic, aiding in identifying network congestion or abnormal traffic patterns.

```bash
sum(irate(node_network_receive_bytes_total{device!="lo"}[5m]) + irate(node_network_transmit_bytes_total{device!="lo"}[5m])) by (device)
```

### 5. Caddy Web Service Health Dashboard

Displays whether the Caddy Service is up & running.

```bash
caddy_reverse_proxy_upstreams_healthy
```

### 6. Http Service Health Dashboard

Displays whether the Http service is up & running.

```bash
sum(rate(promhttp_metric_handler_requests_total{code!="200",instance="caddy:2019"}[10m]))
```

### 7. Latency Dashboard

Latency refers to the time it takes for a request to be processed from the moment it is sent until a response is received. 

```bash
caddy_http_response_duration_seconds_sum{code="200",instance="caddy:2019"}*1000
```

### 8. Client & Server Errors Dashboards

Client and server errors dashboards are essential tools for monitoring the health and performance of web services, APIs, or any networked applications. They track and visualize error rates and types occurring during interactions between clients (e.g., web browsers, mobile apps) and servers. These dashboards help teams quickly identify issues, diagnose root causes, and maintain service reliability according to Service Level Agreements (SLAs).

```bash
sum(caddy_http_request_duration_seconds_count{code=~"4.*"})
sum(caddy_http_request_duration_seconds_count{code=~"5.*"})
```

![Screenshot 2024-03-10 at 14 30 52](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/21b0fad9-489d-4c86-9444-0210701b6fe3)

![Screenshot 2024-03-10 at 14 31 28](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/0bde130a-552e-4108-b880-c8540aa3eb56)

## Alerts

After creating the dashboards, the next important step is to create an alert rules.

Grafana alerts are a powerful feature that allows us to set up notifications based on the data visualized in Grafana dashboards. Alerts help us stay informed about changes or anomalies in our metrics and take timely actions to address them. Here's how Grafana alerts work:

### Setting Up Grafana Alerts:
Define Alert Conditions: Specify conditions that trigger an alert. Set thresholds, expressions, or aggregations based on our metrics. 

Configure Notification Channels: Choose how we want to be notified when an alert is triggered. Grafana supports various notification channels, including email, Slack, PagerDuty, and more. I used Gmail as a notification channel and i configured our grafana accordingly. 

```bash
environment:
      - GF_SECURITY_ADMIN_PASSWORD=password
      - GF_SMTP_ENABLED=true
      - GF_SMTP_HOST=smtp.gmail.com:587
      - GF_SMTP_USER=someone@gmail.com
      - GF_SMTP_PASSWORD=<app-password>
      - GF_SMTP_FROM_ADDRESS=someone@gmail.com
      - GF_SMTP_TLS_ENABLED=true
      - GF_SMTP_SKIP_VERIFY=true  # Note: This is needed if you're using Gmail 
```
In the above script, we have to provide an email address from which we have to send our alerts, password is our gmail app password. we can set a password under this link (https://myaccount.google.com/apppasswords).

Create Alert Rules: Define alert rules in Grafana's alerting interface. This involves selecting the data source, specifying the metric, setting conditions, and choosing the notification channel(s).

Test Alerts: Before deploying alerts in production, it's essential to test them to ensure they work as expected. I tried manually triggering alerts and using Grafana's built-in testing functionality to verify that notifications are sent correctly.

### Test Alert:

![Screenshot 2024-03-10 at 20 27 06](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/aee76baa-25d1-4bcf-82db-bf59395923b4)

### Firing Alert:

![Screenshot 2024-03-10 at 20 28 51](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/901c24b6-5f31-4783-9441-bcdc53501609)

### Resolved Alert:

![Screenshot 2024-03-10 at 20 29 16](https://github.com/MittaDhanunjaya/kubernetes-with-prometheus/assets/23475308/d7db1de9-e42c-41d3-8cbd-9d41bc238872)

Overall, I have created alert rules for all the dashboards created in Grafana. I have included the script for creating an alert rule is included in the monitoring/Grafana/Alert-Rules folder

Description of alerts:

High CPU Usage Alert:

Description: Alerts when CPU usage exceeds 90% for more than 20 seconds.
Threshold: CPU > 90%
Condition: 100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle", instance="node-exporter:9100"}[$__rate_interval]))) > 90 for 20s

Low Disk Space Alert:

Description: Alerts when available disk space falls below 15%.
Threshold: disk_space > 85
Condition: (node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_free_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100 > 85

High Memory Usage Alert:

Description: Alerts when memory usage exceeds 85%.
Threshold: memory_usage > 85
Condition: (1 - ((node_memory_MemFree_bytes{instance="node-exporter:9100",job="node-exporter"} + node_memory_Buffers_bytes{instance="node-exporter:9100",job="node-exporter"} + node_memory_Cached_bytes{instance="node-exporter:9100",job="node-exporter"}) / node_memory_MemTotal_bytes{instance="node-exporter:9100", job="node-exporter"})) * 100 > 85%

Network Traffic Spike Alert:

Description: Alerts when network traffic exceeds the predefined threshold.
Threshold: network_traffic > 100MB
Condition: sum(irate(node_network_receive_bytes_total{device!="lo"}[5m]) + irate(node_network_transmit_bytes_total{device!="lo"}[5m])) by (device) > 100000000

Caddy Web Service Health Alert:

Description: Alerts when caddy reverse proxy upstreams health is down or goes to 0.
Condition: caddy_reverse_proxy_upstreams_healthy < 1

Http Service Health Alert:

Description: Alerts when promhttp metric handler requests have other than 200 code.
Condition:  sum(rate(promhttp_metric_handler_requests_total{code!="200",instance="caddy:2019"}[10m])) > 0

High Latency Alert:

Description: Normally, according to SLA, we have to make sure the latency is under 10ms or something under.
Threshold: Latency > 10 ms
Condition: caddy_http_response_duration_seconds_sum{code="200",instance="caddy:2019"}*1000 > 10 ms


Client & Server Errors Alerts:
Description: Alert when the response code is either 4** or 5**.
Condition: sum(caddy_http_request_duration_seconds_count{code=~"4.*"}) > 1
sum(caddy_http_request_duration_seconds_count{code=~"5.*"}) > 1

## Optional Improvements:

### 1. Migration to Kubernetes:

Deployment Manifests: Convert Docker Compose services into Kubernetes deployment manifests (Deployment or StatefulSet) and service manifests (Service) for container orchestration.

Volumes: Use Kubernetes PersistentVolumes (PVs) and PersistentVolumeClaims (PVCs) for managing storage instead of Docker volumes. This provides more flexibility and allows for dynamic provisioning.

Service Discovery: Utilize Kubernetes' built-in service discovery mechanisms, such as DNS-based service discovery or service discovery via environment variables, instead of relying on container names as in Docker Compose.

Resource Management: Define resource requests and limits for CPU and memory in your Kubernetes deployment manifests to ensure efficient resource allocation and better performance isolation.

### 2. Secure Credential Management:

Secure Credential Management with HashiCorp Vault:
Vault Integration: Utilize HashiCorp Vault for managing sensitive information such as passwords, API keys, and TLS certificates. Vault provides centralized, dynamic secrets management with robust encryption and access control features.

Dynamic Secrets: Leverage Vault's capability to generate dynamic secrets on-demand, which have short-lived lifetimes and are automatically revoked after use. This reduces the risk of credentials being compromised and improves overall security posture.
