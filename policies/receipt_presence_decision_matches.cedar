// Pattern: receipt-presence with policyDecision match.
//
// Deny the action unless the host attached a signed receipt on context
// AND the receipt's policyDecision matches the action being authorized.
//
// Expected context shape (entity-shape constructor pending):
//   context.receipt is { policyDecision: String, ... }
//
// Vocabulary for policyDecision is `permit | deny | rate_limit | none`;
// this template only admits `permit` since deny / rate_limit / none are
// not authorization-granting decisions.

@id("receipt-presence-decision-matches")
forbid (
    principal,
    action,
    resource
)
unless {
    context has receipt &&
    context.receipt has policyDecision &&
    context.receipt.policyDecision == "permit"
};
