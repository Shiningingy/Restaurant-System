// Supabase Edge Function: notify-order
//
// Sends the customer a "your order is ready" message when an online order's
// status flips to `ready`. The restaurant deploys this on its OWN Supabase
// project with its OWN provider key(s) — we host nothing and never hold a key.
//
// Wire it as a Database Webhook on `online_orders` (UPDATE) so Supabase POSTs
// the changed row here. See docs/EMAIL_SMS_NOTIFICATIONS.md for deployment.
//
// Channels (each optional — only fires when the customer opted in AND the
// matching env vars are set):
//   - Email via Resend  : RESEND_API_KEY, NOTIFY_FROM_EMAIL
//   - SMS   via Twilio  : TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM
//
// Card data never touches this function — preorders are pay-at-pickup.

interface OrderRow {
  id: string;
  status: string;
  customer_name: string | null;
  customer_email: string | null;
  customer_phone: string | null;
  notify_by_email: boolean | null;
  notify_by_sms: boolean | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  record: OrderRow | null;
  old_record: OrderRow | null;
}

const env = (k: string) => Deno.env.get(k) ?? "";

function readyMessage(name: string | null): string {
  const who = name && name.length > 0 ? `${name}, ` : "";
  return `${who}your order is ready for pickup. Thanks!`;
}

async function sendEmail(to: string, body: string): Promise<void> {
  const key = env("RESEND_API_KEY");
  const from = env("NOTIFY_FROM_EMAIL");
  if (!key || !from) return; // email not configured — skip silently
  const resp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to,
      subject: "Your order is ready",
      text: body,
    }),
  });
  if (!resp.ok) {
    console.error("resend failed", resp.status, await resp.text());
  }
}

async function sendSms(to: string, body: string): Promise<void> {
  const sid = env("TWILIO_ACCOUNT_SID");
  const token = env("TWILIO_AUTH_TOKEN");
  const from = env("TWILIO_FROM");
  if (!sid || !token || !from) return; // SMS not configured — skip silently
  const resp = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({ To: to, From: from, Body: body }),
    },
  );
  if (!resp.ok) {
    console.error("twilio failed", resp.status, await resp.text());
  }
}

Deno.serve(async (req) => {
  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  const row = payload.record;
  // Only act on the transition INTO `ready`, so it fires exactly once.
  const becameReady = row?.status === "ready" &&
    payload.old_record?.status !== "ready";
  if (!row || !becameReady) {
    return new Response("ignored", { status: 200 });
  }

  const message = readyMessage(row.customer_name);
  const jobs: Promise<void>[] = [];
  if (row.notify_by_email && row.customer_email) {
    jobs.push(sendEmail(row.customer_email, message));
  }
  if (row.notify_by_sms && row.customer_phone) {
    jobs.push(sendSms(row.customer_phone, message));
  }
  await Promise.all(jobs);

  return new Response(JSON.stringify({ sent: jobs.length }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
