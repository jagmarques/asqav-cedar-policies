# Example: receipt-presence with policyDecision match

Minimal host-side scenario for `policies/receipt_presence_decision_matches.cedar`.

## Authorization request

```json
{
  "principal": { "type": "Agent", "id": "agt_demo" },
  "action": { "type": "Tool", "id": "search.web" },
  "resource": { "type": "ToolInvocation", "id": "inv_001" },
  "context": {
    "receipt": {
      "policyDecision": "permit",
      "issuer_id": "org_demo",
      "action_ref": "sha256:..."
    }
  }
}
```

## Expected decision

`isAuthorized` returns `Allow` because the receipt is present and `policyDecision == "permit"`.

## Failure mode

Remove `context.receipt` or set `context.receipt.policyDecision` to anything other than `"permit"` and the policy returns `Deny`.

## Notes for host implementors

- Cedar treats the receipt as opaque structured context. Signature verification, key binding, and timestamp freshness are precondition checks that run before this policy gate; do not attempt to recompute signatures inside Cedar.
- The `policyDecision` vocabulary is `permit | deny | rate_limit | none`; only `permit` is authorization-granting in this template.
