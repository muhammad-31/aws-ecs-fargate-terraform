# 3. Application deploys run in the pipeline, not in `terraform apply`

Status: accepted

## Context

Two common ways to ship a new image to ECS:

1. Pass the image tag into Terraform and run `terraform apply` per release.
2. Let Terraform own the infrastructure and the *shape* of the task definition,
   and let the deploy pipeline register a new revision with the new image.

Option 1 couples every application release to an infrastructure plan, makes
releases slower and gives application pipelines rights to change infrastructure.

## Decision

Option 2. The `aws_ecs_service` resource ignores changes to `task_definition`
and `desired_count`. The deploy workflow reads the latest revision of the task
family, swaps the image, registers a new revision and waits for the rollout.

## Consequences

- Releases take minutes and need only a narrow deploy role (ECR push, register
  task definition, update one service, pass two roles).
- A Terraform change to the task definition (CPU, memory, env vars) registers a
  new revision but is picked up by the *next* deploy, not immediately. Run the
  deploy workflow manually after such changes.
- Rollback = redeploy a previous image tag; the ECS deployment circuit breaker
  already rolls back automatically when new tasks fail health checks.
