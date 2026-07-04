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

## Files in this folder

- `schema.cedarschema` - entity fragment plus the `Receipt` context shape.
- `entities.example.json` - one `Agent`, one `Tool`, one `ToolInvocation`.
- `request.example.json` - a request whose receipt is `policyDecision: "permit"`.

## Expected decision

This template is a `forbid` guardrail. Load it next to a `permit` policy (see the
pack `QUICKSTART.md`). With that `permit` and `policyDecision == "permit"`, the
guardrail stays silent and the call is `Allow`. In isolation, with no `permit`,
Cedar's default-deny returns `Deny`.

## Failure mode

Remove `context.receipt` or set `context.receipt.policyDecision` to anything other than `"permit"` and the guardrail fires, overriding the `permit`, so the decision is `Deny`.

## Notes for host implementors

- Cedar treats the receipt as opaque structured context. Signature verification, key binding, and timestamp freshness are precondition checks that run upstream of this policy gate; do not attempt to recompute signatures inside Cedar.
- The `policyDecision` vocabulary is `permit | deny | rate_limit | none`; only `permit` is authorization-granting in this template.
