// The money math for an online order, isolated from the network so it can be
// unit-tested — this is the one place that decides what a customer is charged,
// so it should be small enough to read in full and covered by tests.
//
// Mirrors `OrderTotals.compute` in packages/domain for the ONLINE case:
//   * the service fee is waived online (the customer is never shown one),
//   * tax is half-up on the subtotal,
//   * the customer's chosen tip is added AFTER tax — tips are not taxed.
//
// All values are integer cents. `double` never touches currency (PRINCIPLES #3).
//
// ⚠️ This duplicates Dart logic in another language, so the two CAN drift. The
// shared golden vectors in `amount_test.ts` exist to catch that; keep them in
// sync with `packages/domain/test/order_totals_test.dart`.

/// Coerces an untrusted JSON value to integer cents. The order `lines` are
/// customer-supplied jsonb, so anything can be in there: only a finite number
/// counts, and it is rounded to a whole cent. Everything else reads as 0 rather
/// than producing `NaN` and poisoning the whole total.
export function toCents(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? Math.round(n) : 0;
}

/// The pre-tax subtotal: Σ((unit price + Σ modifier deltas) × qty).
export function subtotalCents(lines: unknown[]): number {
  let subtotal = 0;
  for (const raw of lines ?? []) {
    const l = (raw ?? {}) as Record<string, unknown>;
    let unit = toCents(l.priceSnapshot);
    for (const m of (l.modifiers as Record<string, unknown>[] ?? [])) {
      unit += toCents((m ?? {}).priceDeltaSnapshot);
    }
    subtotal += unit * toCents(l.qty);
  }
  return subtotal;
}

/// Tax on a subtotal, in basis points, rounded half-up — matching the Dart
/// `Money.percent` used to show the customer their estimate.
export function taxCents(subtotal: number, taxRateBp: number): number {
  const bp = Number.isFinite(taxRateBp) ? taxRateBp : 0;
  return Math.round((subtotal * bp) / 10000);
}

/// The order total the customer agreed to at checkout, EXCLUDING the tip.
export function chargeCents(lines: unknown[], taxRateBp: number): number {
  const subtotal = subtotalCents(lines);
  return subtotal + taxCents(subtotal, taxRateBp);
}

/// The full amount to charge: order total plus the customer's tip.
///
/// The customer's checkout screen shows `subtotal + tax + tip` as the figure
/// they are agreeing to pay, so this is what must reach the processor. Charging
/// the tip-free total instead silently loses the staff their tip — which is
/// exactly the bug this function exists to make impossible to reintroduce.
export function chargeWithTipCents(
  lines: unknown[],
  taxRateBp: number,
  tipCents: unknown,
): number {
  const tip = toCents(tipCents);
  return chargeCents(lines, taxRateBp) + (tip > 0 ? tip : 0);
}
