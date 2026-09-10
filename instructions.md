1. Project Outcome: Architectural Overview & Logic Flow
The project will produce a "Polished Deployment & Automation Blueprint" that restores system integrity and enforces the "Golden Rules" through automated systems.

Logic Flow:

Commit Trigger: Developer pushes code to the repository.

Poka-Yoke CI/CD Gate: GitHub Actions workflow triggers.

Linter: ruff check and ruff format --check fail the build on style or formatting errors.

Security Scan: gitleaks detect identifies and quarantines the build if hardcoded credentials or API keys are found. The pipeline exit(1) immediately.

Terraform Provisioning: On a successful build, Terraform provisions a secure, isolated GCP environment.

D0 Raw Landing: A GCS bucket with encryption, versioning, and object lifecycle rules.

D1 Staged/Enforced: A BigQuery dataset with strict IAM RBAC and Row-Level Security (RLS) policies.

Data Pipeline: An incoming JSON payload for student onboarding passes through the Django REST Framework serializer.

DCYN Library Validation: The serializer converts complex JSON logic into Boolean (Yes/No) outputs using a custom library, eliminating human judgment on data integrity.

Data Storage: The validated data is streamed to BigQuery, where RLS policies enforce data isolation at the row level.

2. Solution - Task 1: Terraform Secure Staging Provisioning (IaC)
File: terraform/main.tf

This file provisions a GCS bucket for raw landing, a BigQuery dataset for staged data, and applies security policies. Note that BigQuery Row-Level Security is enforced via a query job, as Terraform lacks a direct resource for creating row access policies .

3. Solution - Task 2: Poka-Yoke Automated CI/CD Build Gate
File: .github/workflows/poka-yoke-gate.yml

This workflow implements a strict "Fail-Closed" gate. If any linter or security scan fails, the workflow immediately exits with an error, halting the build and quarantining the commit.

Submission Requirement (b) - Demonstrating Fail-Closed:
The gate is "fail-closed" because:

It uses run blocks that automatically halt on a non-zero exit code.

It explicitly checks the exit code of the gitleaks command. Any issue (including a malformed scan output) results in an exit(1) , ensuring we never "hope" the pipeline passes. The if: failure() step is a separate safeguard to quarantine artifacts from a failed build.

4. Solution - Task 3: Schema Mapping and DCYN Validation
File: api/serializers/student_onboarding_serializer.py

This file includes the DCYN logic library and the DRF model serializer with precise validation rules.

Submission Requirement (c) - Presentation & Data Mapping:

Spreadsheets: The worksheet used for mapping the JSON payload schema to the D0/D1 data flow will have "Wrap Text" enabled as per instructions.

Full Forms: The presentation will avoid all abbreviations (e.g., using "Infrastructure as Code" instead of IaC).

Labeling: The answer document and code files will be clearly labeled with my full name and contact information, as specified.

5. Presentation Structure for Project Interview (Max 15 Slides)
Title Slide: Full Name, Contact Info, Project Title.

Executive Summary: Understanding of HabotConnect's mission and the project's core objective.

Root Cause Analysis: Highlighting the developer's security failure and schema mismatch.

Architectural Overview: Diagram of the D0 → D1 → D2 data flow.

Task 1: IaC Design - GCS Bucket: Security features (versioning, encryption, lifecycle).

Task 1: IaC Design - BigQuery & RLS: Enforcing Row-Level Security for parent privacy.

Task 1: IAM & Least Privilege: Justification for RBAC over broad roles.

Task 2: Poka-Yoke Pipeline Logic - Stage 1: Linter & Formatting Gates.

Task 2: Poka-Yoke Pipeline Logic - Stage 2: Security Scan & Quarantine.

Task 2: Fail-Closed Proof: Live demonstration or simulation of the pipeline failing on a secret commit.

Task 3: Schema & DCYN - JSON Mapping: Table connecting JSON fields to model fields.

Task 3: DRF Serializer Validation: Explanation of strict validators and custom DCYN logic.

Task 3: Operational Integrity: "Zero Human Judgment" - How the DCYN library removes ambiguity.

Alignment with HabotConnect Values: Connecting the technical work to the values of "Quality, Clarity, and Accountability" .

Closing & Q&A: Summary of outcomes and readiness for next steps.