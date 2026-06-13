# Fundamental Principles

These six rules are non-negotiable. Every feature, dependency, and code review
is checked against them. If a change violates one, the change is wrong — not the principle.

## 1. Offline-first

The restaurant keeps running when the internet doesn't. SQLite on the merchant
tablet is the source of truth, and every POS feature — taking orders, printing,
charging the terminal, reports — must work with airplane mode on. Anything that
needs the network (online ordering, sync) is additive and degrades gracefully
to "not available right now," never blocking in-store service.

## 2. No required subscription

Our pitch to a small restaurant is: use the tablet you already have, and you get
everything you need. No feature may depend on a service *we* host. Optional cloud
features (sync, online preorder) run on the restaurant's own Supabase project —
they register it, they own the data, the free tier is enough. The app must remain
fully functional forever with no cloud configured.

## 3. Money is integer cents

`double` is banned for currency. All amounts are stored and computed as integer
cents through the `Money` value type in `packages/domain`. Rounding happens only
at explicit, documented points (e.g. tax calculation, half-up). Formatting to
"$12.34" happens only at the presentation edge.

## 4. Hardware abstraction

Printer and payment-terminal SDKs may only be imported inside their driver folder
(`features/printing/drivers/`, `features/payments/drivers/`). Everything else
talks to the `PrinterDriver` / `PaymentTerminal` interfaces in `packages/domain`.
Every hardware integration ships with a manual or noop fallback, so a missing or
broken device never blocks taking an order.

## 5. Never touch card data

Card numbers never pass through our code, our database, or the restaurant's
Supabase. In-store payments are semi-integrated: we push the amount to the
terminal and record the result. Any future online payment uses processor-hosted
checkout only (the customer pays on the processor's page; we receive a result).
This keeps us and the restaurant in the lowest PCI scope.

A payment result is only trusted when a **trusted backend confirms it** — never
the customer's device or the merchant tablet. Confirmation (and the amount being
charged) is verified against the processor by the restaurant's own Supabase Edge
Function, which holds the processor's secret key. Secret keys never ship in any
client app; only that function may mark an order paid.

## 6. Online is opt-in and trust-gated

By default the app is a self-contained **offline internal restaurant system** —
it needs no cloud and no account. Online capabilities (sync, online preorder,
online payment) switch on only when the **merchant connects their own trusted
backend** (their Supabase project, their payment processor). We host nothing.

And we only *ship* an online capability once it has a security model that earns
the trust of **both** sides — the merchant's private business data stays private,
and customers' data and payments are protected. No online feature goes live to a
real restaurant on a "we'll secure it later" basis; the trust model is part of
the feature, not a follow-up. (See the cloud-security gate in ROADMAP.md.)
