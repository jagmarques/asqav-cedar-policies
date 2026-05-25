// Pattern: third-party-notary receipt binding.
//
// Deny the action unless the host attached a signed receipt on context
// whose signing topology is third-party (signer is operated by a notary
// that is neither the principal's home tenant nor the resource's owning
// tenant) AND the signer identifier is on the host's allow-list of
// notaries.
//
// Why this pattern exists separately from receipt_presence: a self-signed
// receipt or a counterparty-signed receipt also satisfies presence, but
// neither satisfies the third-party-notary requirement that some buyers
// and regulators bake into their authorization layer. This template lets
// the host gate on capture topology without re-implementing the check
// across every policy file.
//
// Expected context shape:
//   context.receipt is {
//     signer: String,                // notary identifier, e.g. "notary.example.com"
//     captureTopology: String,       // one of: third_party_notary | counterparty | self_signed | tenant_internal | unknown
//     expiry: Long,                  // unix epoch seconds; 0 means non-expiring
//     ...
//   }
//   context.now is Long               // unix epoch seconds at decision time
//   context.allowedNotaries is Set<String>  // notary signer identifiers the host trusts
//
// Vocabulary for captureTopology mirrors the IETF Compliance Receipts
// `capture_topology` field; only `third_party_notary` clears this gate.
//
// First-class hosts SHOULD layer this template on top of
// receipt_presence_decision_matches (which checks the receipt's
// policyDecision) so a forged unsigned blob never reaches this rule.

@id("receipt-third-party-notary")
forbid (
    principal,
    action,
    resource
)
unless {
    context has receipt &&
    context.receipt has captureTopology &&
    context.receipt.captureTopology == "third_party_notary" &&
    context.receipt has signer &&
    context has allowedNotaries &&
    context.allowedNotaries.contains(context.receipt.signer) &&
    context.receipt has expiry &&
    context has now &&
    (context.receipt.expiry == 0 || context.receipt.expiry > context.now)
};
