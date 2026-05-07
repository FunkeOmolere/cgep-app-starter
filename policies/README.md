# Compliance Policies

OPA/Rego policy library for the CGE-P capstone. Primary framework: SOC 2 Type II.

## Policy inventory

| File | Control | SOC 2 | Severity | Checks |
|------|---------|-------|----------|--------|
| sc28_encryption.rego | SC-28 | CC6.1 | High | S3 bucket has server-side encryption |
| ac3_no_public.rego | AC-3 | CC6.6 | Critical | S3 public access block, no open ports |
| cm6_required_tags.rego | CM-6 | CC6.8 | Medium | Required compliance tags present |

## Running tests

```bash
opa test -v policies/
# PASS: 8/8
```

## Running against a plan

```bash
conftest test --policy policies --namespace compliance.sc28 plan.json
conftest test --policy policies --namespace compliance.ac3  plan.json
conftest test --policy policies --namespace compliance.cm6  plan.json
```