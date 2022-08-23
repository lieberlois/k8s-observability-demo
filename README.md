# Observability in Kubernetes

This repository demonstrates, how observability of distributed deployments in Kubernetes can be achieved. The following technologies are being used to implement this observability.

## Logging

Logs from applications are gathered as Kubernetes logfiles at `/var/log/containers/*.log`. **Fluent Bit** is running as a DaemonSet (a pod on every node) as is responsible for reading the logfiles and posting the data to the **OpenSearch** backend ("log shipping"), which stores and indexes the logs. Using an **OpenSearch Dashboard**, the indexed logs can then be analyzed.

| Technology          	| Description            	|
|-----------------------|-----------------------	|
| Fluent Bit 	        | Log shipper (DaemonSet) responsible for shipping logs from nodes to DB 	|
| OpenSearch            | ElasticSearch-Fork responsible for storing and indexing log data        	|
| OpenSearch Dashboards | Kibana-Fork responsible for analyzing log data  |

## Monitoring

Several sources input data into the Prometheus instance. **Exporters** are responsible for exporting existing metrics from third-party systems, e.g. PostgreSQL instances or Kubernetes nodes (resource usage, networking, etc.). **Service Monitors** are created using a Custom Resource Definition and configure Prometheus to scrape Prometheus-compatible endpoints for metrics, as you can see in the `dotnet-weather-service` at the Route `/metrics`. **Alerts** can be defined using the Prometheus Alertmanager or Grafana. The latter is also being used for data visualization and displays the data stored in Prometheus (K8s metrics, data from exporters, ...) in charts, tables, etc. 

| Technology          	| Description            	|
|-----------------------|-----------------------	|
| Prometheus Service Monitors      | Custom Resource Definition that configures Prometheus to scrape metric endpoints (Operator pattern) |
| Prometheus Exporters  | Responsible for exporting data from a source and ship it to Prometheus (e.g. node-exporter for Kubernetes metrics) |
| Prometheus Alert Manager  | Responsible for sending alerts for various alerting endpoints |
| Prometheus            | Monitoring system & time series database for metric data        	|
| Grafana               | Responsible for visualization and alerting based on Prometheus data  |

## Setup

In order to set this demonstration up, a K3D cluster is being used. K3D is a tool that allows for easy creation of Kubernetes clusters by deploying a K3S-cluster within docker containers. All applications used in this repository (own implementations and third-party applications) are installed using `Helm Charts`. Two utility scripts contain all of the work necessary to setup the cluster and all deployments.

```bash
cd infrastructure

# Create cluster, deploy metrics stack, deploy own applications
./setup.sh

# Deploy logging stack (start separately, startup is very resource heavy)
./deploy_logging
```

After all applications are deployed, you can access the applications as shown in this table:

| Application          	| Endpoint          	| Description            	|
|-----------------------|-----------------------|-----------------------	|
| dotnet-weather-service | http://localhost/forecast     | Default weather forecast ASP.NET Core application (Prometheus metrics, Serilog structured logging)  |
| Prometheus            | No public endpoint    | Prometheus UI, useful for viewing data sources and service monitors |
| Grafana               | http://localhost/grafana | Grafana dashboard used for data visualization (Credentials admin:admin)  |
| OpenSearch               | http://localhost/opensearch | OpenSearch dashboard used for log analysis (Credentials admin:admin)  |