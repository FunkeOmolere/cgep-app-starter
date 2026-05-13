# policies/cc67_tls_deny.rego
# METADATA
# title: SC-8 - TLS in Transit (S3)
# description: "Every aws_s3_bucket must have a bucket policy denying non-TLS requests."
# custom:
#   control_id: SC-8
#   framework: nist-800-53
#   soc2_control: CC6.7
#   severity: high
#   remediation: "Add aws_s3_bucket_policy with a Deny on s3:* where aws:SecureTransport is false."
package compliance.cc67_tls

import rego.v1

deny contains msg if {
  some resource in input.configuration.root_module.resources
  resource.type == "aws_s3_bucket"
  not has_tls_deny(resource.address)
  msg := sprintf(
    "[SC-8/CC6.7] %s: missing TLS-deny bucket policy. Remediation: add aws_s3_bucket_policy denying non-TLS requests.",
    [resource.address],
  )
}

has_tls_deny(bucket_addr) if {
  some r in input.configuration.root_module.resources
  r.type == "aws_s3_bucket_policy"
  some ref in r.expressions.bucket.references
  references_bucket(ref, bucket_addr)
}

references_bucket(ref, bucket_addr) if ref == bucket_addr
references_bucket(ref, bucket_addr) if ref == sprintf("%s.id", [bucket_addr])
references_bucket(ref, bucket_addr) if ref == sprintf("%s.bucket", [bucket_addr])