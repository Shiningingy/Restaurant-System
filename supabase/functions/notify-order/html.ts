// Turning a plain-text notification into an HTML email body.
//
// Extracted from index.ts so it can be unit-tested: `index.ts` calls
// `Deno.serve` at import time, so importing it from a test would start a
// server. (Same reason `pay-online/amount.ts` exists.)

export const escapeHtml = (s: string) =>
  s.replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");

/// Trailing characters that are almost certainly sentence punctuation rather
/// than part of the address, e.g. "pay here: https://x.test/abc." — a URL may
/// legally end in any of these, but a customer-facing message far more often
/// ends a sentence than links to something ending in a full stop.
const TRAILING = /[.,;:!?)\]]+$/;

/// Renders [body] as an HTML fragment in which URLs are **real, tappable
/// links**.
///
/// A text-only email leaves a payment link as bare characters the customer must
/// select, copy and paste — enough friction to lose the sale on a phone. Mail
/// clients only linkify reliably when there is an HTML part to work with.
///
/// Escaping runs first and the URL match runs over the *escaped* text, so an `&`
/// inside a query string becomes `&amp;` — exactly what an `href` needs, and
/// browsers decode it back. Matching after escaping is also what keeps a crafted
/// message from breaking out of the attribute: `"`, `<` and `>` are already
/// entities by the time the regex sees them.
export function linkifyHtml(body: string): string {
  const linked = escapeHtml(body).replace(/https?:\/\/[^\s<]+/g, (raw) => {
    const url = raw.replace(TRAILING, "");
    const trailing = raw.slice(url.length);
    return `<a href="${url}" style="color:#1a56db">${url}</a>${trailing}`;
  });
  return '<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;' +
    'font-size:16px;line-height:1.6;white-space:pre-wrap">' +
    `${linked}</div>`;
}
