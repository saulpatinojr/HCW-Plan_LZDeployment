# HCW Landing Zone Platform — Build Documentation

## Overview

This directory contains comprehensive build documentation for the HCW Landing Zone Platform, a 6-week, 155-195 hour initiative spanning infrastructure-as-code (Terraform + Bicep), web application development (React + Node.js), and security hardening.

**Status**: Phase 0 (Audit & Reconcile) — NOT STARTED  
**Target Launch**: Week 7 (estimated 2026-08-10)  
**Total Effort**: 155-195 hours

---

## Quick Links

### 📋 **Core Documents** (Read in Order)

1. **[BUILD_VERIFICATION_REPORT.md](BUILD_VERIFICATION_REPORT.md)** ⭐ **START HERE**
   - Executive summary of build phases
   - Verified modules & Microsoft Learn standards
   - Phase breakdown (0-5) with requirements
   - Audit checklists for Terraform/Bicep
   - **Reading time**: 20-30 min
   - **For**: Architects, leads, technical planners

2. **[BUILD_CRITICAL_PATH.md](BUILD_CRITICAL_PATH.md)** ⭐ **THEN READ THIS**
   - Weekly timeline (Week 1-7)
   - Decision gates & go/no-go criteria
   - Team resource allocation
   - Risk mitigation & contingencies
   - Success metrics per phase
   - **Reading time**: 15-20 min
   - **For**: Project managers, team leads

3. **[BUILD_STANDARDS_REFERENCE.md](BUILD_STANDARDS_REFERENCE.md)** ⭐ **REFERENCE GUIDE**
   - Terraform module structure (AVM standard)
   - Bicep module patterns (Microsoft Learn)
   - Phase 1 code templates (Node.js, React, Docker)
   - Phase 2 infrastructure templates (Bicep, GitHub Actions)
   - **Reading time**: 30-45 min (skim sections as needed)
   - **For**: Developers, infrastructure engineers

4. **[TODO.md](TODO.md)**
   - Master TODO list with all tasks
   - Phase 0-5 detailed subtasks
   - Progress tracking table
   - **Reading time**: 10 min (reference)
   - **For**: Task tracking, team reference

---

## Document Structure

### For Project Managers & Leads
👉 Read in this order:
1. BUILD_VERIFICATION_REPORT.md (intro + phase summary)
2. BUILD_CRITICAL_PATH.md (timeline + gates + resources)
3. TODO.md (task list for tracking)

### For Developers & Infrastructure Engineers
👉 Read in this order:
1. BUILD_VERIFICATION_REPORT.md (requirements & standards intro)
2. BUILD_STANDARDS_REFERENCE.md (code patterns & templates)
3. Use TODO.md as task list during implementation

### For Security & Compliance
👉 Focus on:
1. BUILD_VERIFICATION_REPORT.md (Phase 5 security hardening)
2. BUILD_STANDARDS_REFERENCE.md (Terraform AVM, Bicep security)
3. BUILD_CRITICAL_PATH.md (Security gate & validation checkpoints)

---

## Key Sections

### Phase 0: Audit & Reconcile (Week 1)
- **Status**: 🔴 NOT STARTED
- **Duration**: 4-6 hours
- **Blocker**: MUST complete before anything else
- **Deliverable**: Audit table + Updated TODO.md
- **Reference**: BUILD_VERIFICATION_REPORT.md § "Phase 0"

### Phase 1: Web App — Docker Local (Weeks 2-3)
- **Status**: 🟦 BLOCKED (waiting on Phase 0)
- **Duration**: 40-50 hours (parallel teams)
- **Teams**: Backend + Frontend + DevOps
- **Deliverable**: Docker image <300MB, multi-arch
- **Reference**: 
  - BUILD_CRITICAL_PATH.md § "Week 2-3"
  - BUILD_STANDARDS_REFERENCE.md § "Phase 1 Build"

### Phase 2: Web App — Azure Deployment (Week 4)
- **Status**: 🟦 BLOCKED (waiting on Phase 1)
- **Duration**: 30-40 hours
- **Team**: Infrastructure Engineer
- **Deliverable**: Bicep modules + GitHub Actions deploy
- **Reference**: 
  - BUILD_CRITICAL_PATH.md § "Week 4"
  - BUILD_STANDARDS_REFERENCE.md § "Bicep Modules", "GitHub Actions"

### Phase 3: Web App — Production (Week 5)
- **Status**: 🟦 BLOCKED (waiting on Phase 2)
- **Duration**: 20-25 hours
- **Team**: Infrastructure + Security
- **Deliverable**: Custom domain, TLS, security hardening
- **Reference**: BUILD_CRITICAL_PATH.md § "Week 5"

### Phase 4: Toolkit Consolidation (Week 6)
- **Status**: 🟦 BLOCKED (waiting on Phase 3)
- **Duration**: 20-25 hours
- **Team**: Infrastructure + Documentation
- **Deliverable**: Module documentation, feature parity
- **Reference**: BUILD_VERIFICATION_REPORT.md § "Phase 4"

### Phase 5: Security Hardening (Weeks 6-7)
- **Status**: 🟦 BLOCKED (waiting on Phase 4)
- **Duration**: 40-50 hours
- **Team**: Security + Infrastructure
- **Deliverable**: Security review, compliance scan, launch approval
- **Reference**: BUILD_VERIFICATION_REPORT.md § "Phase 5"

---

## Standards & Best Practices

### Terraform (AVM — Azure Verified Modules)
- **Provider versions**: azurerm ~> 4.0, azapi ~> 2.0
- **Naming**: lower snake_casing for all identifiers
- **File structure**: main.tf, variables.tf, outputs.tf, locals.tf, terraform.tf
- **Key files**: `.terraform-docs.yml` for auto-generated READMEs
- **Validation**: `terraform fmt`, `terraform validate`, `tflint`
- **Reference**: 
  - BUILD_STANDARDS_REFERENCE.md § "Terraform Modules"
  - BUILD_VERIFICATION_REPORT.md § "Terraform Module Audit Checklist"
  - https://azure.github.io/Azure-Verified-Modules/specs/terraform/

### Bicep (Microsoft Learn)
- **Naming**: camelCasing for all identifiers
- **Outputs**: Discrete attributes only (anti-corruption layer)
- **Sensitive data**: Mark with @secure() decorator
- **Modules**: Reference via `br/public:avm/res/...` syntax
- **Parameters**: Clear descriptions, precise types
- **Validation**: `bicep build`, `bicep lint`
- **Reference**:
  - BUILD_STANDARDS_REFERENCE.md § "Bicep Modules"
  - BUILD_VERIFICATION_REPORT.md § "Bicep Best Practices"
  - https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices

### Code & Architecture
- **Backend**: Node.js + Express + TypeScript
- **Frontend**: React + Vite + TypeScript + Tailwind CSS
- **Infrastructure**: Bicep (Phase 2), Terraform (Phases 4-5)
- **CI/CD**: GitHub Actions with OIDC to Azure
- **Containers**: Multi-stage Docker Dockerfile, <300MB target, multi-arch (amd64 + arm64)
- **Reference**: BUILD_STANDARDS_REFERENCE.md § "Phase 1-2 Code Patterns"

---

## Decision Gates

### Gate 1: Phase 0 Complete (End of Week 1)
- ✅ Audit table signed off
- ✅ TODO.md updated with ground truth
- ✅ Standards gaps documented
- ✅ Team ready for Phase 1

### Gate 2: Phase 1 Complete (End of Week 3)
- ✅ Docker image <300MB, multi-arch
- ✅ OAuth flow works end-to-end
- ✅ Wizard creates real GitHub repo
- ✅ Job status polling functional

### Gate 3: Phase 2 Complete (End of Week 4)
- ✅ Bicep modules deploy without error
- ✅ Container Apps environment healthy
- ✅ Full wizard flow works against Azure
- ✅ Auto-scale verified

### Gate 4: Phase 3 Complete (End of Week 5)
- ✅ Custom domain + TLS working
- ✅ Security headers present
- ✅ Load test passed
- ✅ Runbook documented

### Final Gate: Phase 5 Complete (Week 7)
- ✅ Security review approved
- ✅ Compliance scan clean
- ✅ Azure Secure Score >80
- ✅ Ready for production launch

**Reference**: BUILD_CRITICAL_PATH.md § "Decision Gates & Escalation"

---

## Getting Started

### For Immediate Action (This Week)

1. **Phase 0 Kickoff Preparation**
   - [ ] Read BUILD_VERIFICATION_REPORT.md (full)
   - [ ] Assign Phase 0 audit owner
   - [ ] Schedule Phase 0 kickoff meeting
   - [ ] Create GitHub project board for Phase 0-5

2. **Team Alignment**
   - [ ] Assign team roles (Backend, Frontend, Infrastructure, Security)
   - [ ] Share BUILD_CRITICAL_PATH.md with team
   - [ ] Brief team on AVM Terraform standards
   - [ ] Brief team on Microsoft Bicep standards

3. **Prepare Audit Tools**
   - [ ] Setup Explore agent for TODO verification
   - [ ] Create audit table template (markdown)
   - [ ] List all Terraform modules in repo
   - [ ] List all Bicep files (if any)

### Do NOT Start Build Yet
❌ No code development until Phase 0 complete  
❌ No Terraform/Bicep work until standards audit done  
❌ No Docker builds until architecture reviewed

---

## FAQ

**Q: Can we skip Phase 0?**  
A: No. Phase 0 is the blocking prerequisite. It ensures we're building on accurate information, not aspirational claims.

**Q: Can phases run in parallel?**  
A: No. Each phase depends on the previous one (see critical path). However, *within* a phase, teams can work in parallel (e.g., Backend + Frontend in Phase 1).

**Q: What if we find issues during Phase 0?**  
A: Document them, update TODO.md with ground truth, and adjust Phase 1-5 scope/timeline accordingly. Don't hide issues.

**Q: Are all Phase 5 items required?**  
A: No. Group A (validations) are required. Group B & C are recommended but can be deferred. Phase 5 is 6-7 weeks out; reprioritize as needed.

**Q: What if Docker image is 350MB instead of 300MB?**  
A: Aim for <300MB, but <400MB is acceptable if it blocks shipping. Document the reason (which layer caused growth) and plan optimization post-launch.

**Q: Where do I find code examples?**  
A: BUILD_STANDARDS_REFERENCE.md has complete templates for:
- Terraform modules (file structure, variables, outputs, main.tf)
- Bicep modules (parameters, outputs, main.bicep)
- Express API (server.ts, endpoints)
- React wizard (App.tsx, Wizard component)
- Dockerfile (multi-stage build)
- GitHub Actions workflow

---

## Resource Links

### Standards & Best Practices
- [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Terraform Specs](https://azure.github.io/Azure-Verified-Modules/specs/terraform/)
- [Microsoft Learn: Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure Container Apps Code-to-Cloud](https://learn.microsoft.com/azure/container-apps/code-to-cloud-options)

### Tools & Development
- [Terraform Docs](https://github.com/terraform-docs/terraform-docs) — Auto-generate module READMEs
- [TFLint](https://github.com/terraform-linters/tflint) — Terraform linting
- [Bicep CLI](https://github.com/Azure/bicep) — Bicep validation
- [Vite](https://vitejs.dev/) — React frontend build
- [Docker Buildx](https://docs.docker.com/build/architecture/) — Multi-arch builds

### References
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Bicep Function Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [GitHub Actions with Azure OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

## Document Maintenance

**Last Updated**: 2026-06-30  
**Owner**: Platform Engineering  
**Next Review**: End of Phase 0 (2026-07-06)

When updating these documents:
1. Keep all 4 documents in sync (cross-reference updates)
2. Update TODO.md as tasks complete
3. Update this README.md with new links/sections
4. Maintain version parity across BUILD_*.md files

---

## Support & Questions

**For Phase Planning Questions**: See BUILD_CRITICAL_PATH.md  
**For Code Pattern Questions**: See BUILD_STANDARDS_REFERENCE.md  
**For Requirements Questions**: See BUILD_VERIFICATION_REPORT.md  
**For Task Tracking**: See TODO.md  

**Questions about standards?**  
- AVM Terraform: https://azure.github.io/Azure-Verified-Modules/specs/terraform/
- Microsoft Bicep: https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices

---

**Ready to start Phase 0? Read [BUILD_VERIFICATION_REPORT.md](BUILD_VERIFICATION_REPORT.md) first. ⭐**
