# Example: receipt-chain validity

Minimal host-side scenario for `policies/receipt_chain_validity.cedar`.

## Authorization request

```json
{
  "principal": { "type": "Agent", "id": "agt_demo" },
  "action": { "type": "Tool", "id": "search.web" },
  "resource": { "type": "ToolInvocation", "id": "inv_042" },
  "context": {
    "receipt": {
      "prevHash": "sha256:9b74c9897bac770ffc029102a200c5de"
    },
    "priorReceiptHash": "sha256:9b74c9897bac770ffc029102a200c5de"
  }
}
```

## Expected decision

`isAuthorized` returns `Allow` because the two hashes match.

## Failure modes

- Hashes differ: `Deny`. The host either drifted from the canonical hashing rule or fed in the wrong predecessor.
- `context.priorReceiptHash` missing: `Deny`. Host MUST always provide a value, even for the first receipt (use `""`).
- `context.receipt.prevHash` missing: `Deny`.

## Canonical hash rule

The host MUST produce both hashes via the same canonical-JSON serialisation it uses when signing. Mismatched canonicalisation produces silent denies that look like a tampered chain. If you are emitting [IETF Compliance Receipts](https://datatracker.ietf.org/doc/draft-marques-asqav-compliance-receipts/), JCS (RFC 8785) over the payload is the reference rule.
