# CGE-P Capstone — Patient Intake API GRC Pipeline

A working policy-as-code pipeline for a HIPAA/SOC 2 scoped serverless workload. Built as the capstone project for the GRC Engineering Practitioner program.

## What this is

The starter ships an intentionally non-compliant patient intake API (`terraform/main.tf` — "Acme Health") with 8 named compliance gaps in `GAPS.md`. This repo closes those gaps in Terraform, detects regressions with Rego policies, and produces evidence on every PR.

**Framework chosen:** SOC 2 Type II (with mappings to NIST 800-53 and HIPAA).

## Learning in public

I am new to GRC engineering. This repo is intentionally a record of the journey, including dead ends, suppressed findings with documented justifications, and an open `LESSONS-LEARNED.md`. If you are starting out, that document is probably more useful to you than the Terraform itself.

## Control coverage

| TSC    | NIST 800-53 | Implemented in           | Detected by                  |
|--------|-------------|--------------------------|------------------------------|
| CC6.1  | SC-28       | KMS CMK + SSE-KMS        | `sc28_encryption_aws.rego`   |
| CC6.3  | AC-6        | Scoped IAM policy        | (Layer 1 only)               |
| CC6.6  | AC-3, SC-7  | S3 PAB, Lambda in VPC    | `ac3_no_public_aws.rego`     |
| CC6.7  | SC-8        | S3 TLS-deny policy       | (Layer 1 only)               |
| CC6.8  | CM-6        | `default_tags` on provider | `cm6_required_tags_aws.rego` |
| CC7.2  | AU-2, SI-11 | API GW logs, DLQ, X-Ray  | (Layer 1 only)               |
| A1.2   | CP-9        | S3 versioning            | (Layer 1 only)               |

## Gap closure status

| Gap     | Closed by             | Resource                                          |
|---------|-----------------------|---------------------------------------------------|
| GAP-01  | `main_overrides.tf`   | S3 SSE-KMS configuration                          |
| GAP-02  | `main.tf` (inline)    | DynamoDB SSE with customer CMK                    |
| GAP-03  | `main_overrides.tf`   | S3 bucket policy denying non-TLS requests         |
| GAP-04  | `main_overrides.tf`   | S3 versioning                                     |
| GAP-05  | `main.tf` (inline)    | Lambda `vpc_config` block                         |
| GAP-06  | `main.tf` (inline)    | Lambda DLQ + reserved concurrency + X-Ray         |
| GAP-07  | `main.tf` (inline)    | IAM scoped to least-privilege actions             |
| GAP-08  | `main.tf` + overrides | API Gateway access logs + throttling              |

## Repository layout

.
├── .github/workflows/grc-gate.yml
├── .tfsec/config.yml
├── oidc/
├── policies/
│   ├── sc28_encryption.rego
│   ├── ac3_no_public.rego
│   ├── cm6_required_tags.rego
│   └── tests/
├── terraform/
│   ├── main.tf
│   ├── main_overrides.tf
│   └── primitives/
├── GAPS.md
├── LESSONS-LEARNED.md
└── WRITEUP.md

## Status

- [x] Layer 1 — Terraform baseline + all 8 gaps closed
- [x] Layer 2 — Rego policy library (3 policies + AWS variants, 8/8 tests passing)
- [x] Layer 3 — Pipeline with OIDC, Conftest gate, evidence upload
- [x] Red PR + Green PR in repo history (#1 red, #2 green)
- [ ] 2 additional Rego policies (CC6.7 TLS, CC6.6 Lambda-in-VPC)
- [ ] Cosign signing of evidence bundle (Lab 4.4)
- [ ] CloudTrail baseline (Lab 5.2)
- [ ] Layer 4 — OSCAL component definition
- [ ] `WRITEUP.md`

## Trade-offs and accepted findings

Two tfsec findings are suppressed via inline `# tfsec:ignore:` comments with justifications:

- **`aws-vpc-no-public-egress-sgr`** — Lambda SG egress to `0.0.0.0/0:443`. Required for AWS API access until VPC endpoints land (Lab 5.2 scope).
- **`aws-iam-no-policy-wildcards`** — `s3:PutObject` on `bucket/*`. AWS-recommended pattern for workload Lambdas with dynamic object keys.

Per the capstone overview, tfsec is informational only (not on the Tier 0 grading list). Conftest is the policy gate.
## Prerequisites

- Terraform >= 1.6
- OPA + Conftest (for policy evaluation)
- tfsec (for security scanning, informational)
- AWS CLI configured with credentials to a sandbox account
- (Optional) Cosign for evidence bundle signing
## Verification

```bash
cd terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

for ns in compliance.sc28_aws compliance.ac3_aws compliance.cm6_aws; do
  conftest test --policy ../policies --namespace "$ns" plan.json
done
```

## Credits

Forked from the GRC Engineering Club (grcengclub.com) CGE-P capstone starter. The Acme Health workload, GAPS.md, and lab structure are theirs; the gap closures, Rego policies, CI pipeline, and write-up are mine.

## License

MIT