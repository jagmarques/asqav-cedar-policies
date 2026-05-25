# Example: third-party-notary receipt binding

Minimal host-side scenario for `policies/receipt_third_party_notary.cedar`.

## When to use this template

Reach for this policy when the host's authorization layer must enforce that a third-party notary (not the principal's home tenant, not the resource's owning tenant) signed the receipt that authorises the action. Regulators, procurement reviews, and customer security questionnaires increasingly require this separation; baking it into Cedar pushes the check down into the authorization-decision boundary instead of trusting an upstream pipeline.

This template is composable. Layer it with `receipt_presence_decision_matches` (presence + decision-permit) and `receipt_chain_validity` (chain integrity) to get a stacked policy pack: presence then chain then notary-binding.

## What this policy enforces

- A `receipt` is present on `context`.
- `receipt.captureTopology == "third_party_notary"`. The five-value vocabulary `third_party_notary | counterparty | self_signed | tenant_internal | unknown` matches the `capture_topology` field in the IETF Compliance Receipts draft.
- `receipt.signer` is on the host's allow-list of notaries (`context.allowedNotaries`).
- `receipt.expiry` is either 0 (non-expiring) or strictly greater than `context.now`.

What it deliberately does NOT do: signature cryptography, key-binding, or chain validation. Those are precondition checks that run upstream of Cedar; do not re-implement signature math inside a policy.

## Files in this folder

- `schema.cedarschema` - entity-type fragment plus the context shape (`Receipt`, `now`, `allowedNotaries`).
- `entities.example.json` - sample entity store with one `Agent`, one `Tool`, one `ToolInvocation`.
- `request.example.json` - sample `isAuthorized` request that satisfies the policy.

## Authorization request

```json
{
  "principal": { "type": "Agent", "id": "agt_demo" },
  "action": { "type": "Tool", "id": "search.web" },
  "resource": { "type": "ToolInvocation", "id": "inv_777" },
  "context": {
    "receipt": {
      "signer": "notary.example.com",
      "captureTopology": "third_party_notary",
      "expiry": 1900000000,
      "policyDecision": "permit",
      "issuer_id": "org_demo",
      "action_ref": "sha256:9b74c9897bac770ffc029102a200c5de"
    },
    "now": 1747000000,
    "allowedNotaries": ["notary.example.com", "second-notary.example.org"]
  }
}
```

## Expected decision

`isAuthorized` returns `Allow`. All four conditions are satisfied: topology is `third_party_notary`, signer is on the allow-list, expiry is in the future, and Cedar's default-deny is lifted by the absence of any explicit `forbid`.

## Failure modes

- `receipt.captureTopology` is `self_signed`, `counterparty`, `tenant_internal`, or `unknown`: `Deny`. The notary requirement is the whole point of this template.
- `receipt.signer` is not in `context.allowedNotaries`: `Deny`. The host MUST curate the allow-list; an empty set means no notary is trusted yet.
- `receipt.expiry` is non-zero and `<= context.now`: `Deny`. Stale receipts are not authorization-granting.
- `context` is missing `receipt`, `now`, or `allowedNotaries`: `Deny`. The policy short-circuits on absent fields rather than treating them as wildcards.

## How to integrate

### AWS Verified Permissions (AVP)

1. Upload `policies/receipt_third_party_notary.cedar` to your AVP policy store.
2. Extend your policy store's schema with the `Receipt` type definition from `schema.cedarschema` (or merge into the schema your cedar-for-agents generator already emits).
3. At authorization time, your receipt-verification SDK populates `context.receipt`, `context.now`, and `context.allowedNotaries`, then calls `IsAuthorized`.

### Cerbos

1. Cerbos has its own DSL but ships an experimental Cedar policy loader; load the policy via the equivalent `cedar` ruleset.
2. Populate the `aux_data` block at request time with the same context fields shown above.
3. Test via `cerbosctl decisions` against the example request.

### Local `cedar authorize` smoke test

If you have the Cedar CLI installed (`cargo install cedar-policy-cli`):

```bash
cedar authorize \
  --policies policies/receipt_third_party_notary.cedar \
  --schema examples/receipt_third_party_notary/schema.cedarschema \
  --entities examples/receipt_third_party_notary/entities.example.json \
  --request-json examples/receipt_third_party_notary/request.example.json
```

The CLI prints `ALLOW`. Flip `captureTopology` to `self_signed` and rerun; the CLI prints `DENY` with the matching `forbid` policy ID `receipt-third-party-notary`.

## Where the receipt comes from

The host's verifier produces the `receipt` object. The receipt format and signature cryptography are governed by the IETF Compliance Receipts draft (`draft-marques-asqav-compliance-receipts`). The `captureTopology` value MUST come from the receipt's `capture_topology` claim verbatim; do not re-derive it inside Cedar from other fields.

## Notes for host implementors

- The five-value `captureTopology` vocabulary is locked at the receipt-format layer. Do not invent a sixth value inside Cedar; if you need a different distinction (e.g. `escrow_notary`), open an issue against the IETF draft first so the vocabulary stays single-sourced.
- `allowedNotaries` SHOULD be tenant-scoped. Loading a global allow-list across all tenants defeats the purpose of binding the policy to the customer's authz layer.
- `expiry == 0` is reserved for non-expiring receipts (e.g. audit-only captures); operational deployments SHOULD set a finite expiry and rely on the freshness check baked into this template.
