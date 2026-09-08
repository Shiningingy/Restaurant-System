import { assertEquals, assertStringIncludes } from "@std/assert";
import { escapeHtml, linkifyHtml } from "../functions/notify-order/html.ts";

// The payment link is the whole point of the email: if it is not clickable the
// customer has to copy-paste it off a phone screen, which is where the sale is
// lost. These tests pin the link actually being a link.

Deno.test("payment link becomes a real anchor", () => {
  const url = "https://checkout.stripe.com/c/pay/cs_test_a1B2c3";
  const html = linkifyHtml(`Please pay $24.50 for your order: ${url}`);
  assertStringIncludes(html, `<a href="${url}"`);
  assertStringIncludes(html, `>${url}</a>`);
});

Deno.test("query strings survive as valid href entities", () => {
  const html = linkifyHtml("Pay: https://x.test/p?a=1&b=2");
  // `&` must be escaped inside the attribute; browsers decode it back to `&`.
  assertStringIncludes(html, 'href="https://x.test/p?a=1&amp;b=2"');
});

Deno.test("a trailing full stop is not swallowed into the link", () => {
  const html = linkifyHtml("Pay at https://x.test/abc. Thanks!");
  assertStringIncludes(html, 'href="https://x.test/abc"');
  assertStringIncludes(html, "</a>. Thanks!");
});

Deno.test("the Chinese message links correctly after a full-width colon", () => {
  const url = "https://checkout.stripe.com/c/pay/cs_test_zh";
  const html = linkifyHtml(`请支付您的订单 $24.50：${url}`);
  assertStringIncludes(html, `<a href="${url}"`);
  assertStringIncludes(html, "请支付您的订单");
});

Deno.test("markup in the message cannot break out of the attribute", () => {
  const html = linkifyHtml('<script>alert("x")</script>');
  assertEquals(html.includes("<script>"), false);
  assertStringIncludes(html, "&lt;script&gt;");
});

Deno.test("multiple links are all anchored", () => {
  const html = linkifyHtml("https://a.test/1 and https://b.test/2");
  assertEquals(html.match(/<a href=/g)?.length, 2);
});

Deno.test("a message with no URL is left as plain escaped text", () => {
  const html = linkifyHtml("Your order is ready for pickup. Thanks!");
  assertEquals(html.includes("<a href="), false);
  assertStringIncludes(html, "Your order is ready for pickup. Thanks!");
});

Deno.test("line breaks are preserved for the reader", () => {
  // The div is white-space:pre-wrap, so the newline itself does the work —
  // no <br> rewriting needed.
  assertStringIncludes(linkifyHtml("a\nb"), "white-space:pre-wrap");
  assertStringIncludes(linkifyHtml("a\nb"), "a\nb");
});

Deno.test("escapeHtml covers the attribute-dangerous characters", () => {
  assertEquals(escapeHtml('&<>"'), "&amp;&lt;&gt;&quot;");
});
