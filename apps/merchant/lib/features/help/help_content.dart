/// In-app user guide content (offline). A concise orientation that mirrors the
/// full manual in docs/USER_GUIDE.md — keep the two roughly in sync when flows
/// change. Content lives in Dart (not the ARB) so the paragraphs don't bloat
/// the localization files; only the screen chrome is localized via l10n.
library;

/// One titled section of the guide. A line starting with `- ` renders as a
/// bullet; a line starting with `# ` renders as a sub-heading; anything else is
/// a paragraph.
class HelpSection {
  final String title;
  final List<String> body;

  const HelpSection(this.title, this.body);
}

/// The merchant guide, in English or Chinese.
List<HelpSection> merchantHelp({required bool zh}) => zh ? _zh : _en;

const _en = <HelpSection>[
  HelpSection('Welcome', [
    'This is your point-of-sale. It works fully offline — no internet needed for daily use. Cloud features (online orders, backup) are optional and run on your own account.',
    'The tabs down the side are: Orders, Menu, Inbox, Reports, Settings and Admin.',
  ]),
  HelpSection('First-time setup (Settings)', [
    '- Tax: set your Sales tax rate.',
    '- Printing: set up your Kitchen and Receipt printers — each by network (IP + port 9100) or a USB / Windows printer. Pick paper width (58/80mm), turn on Chinese if your printer needs it for second names, and switch on the cash drawer for the receipt printer. Test print each.',
    '- Checkout: set a Service fee and Discount presets if you use them.',
    '- Tables: add your tables for dine-in.',
    '- Business name & receipt footer for printed receipts.',
  ]),
  HelpSection('Staff & roles (Admin)', [
    'Create the first owner to turn on role-based access. Add staff with a name, a role (Owner / Manager / Server) and a 4-digit PIN.',
    'Staff sign in with name + PIN, so two people can share a PIN safely.',
  ]),
  HelpSection('Taking an order', [
    '- Start a Dine-in (pick a table) or Takeout order on the Orders tab.',
    '- Tap a category, then tap items. Choose options if asked, then Add to order.',
    '- Use ＋ / － to change quantity; － on a single item voids it.',
    '- Add discount if needed (large discounts ask for a manager PIN).',
    '- Send to kitchen prints the kitchen ticket.',
  ]),
  HelpSection('Taking payment', [
    'Tap Pay. Then:',
    '- Cash: optionally type Cash tendered to see the Change due, then tap Cash.',
    '- Card: tap Card, key the amount on your terminal, record Approved or Declined.',
    '# Splitting the bill',
    '- By amount: lower the Amount and take several payments.',
    '- By item: tap Split by item, tick each person’s items, charge that group (it includes its share of tax and fees), and repeat until everything is paid.',
    'When the whole balance is paid the order closes and the receipt prints.',
  ]),
  HelpSection('Menu', [
    '- Create a category, then add items (name + price; optional code, second name, description, photos, options).',
    '- Load sample menu adds a demo menu to try ordering and printing.',
    '- Import from photo (Windows/Android) reads items from a menu photo.',
  ]),
  HelpSection('Customer screen & self-order kiosk', [
    'If you have a second screen, the POS can drive it. Set it up in Settings → Customer display.',
    '- Display mode: Order display (mirrors the bill, with rotating promo when idle), Self-order kiosk (customers order themselves), or Hybrid (promo + “Tap to order” when idle, mirror while you ring up).',
    '- Open customer display puts it on the second screen — frameless with no close button so a customer can’t misclick it. You Hide or Close it from Settings; the POS itself can go Full screen (or press F11).',
    '- Promo: add Promo messages and Promo photos that rotate on the idle screen.',
    '# Self-order',
    'A customer builds their order on the kiosk and taps Place order. It lands on your Orders board in a Self-order section with a pickup number (K0, K1, K2…) shown on the card, so you can match the order to the customer.',
    'They pay at the counter (the kiosk total already includes tax). Pay-at-kiosk is an option you can switch on for later, when card payment is available.',
    '# Tablet kiosks',
    'You can also put out tablets as extra self-order stations — they run the customer app in kiosk mode and look the same. Connect a tablet to your restaurant, then on its menu open ⋮ → Set up kiosk, sign in with your store login and give it a number. Only your store login can enable it (customers can’t); exit with a long-press on the top-left corner. Tablet-kiosk orders come into your Inbox labelled “Kiosk N” (they need cloud setup).',
  ]),
  HelpSection('Online orders (Inbox)', [
    'Needs cloud setup and a published menu. Tap Publish menu to send your current menu out.',
    '- New preorders: Accept, Reject, or Propose time.',
    '- Mark ready when the food is done; the customer is notified.',
    '- Mark picked up when collected — either side can complete it.',
  ]),
  HelpSection('Reports', [
    'The Reports tab shows one day at a time: amount collected, item sales, and order history. Tap a closed order to reprint its receipt.',
  ]),
  HelpSection('If something goes wrong', [
    '- Printer not printing: Settings → Printing → Search for printers, check the IP / same network / port 9100, Test print.',
    '- Online orders show an auth error: in Settings → Cloud sync, sign out and back in.',
    '- Sign-in says “no host in URL”: add https:// to the front of your project URL.',
    'The full manual is in docs/USER_GUIDE.md.',
  ]),
];

const _zh = <HelpSection>[
  HelpSection('欢迎使用', [
    '这是您的收银系统。它可完全离线使用——日常营业无需网络。云功能（在线订单、备份）是可选的，运行在您自己的账号上。',
    '侧边的标签依次为：订单、菜单、收件箱、报表、设置和管理。',
  ]),
  HelpSection('首次设置（设置）', [
    '- 税务：设置您的销售税率。',
    '- 打印：分别设置厨房打印机和小票打印机——每台可用网络（IP + 端口 9100）或 USB / Windows 打印机。选择纸宽（58/80 毫米），如打印机需要可开启中文（用于第二名称），并为小票打印机开启钱箱。逐台测试打印。',
    '- 结账：如需要，设置服务费和折扣预设。',
    '- 餐桌：添加堂食用的餐桌。',
    '- 商家名称与小票页脚：用于打印的小票。',
  ]),
  HelpSection('员工与角色（管理）', [
    '创建第一个店主以启用角色权限。为员工设置姓名、角色（店主 / 经理 / 服务员）和 4 位 PIN。',
    '员工用姓名 + PIN 登录，因此即便两人 PIN 相同也不会混淆。',
  ]),
  HelpSection('开单点餐', [
    '- 在订单标签开一笔堂食（选餐桌）或外带订单。',
    '- 点一个分类，再点菜品。如有选项请选择，然后加入订单。',
    '- 用 ＋ / － 增减数量；数量为 1 时的 － 会作废该项。',
    '- 如需要可添加折扣（大额折扣需经理 PIN）。',
    '- 发送到厨房会打印厨房单。',
  ]),
  HelpSection('收款', [
    '点收款。然后：',
    '- 现金：可选输入实收现金以查看应找零，然后点现金。',
    '- 刷卡：点刷卡，在终端上输入金额，记录已批准或已拒绝。',
    '# 拆分账单',
    '- 按金额：调低金额并多次收款。',
    '- 按菜品：点按菜品拆分，勾选每人的菜品，为该组收款（已含其应分摊的税费与费用），重复直到全部付清。',
    '全部余额付清后，订单关闭并打印小票。',
  ]),
  HelpSection('菜单', [
    '- 先建分类，再添加菜品（名称 + 价格；可选编号、第二名称、描述、照片、选项）。',
    '- 加载示例菜单会添加一个演示菜单以试用点单和打印。',
    '- 从照片导入（Windows/安卓）可从菜单照片识别菜品。',
  ]),
  HelpSection('顾客屏幕与自助点餐', [
    '如果您有第二块屏幕，收银系统可以驱动它。在设置 → 顾客屏幕中设置。',
    '- 显示模式：订单显示（同步显示账单，空闲时轮播促销）、自助点餐机（顾客自行点餐）或混合（空闲时显示促销与“点击点餐”，您结账时同步显示账单）。',
    '- 打开顾客屏幕会将其放到第二块屏幕——无边框、无关闭按钮，顾客不会误点。可在设置中隐藏或关闭；收银主窗口也可全屏（或按 F11）。',
    '- 促销：添加在空闲屏幕轮播的促销信息和促销图片。',
    '# 自助点餐',
    '顾客在点餐机上下单并点下单。订单会出现在您的订单板的“自助点餐”区域，卡片上带有取餐号（K0、K1、K2…），方便您对应到顾客。',
    '顾客在柜台付款（点餐机显示的金额已含税）。“在点餐机付款”是一个可开启的选项，待刷卡付款上线后使用。',
    '# 平板自助点餐机',
    '您还可以摆放平板作为额外的自助点餐站——它们运行顾客端 app 的点餐机模式，外观一致。先把平板连接到您的餐厅，然后在其菜单页打开 ⋮ → 设置自助点餐机，使用您的商家登录信息登录并指定一个编号。只有掌握商家登录信息的人才能开启（顾客无法开启）；长按左上角即可退出。平板点餐机的订单会进入您的收件箱，并标记为“自助机 N”（需要云端设置）。',
  ]),
  HelpSection('在线订单（收件箱）', [
    '需要云设置和已发布的菜单。点发布菜单发送当前菜单。',
    '- 新预订单：接受、拒绝或建议时间。',
    '- 做好后点标记为就绪；系统会通知顾客。',
    '- 取餐后点标记为已取餐——任一方都可完成。',
  ]),
  HelpSection('报表', ['报表标签每次显示一天：收款金额、菜品销量和历史订单。点已结订单可重新打印小票。']),
  HelpSection('遇到问题时', [
    '- 不出单：设置 → 打印 → 搜索打印机，检查 IP / 是否同一网络 / 端口 9100，测试打印。',
    '- 在线订单报授权错误：在设置 → 云同步中退出再重新登录。',
    '- 登录提示“no host in URL”：在项目 URL 开头补上 https://。',
    '完整手册见 docs/USER_GUIDE.md。',
  ]),
];
