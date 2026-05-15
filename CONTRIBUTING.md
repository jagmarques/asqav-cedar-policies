# Contributing

Templates are welcome. The repo's bar is:

1. One pattern per file under `policies/`, named after the predicate (e.g. `receipt_presence_decision_matches.cedar`).
2. A matching folder under `examples/<pattern_name>/` with at least a `README.md` showing the entity-shape inputs the policy expects and an `isAuthorized` invocation.
3. Compatible with the entity shapes the `cedar-for-agents` schema generator emits. If your pattern needs an extra entity shape, document the additional context field your host must supply.
4. Apache-2.0 only. No GPL / LGPL / AGPL contributions.

## Patterns open for contribution

- Signer-key binding (deny unless `context.receipt.signerKey` is one of `principal.boundKeys`).
- Timestamp freshness (deny if `context.receipt.timestamp` is older than N seconds before `now()`).
- Per-tenant policy-pack composition (helper for layering multiple of the above without copy-paste).

## Scope reminder

This repo only carries Cedar policy templates and host-side examples. It does NOT:

- Fork or vendor cedar-for-agents.
- Define a new authorization API surface.
- Standardise a receipt format. That work lives at `draft-marques-asqav-compliance-receipts`.

## PR checklist

- [ ] One pattern per file, snake_case filename.
- [ ] Matching `examples/<pattern>/README.md`.
- [ ] License header references Apache-2.0.
- [ ] Re-runs cleanly against the cedar-for-agents WASM surface (or notes the additional context fields the host must inject).
