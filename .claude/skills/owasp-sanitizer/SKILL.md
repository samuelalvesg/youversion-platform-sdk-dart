---
name: owasp-sanitizer
description: Audits code and dependencies against OWASP Top 10 vulnerabilities, insecure defaults, sanitization flaws, authentication bypasses, and secret leaks.
---
# Security Checklist
1. **Injection (SQL, Command, LDAP, NoSQL)**:
   - Ensure parameterized queries and ORM abstractions. Reject string interpolation in SQL/raw commands.
2. **Broken Authentication & Authorization**:
   - Verify role-based/claims-based authorization on every route. Prevent horizontal privilege escalation (tenant/user ID checks).
3. **Sensitive Data Exposure & Secret Leaking**:
   - Verify no hardcoded API keys, JWT secrets, passwords, or tokens in source code or Git history. Ensure sensitive fields are masked in logs.
4. **Security Misconfiguration**:
   - Verify CORS policies, secure cookie attributes (HttpOnly, Secure, SameSite), CSRF tokens, and security headers (CSP, HSTS).
5. **Vulnerable and Outdated Dependencies**:
   - Audit lockfiles for known CVEs using package managers (`dotnet list package --vulnerable`, `npm audit`, `cargo audit`).
6. **Input Validation & Output Encoding**:
   - Validate input format, length, and types at system boundaries. Encode HTML output to prevent XSS.

# Report Format
`# | vulnerability | component:line | OWASP Category | risk (Critical/High/Medium/Low) | remediation`
