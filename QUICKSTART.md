# Quickstart: gate a tool call on an Asqav receipt

Zero to "an Asqav receipt gates the next tool call" in one file. The flow is
four steps: verify a receipt at the public Asqav endpoint, project the fields it
returns into a Cedar context, evaluate one of the policies in this pack against
that context, and allow or deny the tool call on the decision.

These templates are `forbid` guardrails. They do not grant access on their own,
they take it away when a receipt fails a check. You evaluate them next to the
`permit` policy your host already uses to allow the tool call, and Cedar's rule
that a `forbid` always overrides a `permit` is what turns a bad receipt into a
`Deny`. If you skip the `permit` you get `Deny` on everything, because Cedar is
default-deny.

## Prerequisites

A Cedar evaluator. Two easy options:

- Python: `pip install cedarpy` (the snippets below use it, tested against 4.8.6).
- Rust CLI: `cargo install cedar-policy-cli` gives you `cedar authorize`.

## Step 1: verify a receipt

Asqav exposes a public, unauthenticated verification endpoint. Point it at a
signature id and it returns the receipt plus a cryptographic verdict:

```
GET https://api.asqav.com/api/v1/verify/{signature_id}
```

There is a live example fixture you can call right now with no key:

```bash
curl -s https://api.asqav.com/api/v1/verify/example
```

The response carries the fields you gate on. Trimmed to what matters here:

```json
{
  "agent_id": "agt_example_public_fixture",
  "verified": true,
  "algorithm": "ML-DSA-65",
  "payload": {
    "decision": "allow",
    "risk_class": "medium",
    "action_ref": "c1f3a09a4d2e7f6b8c5a91e3d7b04f2a1c8e6f5d3b9a7c2e4f8d6b1a3c5e7f9d"
  },
  "verification_detail": { "signature_valid": true, "chain_valid": true }
}
```

`verified` is the top-level verdict; a receipt carrying a keyed context digest
reports `verified_keyed` instead (signature valid, digest not third-party
re-derivable without the holder salt). `payload.decision` is the recorded policy
outcome, and its vocabulary is `allow | deny | rate_limit | observation`.
`payload.risk_class` uses `low | medium | high | critical`. Do the signature and
validity-window checks here, upstream of Cedar. Cedar treats the receipt as
structured context, it does not recompute cryptography.

## Step 2: project the receipt onto a Cedar context

Take the verified fields and put them on `context.receipt`. One naming note: the
`receipt_presence_decision_matches` template gates on `policyDecision == "permit"`,
so map the wire value `allow` to the token `permit` (or change the literal in the
template to `allow`). Everything else carries over verbatim.

```python
verify = {  # the JSON from step 1
    "agent_id": "agt_example_public_fixture",
    "verified": True,
    "payload": {"decision": "allow", "risk_class": "medium"},
}

decision = "permit" if verify["payload"]["decision"] == "allow" else verify["payload"]["decision"]

context = {
    "receipt": {
        "policyDecision": decision,
        "risk_class": verify["payload"]["risk_class"],
        "issuer_id": verify["agent_id"],
        "action_ref": "sha256:...",
    }
}
```

If `verify["verified"]` is not `True`, stop here and deny. A receipt that did not
pass verification never reaches the policy.

## Step 3: evaluate a policy from this pack

Load your host `permit` next to a guardrail from this pack, then authorize:

```python
import cedarpy

policies = (
    'permit ( principal, action, resource );\n'
    + open("policies/receipt_presence_decision_matches.cedar").read()
)

request = {
    "principal": {"type": "Agent", "id": "agt_example_public_fixture"},
    "action": {"type": "Tool", "id": "search.web"},
    "resource": {"type": "ToolInvocation", "id": "inv_001"},
    "context": context,   # from step 2
}

result = cedarpy.is_authorized(request, policies, entities="[]")
print(result.decision.value)   # Allow
```

With `policyDecision == "permit"` the guardrail stays silent and the `permit`
wins, so the call is `Allow`. Set `policyDecision` to `deny` and the same
guardrail fires and overrides the `permit`, so the call is `Deny`. Swap in
`policies/receipt_risk_class_ceiling.cedar` and a `risk_class` of `high` or
`critical` denies the call the same way.

## Step 4: allow or deny the tool call

`result.decision.value` is your gate. On `Allow` the agent runs the tool. On
`Deny` you block it and surface the guardrail that fired
(`result.diagnostics.reasons`). That is a verified Asqav receipt gating the next
tool call.

## Where this slots into AWS AgentCore Policy

AWS made Policy in Amazon Bedrock AgentCore generally available on March 3 2026
across thirteen AWS Regions, and it uses Cedar to authorize agents. The design
that matters here is the evaluation boundary: the AgentCore Gateway intercepts
agent-to-tool traffic and evaluates each request against Cedar policies before
allowing or denying the tool call, per tool call rather than per API call
([AWS announcement](https://aws.amazon.com/about-aws/whats-new/2026/03/policy-amazon-bedrock-agentcore-generally-available/),
[AWS Security blog](https://aws.amazon.com/blogs/security/why-policy-in-amazon-bedrock-agentcore-chose-cedar-for-securing-agentic-workflows/)).

This pack lives at that same per-tool-call boundary. The templates here are
Cedar `forbid` policies that gate on a verified Asqav receipt, so they compose
with any host that evaluates Cedar per tool call, wherever that host runs. This
is not an AWS integration and it does not ship with AgentCore. It is a set of
policy files you load into whatever Cedar evaluator you already run.

## Entity shapes

The examples in this repo use illustrative `Agent`, `Tool`, and `ToolInvocation`
entities. A host built on the cedar-for-agents schema generator sees different
names: its stub declares a `User` principal and an `McpServer` resource, and the
generator emits one action per tool as a child of a `call_tool` parent action,
with a per-tool `context` carrying `input` and a common `session`
([cedar-for-agents generator README and example schemas](https://github.com/cedar-policy/cedar-for-agents/tree/main/rust/cedar-policy-mcp-schema-generator)).
The receipt gate is additive: you keep whatever principal, resource, and action
your generated schema uses and add `context.receipt` alongside `session` and
`input`. Adapt the entity names in the example schemas to match your host.
