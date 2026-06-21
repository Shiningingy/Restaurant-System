<!-- Language: English · 中文版见 USER_GUIDE.zh.md -->

# Restaurant System — User Guide

A plain-language guide for shop owners and staff. No technical knowledge needed.

> 📷 _Screenshots are marked like this. They're placeholders — drop in a real screen capture from your tablet/PC where you see them._

The app comes in two parts:

- **Merchant app** — your point-of-sale (POS). Runs on a Windows 10/11 PC or an Android tablet. This is most of the guide.
- **Customer app** — what your customers use to preorder for pickup. Covered in [§9](#9-the-customer-app).

Everything works **offline** — the POS keeps running with no internet. The cloud features (online orders, backup) are optional and run on your own account; nothing is hosted by us, and there is no required subscription.

---

## Contents

1. [Getting around](#1-getting-around)
2. [First-time setup](#2-first-time-setup)
3. [Staff & roles](#3-staff--roles)
4. [Taking an order](#4-taking-an-order)
5. [Taking payment](#5-taking-payment)
6. [Managing the menu](#6-managing-the-menu)
7. [Online orders (Inbox)](#7-online-orders-inbox)
8. [Reports](#8-reports)
9. [The customer app](#9-the-customer-app)
10. [Cloud backup & privacy](#10-cloud-backup--privacy)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Getting around

When you open the merchant app you'll see tabs along the side/bottom:

| Tab | What it's for |
|---|---|
| **Orders** | Take dine-in and takeout orders, send to kitchen, take payment |
| **Menu** | Your categories, items, prices, modifiers, photos |
| **Inbox** | Online preorders from customers (needs cloud setup) |
| **Reports** | Daily sales totals and order history |
| **Settings** | Tax, printer, checkout options, cloud, language |
| **Admin** | Staff accounts and roles |

> 📷 _[screenshot: main screen with the tabs]_

**Language:** change it any time in **Settings → Language** (English, 中文, or follow the system). Receipts print in English.

---

## 2. First-time setup

Open **Settings** and work down the list. You only do this once.

### Tax
- **Sales tax rate** — your local rate (e.g. 13). Applied to new orders. Changing it later does **not** rewrite existing orders.

### Checkout
- **Service fee** — an automatic fee on every order (set 0% for none).
- **Discount presets** — quick discount buttons, e.g. `5, 10, 15`.
- **Discount without manager** — discounts up to this size are free for any staff; bigger ones ask for a manager PIN.

### Printing
- **Network printer** — your receipt printer's IP address and port (usually **9100**). Pick **58 mm** or **80 mm** paper to match your printer.
  - Tap **Search for printers** to scan your network, or type the IP by hand.
  - **Test print** sends a test page so you can confirm it works.
- **Business name on receipts** and **Receipt footer** — what prints at the top and bottom of customer receipts.
- **Print queue** — shows pending/failed print jobs; you can retry or discard.

> 📷 _[screenshot: Settings → Printing]_

### Tables (for dine-in)
- Add your tables (e.g. `1, 2, Patio A`). Dine-in orders ask which table.

### Online ordering (optional)
- **Minimum pickup time** — the soonest a customer may ask to pick up (sent with your menu).
- **Alert sound on new order** — plays a sound when a new online order arrives.

### Second name display
If your items have a second name (e.g. a Chinese name under the English one), choose where it shows:
- **On order screen**, **On kitchen ticket**, **On customer receipt** — each can be on or off.
- **Second name language** — customers whose app is in this language see the second name first.

### Payments
- **Card terminal: manual entry** — for now, staff key the amount into your standalone card machine and record the result. (Integrated Moneris Go support comes later.)

---

## 3. Staff & roles

Optional, but recommended once you have more than one person on the till.

1. Go to **Admin → Create the first owner**. Until you do this, everyone has full access.
2. Add staff under **Staff & roles**. Each person gets a **name**, a **role**, and a **4-digit PIN**.

**Roles:**
- **Owner** — full access, including managing staff.
- **Manager** — can approve large discounts and day-to-day management.
- **Server** — takes orders and payments.

Staff sign in with their **name + PIN** (so two people can share the same PIN safely). Use **Switch user** to hand the tablet to someone else, or **Sign out**.

> 📷 _[screenshot: Admin → Staff & roles]_

---

## 4. Taking an order

1. On the **Orders** tab, start a **Dine-in** (pick a table) or **Takeout** order.
2. Tap a **category**, then tap **items** to add them to the order on the right.
   - If an item has options (e.g. *Size*, *Add-ons*), a picker pops up — choose, then **Add to order**.
3. Adjust as needed:
   - **＋ / －** change the quantity.
   - The **－** on a single-quantity line **voids** it (kept in history, never silently deleted).
4. **Discount** (optional): tap **Add discount**, pick a preset or type a percent. A discount above your "without manager" limit asks for a manager PIN.
5. **Send to kitchen** prints the kitchen ticket. You can keep editing and **Reprint kitchen ticket** if needed.

The totals panel shows **Subtotal → Discount → Service fee → Tax → Total** so you always see how the price is built.

> 📷 _[screenshot: order screen with items and totals]_

---

## 5. Taking payment

Tap **Pay {amount}**. The payment window opens with the amount due.

### Cash (with change)
1. The **Amount** is already the balance.
2. (Optional) type what the customer handed you in **Cash tendered** — the window shows **Change due** automatically.
3. Tap **Cash**. Done.

> 📷 _[screenshot: payment window showing Change due]_

### Card
1. Tap **Card**.
2. Key that amount into your standalone card machine.
3. Record what the machine showed: **Approved** or **Declined**. A decline is logged but not counted as paid.

### Splitting the bill

**Two ways**, depending on how the customers want to split:

**A. Split by amount** — lower the **Amount** to part of the bill and take a payment; repeat for each person. The order stays open until the balance reaches zero.

**B. Split by item** *(when an order has 2+ items)* — tap **Split by item**:
1. Tick the items for one person.
2. The button shows **Charge selected — {amount}**. That amount already includes that group's fair share of tax, service fee and discount.
3. Tap it, then take **Cash** or **Card** as usual.
4. Those items are marked **Paid** and drop off the list. Repeat for the next person until everything's paid.

> 📷 _[screenshot: Split by item with some items ticked]_

When the **whole balance** is paid, the order closes and the **customer receipt** prints automatically. A partial payment keeps the order open.

---

## 6. Managing the menu

On the **Menu** tab:

- **Categories** group your items (e.g. *Appetizers*, *Rolls*). Create a category first, then add items.
- **New item** — set a **Name** and **Price**. Optional extras:
  - **Item code** (e.g. `A01`), **Second name** (e.g. a native-language name), **Description**.
  - **Custom fields** (Ingredients, Allergens, Spice level, Notes…).
  - **Photos** (save the item first, then add photos).
  - **Modifier groups** — reusable option sets like *Size* or *Add-ons*, with min/max picks and price changes (can be negative, e.g. `-0.50`).
- **Load sample menu** — adds a 29-item bilingual demo menu (Yee Sushi) so you can try ordering and printing right away.
- Delete an item or category with the trash action (past orders keep their own snapshots, so history is never affected).

> 📷 _[screenshot: Menu tab with categories and items]_

### Import a menu from a photo
On Windows or Android you can speed up data entry with **Import from photo**:
1. Build a **template** once — drag a box over one item on a sample photo and mark where the **Code / Name / Price** sit.
2. **Pick menu photo**, choose the template and category, then **Capture item** for each dish; the app reads the text for you.
3. **Review drafts** and **Save all**.

> Note: photo import needs an OCR language pack. On Windows: **Settings → Time & language → Language** (add Chinese or English). Not available on Linux.

---

## 7. Online orders (Inbox)

This lets customers preorder for pickup. It needs the optional cloud setup ([§10](#10-cloud-backup--privacy)) and a published menu.

1. In **Inbox**, tap **Publish menu** to send your current menu to your storefront. Re-publish whenever the menu changes.
2. Customers add your restaurant by scanning your **Customer connect code** (Settings) and place preorders.

As orders come in:

- **New preorders** — for each you can **Accept**, **Reject**, or **Propose time** (suggest a different pickup time; the customer then approves or declines).
- **Preparing** — accepted orders. Tap **Mark ready** when the food's done; the customer is notified.
- **Ready for pickup** — when the customer collects, tap **Mark picked up** to complete the order. Either you or the customer can do this, and it updates on both sides.

> 📷 _[screenshot: Inbox with new / preparing / ready sections]_

---

## 8. Reports

The **Reports** tab shows one day at a time (use **Previous day / Next day**):

- **Collected** — total taken, broken down by payments and tips.
- **Item sales** — how many of each item sold.
- **Order history** — every closed order (voided ones are marked); tap one to **Reprint receipt**.
- **Gross sales**, **Tax**, **Tips**, **Total collected** summaries.

> 📷 _[screenshot: Reports for a day]_

---

## 9. The customer app

What your customers do (for your reference when helping them):

1. **Add your restaurant** — scan your **Customer connect code**, upload a photo of it, or type the link by hand. No account or sign-in.
2. **Browse the menu** — tap an item to see its description, options and photo, choose the **quantity**, then add to cart.
3. **Checkout** — enter a name (phone optional), pick a **pickup time** (no earlier than your minimum), and **Place preorder**.
4. **Track it** — they see status update from *Waiting → Preparing → Ready*. If you proposed a different time, they **Approve** or **Decline**. When they collect, they (or you) mark it **Picked up**.
5. **My details** — they can save a name/phone/email and notification preferences for faster checkout.

> 📷 _[screenshot: customer app menu + checkout]_

---

## 10. Cloud backup & privacy

The POS is **offline-first** — the tablet's own storage is the source of truth, and everything works with no internet.

Cloud features (online orders + backup) are **optional** and run on **your own free Supabase project** — we host nothing:

- **Settings → Cloud sync**: sign in with the restaurant login you created, enter your **Project URL** and **anon key**, then **Sync now**.
- **Restore from cloud** pulls your full history onto a new or wiped tablet (existing data is merged, never wiped).
- Your private data stays private: customers using the ordering app can only read your published menu and their own order — never your sales, staff, or other customers' orders.

> Setup is a one-time technical step — see [CLOUD_SECURITY.md](CLOUD_SECURITY.md). If you're not using cloud features, you can ignore this whole section.

---

## 11. Troubleshooting

| Problem | Fix |
|---|---|
| **Printer not found / nothing prints** | Settings → Printing → **Search for printers**, or check the printer's IP, that it's on the same network, and the port is **9100**. Use **Test print** to confirm. |
| **Online orders show an auth error (400)** | In Settings → Cloud sync, **Sign out and sign back in** to refresh the login. |
| **Sign-in says "no host specified in URL"** | Your Project URL is missing `https://` at the front — add it. |
| **"No OCR language pack found"** (photo import) | Windows → Settings → Time & language → Language — add Chinese or English. |
| **App won't run on the shop PC** | It needs **Windows 10 or 11** (Windows 7/8 are not supported). An Android tablet is an alternative. |
| **A customer's "Picked up" / "Approve time" button errors** | The restaurant's cloud project needs its security rules applied — a one-time setup step (see CLOUD_SECURITY.md). |

---

_Questions or something here out of date? Note it and we'll fix the guide._
