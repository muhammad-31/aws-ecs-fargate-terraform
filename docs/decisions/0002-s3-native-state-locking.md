# 2. S3-native state locking instead of a DynamoDB lock table

Status: accepted

## Context

Terraform 1.10 added `use_lockfile` to the S3 backend: the lock is a `.tflock`
object next to the state file, written with S3 conditional writes. The
DynamoDB-based `dynamodb_table` argument is deprecated.

## Decision

Use `use_lockfile = true` and no DynamoDB table.

## Consequences

- One fewer resource and IAM permission set to manage.
- Requires Terraform >= 1.10 (pinned in `required_version` and in CI).
- Even the read-only plan role needs `s3:PutObject` / `s3:DeleteObject` to
  create and release lock files. Because the lock is a separate object
  (`<key>.tflock`), `bootstrap` can grant that on `*.tflock` only, so plan can
  never overwrite or delete state.
