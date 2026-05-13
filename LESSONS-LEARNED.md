# Lessons Learned — CGE-P Capstone

I came into this new to GRC engineering and new to most of the toolchain.
I know compliance frameworks. I know controls. I know how to map risks,
lead audits, and support compliance maturity. But I had never written code
to enforce a compliance control or built a pipeline that blocks
non-compliant infrastructure automatically.

This is what I wish someone had told me before I started.

## The mindset shift

Someone once told me it does not matter how long you have been in the
industry. What matters is how willing you are to shift. This capstone
tested that for me.

A control that runs is stronger than a control that is documented.
Evidence generated automatically is stronger than a screenshot.
A gate that blocks is stronger than a finding that gets filed after the fact.

I understood this concept on day one. Making it real took longer.

## What actually tripped me up

The pipeline was scanning the wrong directory for days and I did not know.
One variable, TF_WORKING_DIR, was pointing at terraform/primitives/evidence-vault
instead of terraform. Every CI run was evaluating the wrong code. Conftest
kept failing with path errors that made no sense until I found the root cause.
The lesson: check your working directory before you debug anything else.

Long content pastes corrupt silently in macOS Terminal. I lost hours to this.
Words duplicated, lines merged, files looked saved but were broken. If you need
to write more than a few lines to disk, use VS Code's editor directly. Not
pico, not bash heredocs. VS Code.

The base Rego policy and the AWS variant exist for different reasons. The base
reads resource.values.tags. The AWS version reads resource.values.tags_all.
If you use default_tags in your Terraform provider, only the AWS variant will
see your tags correctly. I spent time chasing failures that were actually false
positives from using the wrong policy variant.

Default tags are more powerful than per-resource tags. When my CM-6 policy was
flagging four different resources for missing compliance tags, I nearly added
tags to each one individually. One edit to the provider default_tags block
fixed all five failures at once. Every resource inherits via tags_all.

tfsec is not the gate. Conftest is. I spent time fighting tfsec findings before
I re-read the capstone overview and realised the grader uses Conftest, not tfsec.
Read the actual grading criteria before you optimise for the wrong thing.

## What I got right

I kept going. Some things broke multiple times before they worked. The terminal
is not my natural habitat. But the concept made sense from day one, and I kept
building toward it.

I documented my trade-offs honestly. The tfsec suppressions in my repo have
justifications. The gaps I did not close are listed as future work. That is
what real GRC engineering looks like.

I asked the right questions when stuck. Not just "why is this broken" but
"am I solving the right problem."

## What I would tell someone starting day one

Read GAPS.md and the full capstone overview before you touch any code.
Understand what you are building before you start building it.

Set up your full toolchain first. Terraform, Conftest, OPA, tfsec, Cosign,
AWS CLI. Do this in week one, not the night before the deadline.

Get the pipeline running before you optimise anything. One PR through CI,
even broken, teaches you more than perfect code that never runs.

Write your WRITEUP.md as you go. You will not remember your trade-off
reasoning at the end. Write it when you make the decision.

Cut scope early if you need to. Five things done well beats eight things
half-done. The capstone says this explicitly. I wish I had listened sooner.

The learning curve is real. Some things will break multiple times.
That is not failure. That is the process.# Cosign signing test
# Final verification run
