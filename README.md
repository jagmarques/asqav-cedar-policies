# asqav-cedar-policies

Reusable Cedar policy templates for agent action receipts. They target the entity-shape contract emitted by [cedar-policy/cedar-for-agents](https://github.com/cedar-policy/cedar-for-agents), so a host can drop a pack in next to whatever policies it already loads. There is no need to modify the WASM surface or the schema generator.

Out-of-tree by design. Tracks the maintainers' scope call on [cedar-for-agents#80](https://github.com/cedar-policy/cedar-for-agents/issues/80): policy templates live outside `cedar-policy/`.

## What is in scope

- Cedar policy text for cryptographic-receipt verification patterns: presence, chain validity, and key binding.
- Examples that consume the entity shapes the cedar-for-agents schema generator already emits.
- Helper entity-shape constructors if/when a Rust crate proves useful.

## What is out of scope

- Forking, vendoring, or patching `cedar-for-agents` itself.
- Defining a new authorization API surface. The runtime call shape stays `isAuthorized(request, schema, policies)`.
- Receipt format itself. That is the IETF Compliance Receipts work. The policies here verify the receipt as the host presents it on `context`.

## Layout

- `policies/` - Cedar policy text files, one pattern per file, named after the predicate.
- `examples/` - Host-side scenarios with the entity-shape inputs each policy expects.

## Status

Initial scaffold. Three starter patterns:

1. `policies/receipt_presence_decision_matches.cedar` - deny unless `context.receipt.policyDecision` matches the action being authorized.
2. `policies/receipt_chain_validity.cedar` - deny unless `context.receipt.prevHash` equals the canonical hash of the prior receipt that the host passed in as `context.priorReceiptHash`.
3. `policies/receipt_third_party_notary.cedar` - deny unless `context.receipt.captureTopology` is `third_party_notary`, the signer is on the host's allow-list, and the receipt has not expired.

Templates are welcome. Open a PR with a Cedar file under `policies/` plus a matching folder under `examples/` showing the entity shape and an `isAuthorized` invocation.

## License

Apache-2.0, matching Cedar's own license so policies and examples can flow back upstream cleanly if the maintainers ever change their scope position.

## Provenance

Maintained by [Asqav](https://asqav.com) alongside the IETF Compliance Receipts draft (`draft-marques-asqav-compliance-receipts`). Contributors from the Cedar community welcome. The repo is not Asqav-specific in its policy text, only in its initial maintainer set.
