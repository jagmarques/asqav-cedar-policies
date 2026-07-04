// Pattern: receipt risk-class ceiling.
//
// Deny the action when the verified receipt carries a risk_class at or above
// the ceiling the host wants to block at the tool-call boundary. The default
// ceiling here blocks "high" and "critical"; a host that wants a different
// line edits the comparison or swaps to a host-supplied deny set.
//
// The risk_class value is projected verbatim from the receipt the host
// verified upstream. The four-level vocabulary low | medium | high | critical
// is the risk-level set Asqav records emit; the host normalises whatever it
// verified into that set before placing it on context.
//
// Expected context shape:
//   context.receipt is { risk_class: String, ... }
//
// This is a forbid-when template: it stays silent (no opinion) on low and
// medium and only fires on high or critical. Layer it on top of
// receipt_presence_decision_matches so an unsigned blob never reaches here.

@id("receipt-risk-class-ceiling")
forbid (
    principal,
    action,
    resource
)
when {
    context has receipt &&
    context.receipt has risk_class &&
    (context.receipt.risk_class == "high" ||
     context.receipt.risk_class == "critical")
};
