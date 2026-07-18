# Le Kreamery — QR Table Ordering

Scan the code on your table, open your bill, order as you go, and pay on your phone or at the till. Orders sync live to the till across every device.

## Run it locally

```bash
npm install
npm run dev
```

Open the printed localhost URL. Pick a table (this simulates scanning the QR/NFC tag), order, then open **Staff · till view** to watch orders arrive and close/settle bills.

## Deploy (free)

Push to GitHub, import into Vercel, accept the Vite defaults. You get an HTTPS URL (needed for Apple Pay later). Every commit auto-redeploys.

## Turn on live cross-device sync (Supabase) — ~3 minutes

Without keys the app runs in **local mode** (one browser only). To sync across phones, tills, and devices, connect a free Supabase backend:

1. Go to supabase.com, sign up, **New project** (pick any name + a database password, free tier). Wait ~1 min for it to finish setting up.
2. Open **SQL Editor → New query**, paste the contents of `supabase-setup.sql` from this repo, click **Run**. (Creates the `tabs` table, enables realtime, sets pilot access.)
3. Open **Settings → API**. Copy two values:
   - **Project URL** (e.g. `https://abcd1234.supabase.co`)
   - **anon public** key (a long token under "Project API keys")
4. Open `src/supabaseConfig.js` and paste them between the quotes:
   ```js
   export const SUPABASE_URL = "https://abcd1234.supabase.co";
   export const SUPABASE_ANON_KEY = "eyJhbGciOi...";
   ```
5. Commit. Vercel redeploys. The landing page now shows **“Live sync on.”**

Now a phone and a laptop open the same URL and see each other's orders in real time.

## Architecture — the part that matters

```
Customer phone ──┐
                 ├── POSAdapter interface ── SupabaseAdapter  (live sync, when keys set)
Till screen ─────┘                        └─ LocalAdapter     (fallback, single browser)
                                          └─ GAAPAdapter / LightspeedAdapter (later)
```

The UI never talks to a backend directly — only through the adapter contract in `src/App.jsx`:

```
openTab(table)            requestBill(table)
getTab(table)             closeBill(table)
addLines(table, lines)    recordPayment(table, method)
listTabs()                subscribe(fn)
```

`SupabaseAdapter` stores each table's bill as a row in the `tabs` table and subscribes to realtime changes. To integrate a real till later, write a `GAAPAdapter` / `LightspeedAdapter` with the same methods against the POS API, then swap the one line at the bottom of the adapter section. The POS stays the source of truth for the bill — the app is a client of it.

## Payments (Yoco / Apple Pay)

`payWithProvider()` in `src/App.jsx` is a stub. Replace it with the Yoco web checkout: get a Yoco account + web keys, call their checkout with the tab total (cents, ZAR), and on success call `POS.recordPayment(table, "Apple Pay")`. Apple Pay on the web also needs domain verification via Yoco's dashboard and HTTPS (Vercel provides it). The provider's iframe handles card data, keeping you out of PCI scope.

## Menu

The full Le Kreamery menu lives as data at the top of `src/App.jsx`: categories → items → option groups (required choices) and paid extras. Items marked "SQ" on the print menu are noted but not orderable online. When a real POS adapter exists, the menu should come from the POS so prices and 86'd items never drift.

## Notes

- **Local mode** (no keys): state lives in `localStorage` + `BroadcastChannel`, so it survives refresh and syncs across tabs in the *same* browser, but not across devices. That's what Supabase adds.
- **Pilot security:** the SQL policy allows open read/write — fine for a trial, tighten before a public launch.
- Payment is simulated until the Yoco step; no money moves.
