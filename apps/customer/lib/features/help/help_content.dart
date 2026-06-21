/// In-app help content (offline) for the customer ordering app. Mirrors the
/// customer section of docs/USER_GUIDE.md. Content lives in Dart so it doesn't
/// bloat the ARB files; only the screen chrome is localized via l10n.
library;

/// One titled section. A line starting with `- ` renders as a bullet; anything
/// else is a paragraph.
class HelpSection {
  final String title;
  final List<String> body;

  const HelpSection(this.title, this.body);
}

/// The customer guide, in English or Chinese.
List<HelpSection> customerHelp({required bool zh}) => zh ? _zh : _en;

const _en = <HelpSection>[
  HelpSection('Welcome', [
    'Use this app to preorder from restaurants and pick up — no account, no sign-in. Your details stay on this device.',
  ]),
  HelpSection('Add a restaurant', [
    'On the home screen tap Add restaurant, then:',
    '- Scan the QR code the restaurant shows you, or',
    '- Upload a photo of their QR code, or',
    '- Enter the link and key by hand.',
    'The restaurant is saved to your list so you can reorder any time.',
  ]),
  HelpSection('Place an order', [
    '- Open a saved restaurant to see its menu.',
    '- Tap an item to see its description, options and photo, choose how many, and add it to your cart.',
    '- Open the cart and tap Checkout.',
    '- Enter your name (phone is optional), pick a pickup time, and Place preorder.',
  ]),
  HelpSection('Track your order', [
    'Your order moves through Waiting → Preparing → Ready. You’ll see it update on the order screen.',
    '- If the restaurant suggests a different pickup time, tap Approve or Decline.',
    '- When you’ve collected it, tap Picked up to close it out.',
  ]),
  HelpSection('My details', [
    'Save your name, phone and email under My details to fill in checkout faster. You can also choose to be notified when an order is ready (only works if the restaurant has turned that on).',
  ]),
  HelpSection('Good to know', [
    '- Change the language any time from the language menu.',
    '- You pay at the counter when you pick up — no card details are entered here.',
  ]),
];

const _zh = <HelpSection>[
  HelpSection('欢迎使用', ['用本应用向餐厅预订并自取——无需账号、无需登录。您的信息只保存在本设备上。']),
  HelpSection('添加餐厅', [
    '在主界面点添加餐厅，然后：',
    '- 扫描餐厅出示的二维码，或',
    '- 上传他们二维码的照片，或',
    '- 手动输入链接和密钥。',
    '餐厅会保存到您的列表中，方便随时再次下单。',
  ]),
  HelpSection('下单', [
    '- 打开已保存的餐厅即可查看菜单。',
    '- 点菜品查看描述、选项和照片，选择数量后加入购物车。',
    '- 打开购物车，点结账。',
    '- 填写姓名（电话可选），选择取餐时间，然后提交预订单。',
  ]),
  HelpSection('追踪订单', [
    '订单会经历 等待中 → 准备中 → 可取餐，订单界面会实时更新。',
    '- 若餐厅建议了其他取餐时间，请点确认或拒绝。',
    '- 取到餐后，点已取餐以完成订单。',
  ]),
  HelpSection('我的信息', [
    '在我的信息中保存姓名、电话和邮箱，结账时可快速填写。您也可以选择在订单就绪时收到通知（仅当餐厅已开启该功能时有效）。',
  ]),
  HelpSection('温馨提示', ['- 可随时从语言菜单切换语言。', '- 取餐时在柜台付款——此处不输入任何银行卡信息。']),
];
