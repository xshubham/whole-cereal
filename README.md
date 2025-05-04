# Book Library Service

A complete microservice-based book library application with observability, infrastructure as code, and Kubernetes deployment capabilities.

## Project Structure

- `application/` - Main Python application with FastAPI
- `infrastructure/` - Terraform IaC for Azure infrastructure
- `k8s/` - Kubernetes manifests and Helm charts
- `tests/` - Unit and integration tests

## Features

- RESTful API for book management
- User authentication and authorization
- Full observability stack (Prometheus, Grafana, Loki, Tempo)
- Infrastructure as Code with Terraform
- Kubernetes deployment with ArgoCD
- CI/CD with Jenkins

## Prerequisites

- Python 3.10+
- Docker and Docker Compose
- Terraform
- kubectl
- Azure CLI
- Helm

## Quick Start

1. Clone the repository
2. Set up the development environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # or `venv\Scripts\activate` on Windows
   pip install -r application/requirements.txt
   ```

3. Run locally with Docker Compose:
   ```bash
   cd application
   docker-compose up
   ```

4. Access the API documentation at `http://localhost:8000/docs`

## Development

- Run tests: `pytest tests/`
- Format code: `black .`
- Lint code: `flake8`

## Deployment

### Infrastructure Setup

```bash
cd infrastructure/terraform
terraform init
terraform apply -var-file=dev.tfvars
```

### Application Deployment

```bash
cd k8s/helm/book-library
helm install book-library . -f values-dev.yaml
```

## Monitoring

- Grafana: Access dashboards at `http://localhost:3000`
- Prometheus: Metrics at `http://localhost:9090`
- Tempo: Distributed tracing
- Loki: Log aggregation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

See [LICENSE](LICENSE) file for details.