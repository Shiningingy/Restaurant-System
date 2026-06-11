# Entities

Shared domain entities land here in Phase 1 (freezed models):

`Category`, `MenuItem`, `ModifierGroup`, `Modifier`, `DiningTable`,
`Order`, `OrderLine`, `OrderLineModifier`, `Payment`, `PrintJob`, `SyncLog`.

See `docs/ARCHITECTURE.md` for the relationship sketch and invariants
(price/name snapshots on order lines; voids are status flips, never deletes;
all money columns are integer cents).
