# 1. ECS Fargate instead of EKS for a single web application

Status: accepted

## Context

The workload is one containerised HTTP service with a PostgreSQL database.
The team running it is small and does not have a platform team.

## Decision

Run the service on ECS with the Fargate launch type.

## Consequences

- No cluster to upgrade, no node groups, no control-plane fee
  (an EKS cluster costs about $73/month before any workload runs).
- IAM, ALB, Secrets Manager and CloudWatch integrations are native, with no add-ons
  (no AWS Load Balancer Controller, External Secrets, etc.).
- Less portable than Kubernetes manifests. If the product grows to many services
  that need service mesh, custom controllers or multi-cloud, revisit and move to EKS.
- Fargate costs more per vCPU than EC2 at steady high utilisation; Fargate Spot
  (used in dev) and ARM64 tasks narrow the gap.
