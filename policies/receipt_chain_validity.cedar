// Pattern: receipt-chain validity.
//
// Deny the action unless context.receipt.prevHash equals the canonical
// hash of the prior receipt that the host's verifier passed in on context.
//
// The host is responsible for computing and supplying both fields; Cedar
// only checks string equality. The host MUST pass `context.priorReceiptHash`
// as the canonical-JSON-serialised SHA-256 of the previous receipt, and the
// signed receipt itself MUST carry `prevHash` in the same canonical form.
//
// Expected context shape:
//   context.receipt is { prevHash: String, ... }
//   context.priorReceiptHash is String
//
// First receipt in a chain: the host passes priorReceiptHash="" and the
// receipt carries prevHash="". Both equal, gate passes.

@id("receipt-chain-validity")
forbid (
    principal,
    action,
    resource
)
unless {
    context has receipt &&
    context.receipt has prevHash &&
    context has priorReceiptHash &&
    context.receipt.prevHash == context.priorReceiptHash
};
