# Example: receipt risk-class ceiling

Minimal host-side scenario for `policies/receipt_risk_class_ceiling.cedar`.

## When to use this template

Reach for this policy when the host wants a hard stop on tool calls whose
verified receipt reports a high or critical risk level, regardless of what the
receipt's decision field says. It runs the risk cut at the authorization
boundary instead of leaving it to an upstream pipeline that a caller might skip.

The `risk_class` value comes straight off the receipt the host verified. Asqav
records emit a four-level set: `low | medium | high | critical`. The host
normalises whatever it verified into that set before placing it on
`context.receipt.risk_class`.

## Files in this folder

- `schema.cedarschema` - entity fragment plus the `Receipt` context shape used here.
- `entities.example.json` - one `Agent`, one `Tool`, one `ToolInvocation`.
- `request.example.json` - a request whose receipt is `risk_class: "high"`.

## Expected decision

The sample request carries `risk_class: "high"`, so `isAuthorized` returns
`Deny` and cites the `forbid` policy id `receipt-risk-class-ceiling`.

## Failure modes

- `risk_class` is `high` or `critical`: `Deny`. That is the whole point of the ceiling.
- `risk_class` is `low` or `medium`: this template stays silent, so the call is
  allowed unless some other policy in the pack denies it.
- `context.receipt` or `context.receipt.risk_class` missing: this template stays
  silent. Pair it with `receipt_presence_decision_matches` if you want a missing
  receipt to fail closed.

## Local smoke test

See the pack `QUICKSTART.md` for a runnable `cedarpy` snippet that evaluates
this request and prints the `Deny`. Flip `risk_class` to `"medium"` and rerun to
watch the ceiling stay silent.
