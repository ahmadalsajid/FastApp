# FastApp

This is a simple Python FastAPI application that will be used to demonstrate
GitHub Actions for CI/CD, Docker Hub to publish the image, AWS ECS for deployment,
and Terraform for IaC.

## Docker Compose

Spin up the application by

```
docker compose up -d
```

Once done with testing, remove with

```
docker compose down --rmi local
```