# WRITEUP.md — Acme Health Patient Intake API GRC Pipeline

## Framework choice

Primary framework: SOC 2 Type II (Trust Services Criteria).

SOC 2 was chosen because the capstone scenario positions Acme Health as a
telehealth company with an enterprise customer asking for audit evidence.
SOC 2 Type II is the most common external audit requirement in that context.
Controls are mapped to NIST 800-53 Rev 5 equivalents throughout the repo
to demonstrate cross-framework coverage and support future HIPAA alignment.

## What I built

A four-layer GRC pipeline wrapped around the Acme Health starter workload:

Layer 1 — Terraform baseline closing all 8 starter gaps:
- GAP-01: S3 SSE-KMS via aws_s3_bucket_server_side_encryption_configuration
- GAP-02: DynamoDB SSE with customer-managed KMS key
- GAP-03: S3 TLS-deny bucket policy blocking non-HTTPS requests
- GAP-04: S3 versioning enabled
- GAP-05: Lambda deployed in VPC with subnet and security group config
- GAP-06: Lambda dead letter queue, reserved concurrency, X-Ray tracing
- GAP-07: IAM policy scoped to least-privilege actions
- GAP-08: API Gateway access logging and throttling

Layer 2 — Five Rego policies enforcing SOC 2 controls:
- sc28_encryption_aws.rego: CC6.1 encryption at rest
- ac3_no_public_aws.rego: CC6.6 public access prevention
- cm6_required_tags_aws.rego: CC6.8 required compliance tags
- cc67_tls_deny.rego: CC6.7 TLS in transit
- cc66_lambda_vpc.rego: CC6.6 Lambda network isolation

Layer 3 — GitHub Actions pipeline running on every PR:
- OIDC authentication to AWS (no long-lived secrets)
- Terraform plan
- Conftest policy gate (fails closed)
- tfsec scan (informational)
- Cosign keyless signing of evidence bundle
- Upload to immutable S3 vault with Object Lock

Layer 4 — OSCAL component definition validated by compliance-trestle,
mapping SC-28, AC-3, and CM-6 to real Terraform resources and Rego policies
with evidence links to signed vault bundles.

## Design decisions

Conftest is the policy gate, not tfsec. The capstone rubric uses Conftest
for deterministic pass/fail. tfsec is informational and suppressed findings
are documented in .tfsec/config.yml with justifications.

AWS variants of Rego policies over base policies. Terraform plans use
tags_all not tags for provider-level default_tags. The AWS variants read
tags_all correctly; the base policies false-positive on this pattern.

default_tags over per-resource tags. One edit to the provider block applies
compliance tags to every resource via tags_all. More maintainable and less
error-prone than per-resource tagging.

Keyless Cosign signing over key management. GitHub OIDC tokens are used to
obtain short-lived Sigstore certificates. No key material is stored anywhere.
The Rekor transparency log provides an immutable timestamp.

Single AWS account for lab scope. A separate evidence vault account would
be cleaner for production but adds IAM complexity beyond the 30-day scope.
Documented as future work.

## Control coverage

| TSC    | NIST 800-53 | Implementation                        | Detection                        |
|--------|-------------|---------------------------------------|----------------------------------|
| CC6.1  | SC-28       | KMS CMK + SSE-KMS on S3 and DynamoDB  | sc28_encryption_aws.rego         |
| CC6.3  | AC-6        | IAM scoped to least-privilege         | (Terraform only)                 |
| CC6.6  | AC-3, SC-7  | S3 PAB, Lambda in VPC                 | ac3_no_public_aws.rego           |
| CC6.7  | SC-8        | S3 TLS-deny bucket policy             | cc67_tls_deny.rego               |
| CC6.8  | CM-6        | Provider default_tags                 | cm6_required_tags_aws.rego       |
| CC7.2  | AU-2        | API GW access logs, DLQ, X-Ray        | (Terraform only)                 |
| A1.2   | CP-9        | S3 versioning                         | (Terraform only)                 |

## Trade-offs and accepted findings

Two tfsec findings are suppressed with justifications in .tfsec/config.yml:

aws-vpc-no-public-egress-sgr: Lambda security group allows egress to
0.0.0.0/0 on port 443. Required for Lambda to reach AWS API endpoints
until VPC endpoints are provisioned. Documented as future work.

aws-iam-no-policy-wildcards: s3:PutObject on bucket/*. AWS-recommended
pattern for workload Lambdas with dynamic object keys. The resource scope
is limited to the specific uploads bucket.

## What I did not get to

CloudTrail and AWS Config baseline (Lab 5.2). These would satisfy AU-2,
AU-9, and AU-10 more completely. Documented as the next sprint.

Additional Rego policies beyond the 5 minimum. CC6.3 IAM least-privilege
and AU-2 logging policies would strengthen the suite.

OSCAL system security plan. The component definition describes the
component. A full SSP would describe the whole system. Out of scope for
30 days.

Separate evidence vault AWS account. Cleaner separation of duties but
adds IAM cross-account complexity. Single account accepted for lab scope.

## What I learned

I have been in GRC for years. I know compliance frameworks. I know how to
map risks, lead audits, align stakeholders, write policies, and support
compliance maturity across complex environments. This capstone was not about
learning what a control is. It was about learning how to make one run.

The shift was real. Writing Rego to enforce a control is different from
documenting it. Building a pipeline that blocks non-compliant infrastructure
is different from filing a finding after the fact. Generating signed evidence
automatically is different from taking a screenshot.

The hardest technical lesson was OSCAL. I understood the concept before I
started. A machine-readable description of what you built, linked to the
evidence that proves it. But writing a valid component-definition.json
from scratch taught me things the framework docs do not say. UUIDs must be
v4. The source field must point at the exact catalog your controls come from.
Implementation statements must reference real resources, not aspirational ones.
trestle validate catches everything and is honest about it.

The hardest Terraform lesson was the gap between what works locally and what
works in CI. My pipeline had TF_WORKING_DIR pointing at the wrong directory
for days. Every CI run was scanning terraform/primitives/evidence-vault instead
of terraform. Conftest was failing with path errors that made no sense until I
found that one variable. The fix was one line. The debugging was hours.

The hardest pipeline lesson was that base Rego policies and AWS variants exist
for a reason. The base compliance.cm6 policy reads resource.values.tags. The
AWS variant reads resource.values.tags_all. If you use default_tags in your
provider, only the AWS variant sees your tags correctly. I chased five false
positives before I understood why.

What I would tell someone starting this with years of GRC experience: the
frameworks you know will make the design obvious. The engineering will still
surprise you. That is not a problem. That is the point.