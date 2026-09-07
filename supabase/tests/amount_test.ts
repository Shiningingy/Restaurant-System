// Unit tests for the online-order money math.
//
// Run:  deno test supabase/functions/pay-online/
//
// These exist because the amount logic is duplicated across three languages —
// `OrderTotals.compute` (Dart, canonical), the customer checkout screen (Dart),
// and `amount.ts` (here) — and it HAS drifted before: the customer's tip was
// displayed at checkout and then never charged. The golden vectors at the bottom
// should stay in step with packages/domain/test/order_totals_test.dart.

import { assertEquals } from "@std/assert";
import {
  chargeCents,
  chargeWithTipCents,
  subtotalCents,
  taxCents,
  toCents,
} from "../functions/pay-online/amount.ts";

const line = (
  priceSnapshot: unknown,
  qty: unknown,
  modifiers: unknown[] = [],
) => ({ priceSnapshot, qty, modifiers });

// --- subtotal -------------------------------------------------------------

Deno.test("subtotal: single line", () => {
  assertEquals(subtotalCents([line(1000, 1)]), 1000);
});

Deno.test("subtotal: quantity multiplies", () => {
  assertEquals(subtotalCents([line(1000, 3)]), 3000);
});

Deno.test("subtotal: modifiers add to the unit price before qty", () => {
  // (1000 + 50 + 25) * 2
  assertEquals(
    subtotalCents([
      line(1000, 2, [{ priceDeltaSnapshot: 50 }, { priceDeltaSnapshot: 25 }]),
    ]),
    2150,
  );
});

Deno.test("subtotal: a negative modifier discounts the line", () => {
  assertEquals(
    subtotalCents([line(1000, 1, [{ priceDeltaSnapshot: -150 }])]),
    850,
  );
});

Deno.test("subtotal: several lines sum", () => {
  assertEquals(subtotalCents([line(1000, 2), line(375, 1)]), 2375);
});

Deno.test("subtotal: empty order is zero", () => {
  assertEquals(subtotalCents([]), 0);
});

// --- tax ------------------------------------------------------------------

Deno.test("tax: 13% of 1000 is 130", () => {
  assertEquals(taxCents(1000, 1300), 130);
});

Deno.test("tax: rounds half UP, matching Dart Money.percent", () => {
  // 505 * 13% = 65.65 -> 66
  assertEquals(taxCents(505, 1300), 66);
  // exactly .5 rounds away from zero, as Dart's .round() does
  assertEquals(taxCents(1000, 5), 1);
});

Deno.test("tax: a tax-free shop legitimately charges no tax", () => {
  assertEquals(taxCents(2500, 0), 0);
});

// --- charge ---------------------------------------------------------------

Deno.test("charge: subtotal plus tax, no service fee online", () => {
  // The service fee is deliberately waived online — the customer never saw one.
  assertEquals(chargeCents([line(1000, 1)], 1300), 1130);
});

// --- tip: the regression this module exists to prevent ---------------------

Deno.test("charge WITH tip: the tip is added after tax and is not taxed", () => {
  // subtotal 1000, tax 130, tip 200 -> 1330 (NOT 1000 + 13% of 1200)
  assertEquals(chargeWithTipCents([line(1000, 1)], 1300, 200), 1330);
});

Deno.test("charge WITH tip: a missing tip column charges the plain total", () => {
  assertEquals(chargeWithTipCents([line(1000, 1)], 1300, undefined), 1130);
  assertEquals(chargeWithTipCents([line(1000, 1)], 1300, null), 1130);
});

Deno.test("charge WITH tip: a negative tip never reduces the charge", () => {
  assertEquals(chargeWithTipCents([line(1000, 1)], 1300, -500), 1130);
});

// --- untrusted input ------------------------------------------------------
// `lines` is customer-supplied jsonb, so it can contain anything at all. The
// charge must stay a finite integer rather than becoming NaN.

Deno.test("toCents: coerces safely", () => {
  assertEquals(toCents(150), 150);
  assertEquals(toCents("150"), 150);
  assertEquals(toCents(150.4), 150);
  assertEquals(toCents(150.5), 151);
  assertEquals(toCents(undefined), 0);
  assertEquals(toCents(null), 0);
  assertEquals(toCents("abc"), 0);
  assertEquals(toCents(NaN), 0);
  assertEquals(toCents(Infinity), 0);
  assertEquals(toCents({}), 0);
});

Deno.test("charge: malformed lines never produce NaN", () => {
  const total = chargeCents(
    [
      line("abc", 1),
      line(1000, "2"),
      line(undefined, 1),
      { priceSnapshot: 500, qty: 1, modifiers: null },
      {},
    ],
    1300,
  );
  assertEquals(Number.isFinite(total), true);
  // 0 + 2000 + 0 + 500 + 0 = 2500, +13% = 2825
  assertEquals(total, 2825);
});

Deno.test("charge: a missing modifiers array is treated as none", () => {
  assertEquals(chargeCents([{ priceSnapshot: 1000, qty: 1 }], 0), 1000);
});

// --- golden vectors -------------------------------------------------------
// Keep in step with packages/domain/test/order_totals_test.dart. If a change
// makes one of these fail, the Dart and TypeScript money math have diverged and
// one of them is now charging customers the wrong amount.

Deno.test("golden: realistic bilingual order, 13% ON tax, $2 tip", () => {
  const lines = [
    line(1399, 1), // Tempura shrimp poke
    line(650, 2, [{ priceDeltaSnapshot: 100 }]), // 2x bubble tea, large
  ];
  const subtotal = 1399 + (650 + 100) * 2; // 2899
  assertEquals(subtotalCents(lines), subtotal);
  const tax = Math.round(subtotal * 0.13); // 377
  assertEquals(chargeCents(lines, 1300), subtotal + tax); // 3276
  assertEquals(chargeWithTipCents(lines, 1300, 200), subtotal + tax + 200); // 3476
});
