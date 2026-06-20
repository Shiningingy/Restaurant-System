// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '餐厅系统';

  @override
  String get navOrders => '订单';

  @override
  String get navMenu => '菜单';

  @override
  String get navInbox => '收件箱';

  @override
  String get navReports => '报表';

  @override
  String get navSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonAdd => '添加';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRemove => '移除';

  @override
  String get commonDone => '完成';

  @override
  String get orderDineIn => '堂食';

  @override
  String get orderTakeout => '外带';

  @override
  String get orderOnline => '在线';

  @override
  String orderTableLabel(String label) {
    return '$label 号桌';
  }

  @override
  String get payCash => '现金';

  @override
  String get payCard => '刷卡';

  @override
  String get payCardKeyed => '刷卡（手输）';

  @override
  String get ordersTitle => '未结订单';

  @override
  String get ordersEmpty => '暂无未结订单 — 开始一笔堂食或外带订单。';

  @override
  String ordersLoadFailed(String error) {
    return '加载订单失败：$error';
  }

  @override
  String get noTablesYet => '尚未添加餐桌 — 请在“设置”中添加。';

  @override
  String get pickTable => '选择餐桌';

  @override
  String get ordVoidOrder => '作废订单';

  @override
  String get ordDineInTitle => '堂食订单';

  @override
  String get ordTakeoutTitle => '外带订单';

  @override
  String get ordOnlineTitle => '在线订单';

  @override
  String get ordOrderTitle => '订单';

  @override
  String get ordVoidConfirmTitle => '作废此订单？';

  @override
  String get ordVoidConfirmBody => '该订单将作为已作废保留在历史记录中。';

  @override
  String get ordKeep => '保留';

  @override
  String get ordNoMenuYet => '暂无菜单 — 请在菜单中添加分类和菜品。';

  @override
  String get ordTapToAdd => '点按菜品以加入订单。';

  @override
  String get ordVoidLine => '作废此项';

  @override
  String get ordDecrease => '减少';

  @override
  String ordQtyMultiplier(int qty) {
    return 'x$qty';
  }

  @override
  String get ordSubtotal => '小计';

  @override
  String ordTaxPercent(String rate) {
    return '税 ($rate%)';
  }

  @override
  String get ordTotal => '合计';

  @override
  String ordPaidMethod(String method) {
    return '已付 — $method';
  }

  @override
  String ordTipSuffix(String tip) {
    return '（小费 $tip）';
  }

  @override
  String get ordBalanceDue => '应付余额';

  @override
  String get ordReprintKitchenTicket => '重新打印厨房单';

  @override
  String get ordSendToKitchen => '发送到厨房';

  @override
  String ordPayAmount(String amount) {
    return '收款 $amount';
  }

  @override
  String get ordClosed => '已关闭';

  @override
  String get ordNoPrinterConfigured => '未配置打印机 — 请在设置中添加。';

  @override
  String get ordKitchenTicketQueued => '厨房单已加入打印队列。';

  @override
  String get ordPartialPaymentRecorded => '已记录部分付款 — 订单保持未结。';

  @override
  String get ordCardDeclined => '刷卡被拒 — 未记为已付。';

  @override
  String ordPaymentFailed(String message) {
    return '支付失败：$message';
  }

  @override
  String get menuTitle => '菜单';

  @override
  String get menuItems => '菜品';

  @override
  String get menuModifierGroups => '选项组';

  @override
  String get menuHiddenFromOrderScreen => '在点单界面隐藏';

  @override
  String get menuCategory => '分类';

  @override
  String get menuCreateCategoryToStart => '创建一个分类以开始您的菜单。';

  @override
  String get menuNewCategory => '新建分类';

  @override
  String get menuEditCategory => '编辑分类';

  @override
  String get menuName => '名称';

  @override
  String get menuVisibleOnOrderScreen => '在点单界面显示';

  @override
  String get menuItem => '菜品';

  @override
  String get menuNoItemsInCategory => '此分类暂无菜品。';

  @override
  String get menuLoadSample => '加载示例菜单';

  @override
  String get menuLoadSampleConfirm =>
      '添加忆寿司示例菜单（7 个分类、29 个中英双语菜品）以试用点单和打印？重复加载只会刷新相同的菜品。';

  @override
  String get menuLoadSampleDone => '示例菜单已加载。';

  @override
  String get menuNewItem => '新建菜品';

  @override
  String get menuEditItem => '编辑菜品';

  @override
  String get menuPrice => '价格';

  @override
  String get menuDeleteItem => '删除菜品';

  @override
  String menuDeleteItemConfirm(String name) {
    return '删除“$name”？此操作无法撤销。';
  }

  @override
  String get menuDeleteCategory => '删除分类';

  @override
  String menuDeleteCategoryConfirm(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '删除“$name”及其下的 $count 个菜品？此操作无法撤销。',
      zero: '删除“$name”？此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get modGroup => '选项组';

  @override
  String get modGroupsEmpty => '选项组（如“规格”、“加料”）会显示在这里。';

  @override
  String get modModifier => '选项';

  @override
  String get modEditGroup => '编辑选项组';

  @override
  String get modDeleteGroup => '删除选项组';

  @override
  String get modOptionalPickOne => '可选，选择 1 个';

  @override
  String modOptionalUpTo(int n) {
    return '可选，最多 $n 个';
  }

  @override
  String modRequiredPick(int n) {
    return '必选，选择 $n 个';
  }

  @override
  String modRequiredPickRange(int min, int max) {
    return '必选，选择 $min-$max 个';
  }

  @override
  String get modNewGroup => '新建选项组';

  @override
  String get modGroupNameLabel => '名称（如 规格、加料）';

  @override
  String get modMinPicks => '最少选择';

  @override
  String get modMaxPicks => '最多选择';

  @override
  String get modNewModifier => '新建选项';

  @override
  String get modEditModifier => '编辑选项';

  @override
  String get modName => '名称';

  @override
  String get modPriceChange => '加价';

  @override
  String get modPriceChangeHelper => '可为负数，如 -0.50';

  @override
  String modDeleteGroupConfirm(String name) {
    return '删除“$name”？';
  }

  @override
  String get modDeleteGroupBody => '商品将移除此选项组。历史订单不受影响（已保留快照）。';

  @override
  String get modAddToOrder => '加入订单';

  @override
  String get modOptional => '可选';

  @override
  String modUpTo(int n) {
    return '最多 $n 个';
  }

  @override
  String modPick(int n) {
    return '选择 $n 个';
  }

  @override
  String modPickRange(int min, int max) {
    return '选择 $min-$max 个';
  }

  @override
  String get pmtAmount => '金额';

  @override
  String get pmtTipOptional => '小费（可选）';

  @override
  String get pmtTipFromTerminal => '终端小费（可选）';

  @override
  String get pmtEnterValidAmount => '请输入有效金额。';

  @override
  String get pmtEnterValidTip => '请输入有效小费。';

  @override
  String pmtAmountExceedsBalance(String balance) {
    return '金额超过应付余额（$balance）。';
  }

  @override
  String pmtCollect(String amount) {
    return '收款 $amount';
  }

  @override
  String pmtKeyAmountOnTerminal(String amount) {
    return '在终端上输入 $amount';
  }

  @override
  String get pmtKeyOnTerminalBody => '在刷卡终端上输入金额，然后记录其屏幕显示的结果。';

  @override
  String get pmtPartialPaymentHint => '部分付款 — 订单保持未结。';

  @override
  String get pmtLowerToSplitHint => '调低金额以拆分账单。';

  @override
  String get pmtDeclined => '已拒绝';

  @override
  String get pmtApproved => '已批准';

  @override
  String get inboxTitle => '在线订单';

  @override
  String get inboxPublishMenu => '发布菜单';

  @override
  String get inboxDisabledHint => '在设置中配置您的 Supabase 项目以接受在线预订单。收银系统无需它即可完整运行。';

  @override
  String get inboxNewPreorders => '新预订单';

  @override
  String get inboxNoNewPreorders => '暂无新预订单。';

  @override
  String get inboxPreparing => '准备中';

  @override
  String get inboxNothingInProgress => '暂无进行中的订单。';

  @override
  String get inboxMenuPublished => '菜单已发布到您的店铺。';

  @override
  String inboxPublishFailed(String error) {
    return '发布失败：$error';
  }

  @override
  String inboxError(String error) {
    return '错误：$error';
  }

  @override
  String inboxCustomerPickup(String name, String time) {
    return '$name · 取餐时间 $time';
  }

  @override
  String inboxTotalPayAtPickup(String total) {
    return '合计 $total · 取餐时支付';
  }

  @override
  String get inboxReject => '拒绝';

  @override
  String get inboxAccept => '接受';

  @override
  String get inboxAcceptedAdded => '已接受，已添加到订单。';

  @override
  String get inboxPreorderRejected => '预订单已拒绝。';

  @override
  String get inboxCustomerNotifiedReady => '已通知顾客：已就绪。';

  @override
  String get inboxMarkReady => '标记为就绪';

  @override
  String get repTitle => '报表';

  @override
  String get repPreviousDay => '前一天';

  @override
  String get repNextDay => '后一天';

  @override
  String get repCollected => '已收';

  @override
  String get repItemSales => '菜品销量';

  @override
  String repItemQty(int qty) {
    return '${qty}x';
  }

  @override
  String get repOrderHistory => '历史订单';

  @override
  String get repNoClosedOrders => '当天暂无已结订单。';

  @override
  String get repOrders => '订单';

  @override
  String repOrdersVoided(int count) {
    return '已作废 $count';
  }

  @override
  String get repGrossSales => '销售总额';

  @override
  String repSubtotalValue(String amount) {
    return '小计 $amount';
  }

  @override
  String get repTax => '税';

  @override
  String get repTips => '小费';

  @override
  String repPaymentsCount(int count) {
    return '$count 笔收款';
  }

  @override
  String repPaymentsCountTips(int count, String tips) {
    return '$count 笔收款 — 小费 $tips';
  }

  @override
  String get repTotalCollected => '收款合计';

  @override
  String repOrderVoidedSuffix(String ref) {
    return '$ref — 已作废';
  }

  @override
  String repOrderVoidedParen(String ref) {
    return '$ref（已作废）';
  }

  @override
  String repLineQtyName(int qty, String name) {
    return '$qty x $name';
  }

  @override
  String get repTotal => '合计';

  @override
  String repTipValue(String amount) {
    return '小费 $amount';
  }

  @override
  String get repReceiptQueued => '小票已排队打印。';

  @override
  String get repReprintReceipt => '重新打印小票';

  @override
  String get setLanguage => '语言';

  @override
  String get setLanguageSystem => '跟随系统';

  @override
  String get setTax => '税务';

  @override
  String get setSalesTaxRate => '销售税率';

  @override
  String get setSalesTaxRateSubtitle => '适用于新订单；已有订单保留其税率。';

  @override
  String get setPayments => '支付';

  @override
  String get setCardTerminalManual => '刷卡终端：手动输入';

  @override
  String get setCardTerminalManualSubtitle =>
      '员工在独立终端上输入金额并记录结果。配置 Moneris Cloud API 访问后即可支持半集成的 Moneris Go。';

  @override
  String get setPrinting => '打印';

  @override
  String get setTestPrint => '测试打印';

  @override
  String get setNetworkPrinter => '网络打印机';

  @override
  String setPrinterConfigured(String host, int port, String width) {
    return '$host:$port — ${width}mm 纸';
  }

  @override
  String get setPrinterNotConfigured => '未配置。通过局域网使用 ESC/POS（端口 9100）。';

  @override
  String get setBusinessNameOnReceipts => '小票上的商家名称';

  @override
  String get setBusinessName => '商家名称';

  @override
  String get setReceiptFooter => '小票页脚';

  @override
  String get setPrintQueue => '打印队列';

  @override
  String get setTables => '餐桌';

  @override
  String get setTableButton => '餐桌';

  @override
  String get setAddTablesHint => '添加餐桌以启用堂食订单。';

  @override
  String get setInactive => '停用';

  @override
  String get setRate => '税率';

  @override
  String get setTestPageSent => '测试页已发送到打印机。';

  @override
  String setTestPrintFailed(String message) {
    return '测试打印失败：$message';
  }

  @override
  String get setPrinterIp => '打印机 IP 地址';

  @override
  String get setPrinterIpHelper => '留空以停用打印。';

  @override
  String get setPort => '端口';

  @override
  String get setPaper58 => '58mm 纸';

  @override
  String get setPaper80 => '80mm 纸';

  @override
  String get setNewTable => '新建餐桌';

  @override
  String get setEditTable => '编辑餐桌';

  @override
  String get setTableLabelHint => '标签（如 1、2、露台 A）';

  @override
  String get setActive => '启用';

  @override
  String get setJobKitchenTicket => '厨房单';

  @override
  String get setJobCustomerReceipt => '顾客小票';

  @override
  String get setJobTestPage => '测试页';

  @override
  String get setJobQueued => '排队中';

  @override
  String get setJobPrinting => '打印中…';

  @override
  String get setJobPrinted => '已打印';

  @override
  String get setJobFailed => '失败';

  @override
  String setJobStatusError(String status, String error) {
    return '$status — $error';
  }

  @override
  String get setRetry => '重试';

  @override
  String get setDiscard => '丢弃';

  @override
  String get setCloudSync => '云同步';

  @override
  String get setCloudBackingUp => '正在备份到您的 Supabase';

  @override
  String get setCloudNotConfigured => '未配置';

  @override
  String setCloudConfiguredSubtitle(String url) {
    return '$url\n可选 — 收银系统可完全离线运行。';
  }

  @override
  String get setCloudNotConfiguredSubtitle =>
      '备份并同步到您自己的 Supabase 项目。可选；收银系统无需它即可完全离线运行。';

  @override
  String get setSetUp => '设置';

  @override
  String setSignedInAs(String email) {
    return '已登录：$email';
  }

  @override
  String get setSignInRequired => '需要餐厅登录';

  @override
  String get setSignedInSubtitle => '同步和在线订单使用此安全登录。';

  @override
  String get setSignInRequiredSubtitle =>
      '云功能需要您的餐厅 Supabase 登录，以确保数据私密。（顾客永远不会获得它。）';

  @override
  String get setSignOut => '退出登录';

  @override
  String get setSignIn => '登录';

  @override
  String setLastSynced(String time) {
    return '上次同步 $time';
  }

  @override
  String get setSyncNow => '立即同步';

  @override
  String get setRestoreFromCloud => '从云端恢复';

  @override
  String get setCustomerQr => '顾客连接码';

  @override
  String get setCustomerQrTitle => '扫码点餐';

  @override
  String get setCustomerQrHint => '顾客用点餐应用扫描此码，即可添加您的餐厅并预订自取。';

  @override
  String get setRestaurantSignIn => '餐厅登录';

  @override
  String get setSignInBody => '使用您为此餐厅创建的 Supabase 用户登录。这样可使您的数据对顾客保持私密。';

  @override
  String get setEmail => '邮箱';

  @override
  String get setPassword => '密码';

  @override
  String get setSignedInMsg => '已登录。';

  @override
  String setSignInFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String get setSignedOutMsg => '已退出登录。';

  @override
  String setSyncedMsg(int pulled, int pushed) {
    return '已同步：拉取 $pulled，推送 $pushed。';
  }

  @override
  String setSyncFailed(String error) {
    return '同步失败：$error';
  }

  @override
  String get setRestoreTitle => '从云端恢复？';

  @override
  String get setRestoreBody =>
      '从您的 Supabase 拉取完整历史并应用到本设备。适用于新设备或已清空的平板。本地已有数据将合并（后写入者优先），不会被清除。';

  @override
  String get setRestore => '恢复';

  @override
  String setRestoredMsg(int pulled) {
    return '已从云端恢复 $pulled 条更改。';
  }

  @override
  String setRestoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get setYourSupabaseProject => '您的 Supabase 项目';

  @override
  String get setSupabaseBody =>
      '输入您的项目 URL 和 anon（公开）密钥。请先创建“sync_changes”表 — 参见文档中的设置 SQL。留空 URL 可关闭同步。';

  @override
  String get setProjectUrl => '项目 URL';

  @override
  String get setAnonKey => 'Anon 密钥';

  @override
  String get navAdmin => '管理';

  @override
  String get roleOwner => '店主';

  @override
  String get roleManager => '经理';

  @override
  String get roleServer => '服务员';

  @override
  String get roleSignIn => '登录';

  @override
  String get roleSwitchUser => '切换用户';

  @override
  String get roleSignOut => '退出登录';

  @override
  String get roleNoStaffYet => '尚未设置员工';

  @override
  String get roleAccessRequired => '需要经理权限';

  @override
  String get pinEnterTitle => '输入 PIN';

  @override
  String get pinFieldLabel => '4 位 PIN';

  @override
  String get pinIncorrect => 'PIN 不正确';

  @override
  String get pinUnlock => '解锁';

  @override
  String get adminStaffSection => '员工与角色';

  @override
  String get adminAddStaff => '添加员工';

  @override
  String get adminManageStaffOwnerOnly => '仅店主可管理员工。';

  @override
  String get adminNewStaff => '新增员工';

  @override
  String get adminEditStaff => '编辑员工';

  @override
  String get adminStaffName => '姓名';

  @override
  String get adminStaffRole => '角色';

  @override
  String get adminStaffNameRequired => '请输入姓名。';

  @override
  String get adminStaffPinRequired => '请设置 4 位 PIN。';

  @override
  String get adminStaffPinKeepHint => '留空以保留当前 PIN。';

  @override
  String get adminCannotDeleteLastOwner => '无法移除最后一位店主。';

  @override
  String adminRemoveStaffConfirm(String name) {
    return '移除 $name？';
  }

  @override
  String get adminBootstrapTitle => '设置员工权限';

  @override
  String get adminBootstrapBody => '创建第一个店主账号以启用基于角色的权限。在此之前，所有人都拥有完整权限。';

  @override
  String get adminCreateFirstOwner => '创建第一位店主';

  @override
  String get adminManagementSection => '管理功能';

  @override
  String get adminComingSoon => '即将推出';

  @override
  String get adminOnlineAuth => '在线授权';

  @override
  String get adminOnlineAuthBody => '连接到您的后端后，高风险操作可要求输入发送给店主的一次性验证码。';

  @override
  String get adminDiscounts => '折扣与赠送';

  @override
  String get adminEndOfDay => '日终现金盘点';

  @override
  String get adminExport => '导出数据';

  @override
  String get itemCodeLabel => '编号（可选）';

  @override
  String get itemNameSecondaryLabel => '第二名称（可选）';

  @override
  String get itemFieldsSection => '自定义字段';

  @override
  String get itemFieldLabelHint => '字段';

  @override
  String get itemFieldValueHint => '内容';

  @override
  String get itemAddField => '添加字段';

  @override
  String get itemFieldCustom => '自定义…';

  @override
  String get fieldPresetDescription => '描述';

  @override
  String get fieldPresetIngredients => '配料';

  @override
  String get fieldPresetAllergens => '过敏原';

  @override
  String get fieldPresetSpice => '辣度';

  @override
  String get fieldPresetNotes => '备注';

  @override
  String get itemImagesSection => '图片';

  @override
  String get itemAddImage => '添加图片';

  @override
  String get itemImageLabelHint => '标签';

  @override
  String get itemSaveFirstForPhotos => '请先保存菜品再添加图片。';

  @override
  String get itemRenameImage => '重命名图片';

  @override
  String get captureImportFromPhoto => '从照片导入';

  @override
  String get captureTemplatesTitle => '采集模板';

  @override
  String get captureNewTemplate => '新建模板';

  @override
  String get captureNoTemplates => '暂无模板。创建一个，用来标记菜单照片上各字段的位置。';

  @override
  String get captureTemplateNameHint => '模板名称';

  @override
  String get captureRenameTemplate => '重命名模板';

  @override
  String get captureDeleteTemplate => '删除模板';

  @override
  String captureDeleteTemplateConfirm(String name) {
    return '删除模板“$name”？';
  }

  @override
  String get captureTemplateEditorTitle => '模板';

  @override
  String get capturePickSamplePhoto => '选择示例照片';

  @override
  String get captureBigBlockHint => '将大框拖到一个菜品上，然后在框内添加带标签的区域。';

  @override
  String get captureAddRegion => '添加区域';

  @override
  String get captureRegionField => '字段';

  @override
  String get captureRegionLabel => '标签';

  @override
  String get captureDeleteRegion => '删除区域';

  @override
  String get captureSaveTemplate => '保存模板';

  @override
  String get captureTemplateNameRequired => '请为模板命名。';

  @override
  String get captureNeedsBlockAndRegion => '请绘制大框并至少添加一个区域。';

  @override
  String get captureFieldCode => '编号';

  @override
  String get captureFieldName => '名称';

  @override
  String get captureFieldNameSecondary => '第二名称';

  @override
  String get captureFieldPrice => '价格';

  @override
  String get captureFieldAttribute => '自定义字段';

  @override
  String get captureFieldImage => '图片';

  @override
  String get captureTitle => '从照片导入';

  @override
  String get capturePickPhoto => '选择菜单照片';

  @override
  String get captureChooseTemplate => '模板';

  @override
  String get captureChooseCategory => '分类';

  @override
  String get captureRunningOcr => '正在识别文字…';

  @override
  String get captureCaptureItem => '采集菜品';

  @override
  String captureDraftCount(int count) {
    return '已采集 $count 项';
  }

  @override
  String get captureReviewAction => '查看';

  @override
  String get captureOcrLanguageMissing =>
      '未找到 OCR 语言包。请在 Windows 设置 → 时间和语言 → 语言 中添加中文或英文。';

  @override
  String get captureSelectTemplateFirst => '请先选择模板。';

  @override
  String get captureSelectPhotoFirst => '请先选择照片。';

  @override
  String get captureReviewTitle => '核对草稿';

  @override
  String get captureSaveAll => '全部保存';

  @override
  String get captureDiscardDraft => '丢弃';

  @override
  String get captureNoDrafts => '尚未采集任何内容。';

  @override
  String captureSavedCount(int count) {
    return '已保存 $count 项';
  }

  @override
  String get captureUnsupportedPlatform => '照片导入目前仅支持 Windows。';

  @override
  String get captureTemplatesShort => '模板';

  @override
  String get captureLabelsToggle => '标签';

  @override
  String get captureCreateTemplate => '创建模板';

  @override
  String get captureResetRegions => '重置布局';

  @override
  String get setSecondNameSection => '第二名称显示';

  @override
  String get setSecondNameHint => '可选的第二名称（如本地语言名称）显示在何处。';

  @override
  String get setSecondNameOrderScreen => '在点单界面';

  @override
  String get setSecondNameKitchen => '在厨房小票';

  @override
  String get setSecondNameReceipt => '在顾客收据';
}
