// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '预订';

  @override
  String get languageMenuTooltip => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get connectTitle => '连接到餐厅';

  @override
  String get connectAddTitle => '添加餐厅';

  @override
  String get connectIntro => '扫描或输入餐厅给您的店铺信息，即可浏览菜单并预订自取。';

  @override
  String get connectUrlLabel => '店铺网址';

  @override
  String get connectKeyLabel => '访问密钥';

  @override
  String get connectNameLabel => '餐厅名称（可选）';

  @override
  String get connectScanButton => '扫描二维码';

  @override
  String get connectUploadQr => '上传二维码图片';

  @override
  String get connectQrImageInvalid => '未在该图片中找到餐厅二维码。';

  @override
  String get connectEnterManually => '手动输入信息';

  @override
  String get connectOrDivider => '或手动输入';

  @override
  String get connectButton => '连接';

  @override
  String get connectErrorEmptyFields => '请输入餐厅网址和密钥。';

  @override
  String get walletTitle => '我的餐厅';

  @override
  String get walletEmptyTitle => '还没有餐厅';

  @override
  String get walletEmptyBody => '扫描餐厅的二维码即可添加，或手动输入其链接。';

  @override
  String get walletAdd => '添加餐厅';

  @override
  String get walletProfile => '我的信息';

  @override
  String get walletShare => '分享';

  @override
  String get walletRename => '重命名';

  @override
  String get walletRenameLabel => '您给这家餐厅起的昵称';

  @override
  String get walletRemove => '移除';

  @override
  String walletRemoveConfirm(String name) {
    return '要将 $name 从您的餐厅中移除吗？';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get kioskEnter => '自助点餐模式';

  @override
  String get kioskEnterTitle => '切换到自助点餐模式？';

  @override
  String kioskEnterBody(String name) {
    return '此平板将成为 $name 的自助点餐机。顾客可以点餐，但不能切换餐厅。如需退出，请长按左上角。';
  }

  @override
  String get kioskTapToOrder => '点击开始点餐';

  @override
  String get kioskStart => '开始点餐';

  @override
  String get kioskExit => '退出自助模式';

  @override
  String get kioskExitTitle => '退出自助点餐模式？';

  @override
  String get kioskExitBody => '此设备将恢复为普通模式。';

  @override
  String get kioskNotConnected => '自助点餐尚未设置。';

  @override
  String get kioskThankYou => '谢谢！';

  @override
  String get kioskThankYouBody => '您的订单已提交，请到柜台付款。';

  @override
  String get kioskStartNewOrder => '开始新订单';

  @override
  String get kioskDefaultName => '自助点餐';

  @override
  String get kioskSetup => '设置自助点餐机';

  @override
  String get kioskLoadingMenu => '正在加载菜单…';

  @override
  String get kioskRetry => '重试';

  @override
  String get kioskBack => '返回';

  @override
  String get kioskHeaderFallback => '在此点餐';

  @override
  String get kioskCartEmpty => '购物车是空的';

  @override
  String get kioskReviewOrder => '确认订单';

  @override
  String get kioskReviewTitle => '您的订单';

  @override
  String get kioskAddMore => '继续添加';

  @override
  String get kioskPayAtCounter => '柜台付款';

  @override
  String get kioskPlacing => '正在提交…';

  @override
  String get kioskPayHereSoon => '在此付款（即将推出）';

  @override
  String get kioskSubtotal => '小计';

  @override
  String get kioskTotal => '合计';

  @override
  String get kioskTipTitle => '添加小费？';

  @override
  String get kioskNoTip => '不给小费';

  @override
  String get kioskTipCustom => '自定义';

  @override
  String get kioskTipCustomHint => '小费金额';

  @override
  String get kioskTip => '小费';

  @override
  String get kioskOrderPlaced => '下单成功！';

  @override
  String get kioskYourNumber => '您的取餐号';

  @override
  String get kioskPayAtCounterNote => '请到柜台付款。';

  @override
  String get kioskDone => '完成';

  @override
  String get kioskAddToOrder => '加入订单';

  @override
  String get kioskSubmitFailed => '无法下单，请联系工作人员。';

  @override
  String kioskCartSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件商品',
    );
    return '$_temp0  ·  $total';
  }

  @override
  String kioskService(String pct) {
    return '服务费 ($pct%)';
  }

  @override
  String kioskTax(String pct) {
    return '税 ($pct%)';
  }

  @override
  String kioskAddToOrderExtra(String extra) {
    return '加入订单  ·  +$extra';
  }

  @override
  String kioskAddToOrderTotal(String total) {
    return '加入订单  ·  $total';
  }

  @override
  String kioskOrderName(int number) {
    return '自助机 $number';
  }

  @override
  String get kioskSetupTitle => '设置自助点餐机';

  @override
  String get kioskSetupBody => '使用餐厅的商家登录信息将本设备设为自助点餐机。该登录仅用于授权设置，不会保存在本设备上。';

  @override
  String get kioskSetupEmail => '商家邮箱';

  @override
  String get kioskSetupPassword => '商家密码';

  @override
  String get kioskSetupNumber => '自助机编号';

  @override
  String get kioskSetupNumberHint => '显示在该自助机的订单上，例如：自助机 3';

  @override
  String get kioskSetupStart => '设置自助点餐机';

  @override
  String get kioskSetupNoStore => '请先打开一家餐厅，再设置自助点餐机。';

  @override
  String kioskSetupSignInFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String get profileTitle => '我的信息';

  @override
  String get profileIntro => '保存在本设备上，用于自动填写取餐订单。无需账号，无需登录。';

  @override
  String get profileNameLabel => '姓名或昵称';

  @override
  String get profilePhoneLabel => '电话（可选）';

  @override
  String get profileEmailLabel => '电子邮箱（可选）';

  @override
  String get profileNotifySection => '订单准备好时通知我';

  @override
  String get profileNotifyHint => '仅在餐厅已开启邮件/短信通知时有效。';

  @override
  String get profileNotifyEmail => '通过电子邮件';

  @override
  String get profileNotifySms => '通过短信';

  @override
  String get profileSave => '保存';

  @override
  String get profileSaved => '已保存';

  @override
  String get scanTitle => '扫描店铺二维码';

  @override
  String get scanHint => '将相机对准餐厅的二维码。';

  @override
  String get scanInvalid => '该二维码不是餐厅链接。';

  @override
  String get scanCameraNeeded => '扫描餐厅二维码需要使用相机。';

  @override
  String get scanAllowCamera => '允许使用相机';

  @override
  String get scanCameraBlocked => '相机权限已关闭。请在系统设置中为本应用开启，然后返回。';

  @override
  String get scanOpenSettings => '打开设置';

  @override
  String get scanCameraError => '无法启动相机。请检查系统设置中是否已允许使用相机。';

  @override
  String shareTitle(String name) {
    return '分享 $name';
  }

  @override
  String get shareHint => '让朋友扫描此码即可添加同一家餐厅。';

  @override
  String get shareClose => '关闭';

  @override
  String get menuTitle => '菜单';

  @override
  String get menuDisconnect => '断开连接';

  @override
  String get menuOptionsAvailable => '有可选项';

  @override
  String get menuEmpty => '该餐厅尚未发布菜单。';

  @override
  String menuLoadError(String error) {
    return '无法加载菜单。\n$error';
  }

  @override
  String menuViewCart(int count, String total) {
    return '查看购物车（$count）— $total';
  }

  @override
  String menuItemAdded(String name) {
    return '已添加 $name';
  }

  @override
  String itemPriceDelta(String delta) {
    return '+$delta';
  }

  @override
  String itemAdd(String price) {
    return '添加 — $price';
  }

  @override
  String get cartTitle => '您的订单';

  @override
  String get cartEmpty => '您的购物车是空的。';

  @override
  String get cartTotal => '合计';

  @override
  String get cartCheckout => '结算';

  @override
  String get checkoutTitle => '结算';

  @override
  String get checkoutNameLabel => '您的姓名';

  @override
  String get checkoutPhoneLabel => '电话（可选）';

  @override
  String get checkoutPickupTime => '取餐时间';

  @override
  String checkoutPickupLead(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '下单后最快约 $minutes 分钟可取餐',
    );
    return '$_temp0';
  }

  @override
  String checkoutPickupTooSoon(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '时间太早——取餐至少需 $minutes 分钟。已设为最早可取时间。',
    );
    return '$_temp0';
  }

  @override
  String get checkoutSubtotal => '小计';

  @override
  String get checkoutTip => '小费';

  @override
  String get checkoutTipTitle => '添加小费？';

  @override
  String get checkoutNoTip => '不给小费';

  @override
  String get checkoutTipCustom => '自定义';

  @override
  String get checkoutTipCustomHint => '小费金额';

  @override
  String get checkoutEstimatedTax => '预估税费';

  @override
  String get checkoutEstimateNote => '税费为预估值，最终金额以餐厅为准。取餐时在柜台支付。';

  @override
  String get checkoutTotal => '合计';

  @override
  String get checkoutPayAtCounter => '取餐时在柜台支付。';

  @override
  String get checkoutNameRequired => '请输入您的姓名。';

  @override
  String checkoutOrderFailed(String error) {
    return '无法提交订单：$error';
  }

  @override
  String get checkoutPlacePreorder => '提交预订单';

  @override
  String get checkoutPayOnline => '在线支付';

  @override
  String get checkoutPayAtCounterButton => '柜台支付';

  @override
  String get checkoutAwaitingPayment => '正在完成支付…';

  @override
  String get checkoutAwaitingPaymentBody => '请在浏览器中完成支付。支付完成后此页面会自动更新。';

  @override
  String get checkoutReopenPayment => '重新打开支付页面';

  @override
  String get checkoutCancelPayment => '取消支付';

  @override
  String get checkoutPaymentNotCompleted => '支付未完成。您的购物车已保留——可以重试。';

  @override
  String get statusTitle => '您的预订单';

  @override
  String get statusSendingHeadline => '正在提交您的订单…';

  @override
  String get statusSubmittedHeadline => '等待餐厅确认';

  @override
  String get statusAcceptedHeadline => '已接受 — 正在准备';

  @override
  String get statusReadyHeadline => '可以取餐了！';

  @override
  String get statusPickedUpHeadline => '已取餐 — 请慢用！';

  @override
  String get statusRejectedHeadline => '订单已被拒绝';

  @override
  String get statusTimeProposedHeadline => '建议了新的取餐时间';

  @override
  String get statusSubmittedDetail => '餐厅将很快确认您的订单。';

  @override
  String get statusAcceptedDetail => '准备好取餐时我们会通知您。';

  @override
  String get statusReadyDetail => '请前往柜台取餐并付款。';

  @override
  String get statusRejectedDetail => '抱歉 — 餐厅无法接受此订单。';

  @override
  String statusTimeProposedDetail(String time) {
    return '餐厅建议改为 $time。确认以继续，或拒绝以取消。';
  }

  @override
  String get statusApproveTime => '确认';

  @override
  String get statusDeclineTime => '拒绝';

  @override
  String statusTotalPayAtPickup(String total) {
    return '合计 $total — 取餐时支付';
  }

  @override
  String statusPaidOnline(String total) {
    return '已在线支付 — $total';
  }

  @override
  String get statusPayNow => '立即支付';

  @override
  String get statusBackToMenu => '返回菜单';

  @override
  String get ordersTitle => '我的订单';

  @override
  String get ordersEmpty => '您在这里下的订单及其状态会显示在此处。';

  @override
  String get orderStatusSubmitted => '等待中';

  @override
  String get orderStatusTimeProposed => '新时间';

  @override
  String get orderStatusAccepted => '备餐中';

  @override
  String get orderStatusReady => '可取餐';

  @override
  String get orderStatusPickedUp => '已取餐';

  @override
  String get orderStatusRejected => '已拒绝';

  @override
  String get orderMarkPickedUp => '已取餐';

  @override
  String get orderMarkPickedUpFailed => '无法确认取餐，请重试。';

  @override
  String get orderNotifyAccepted => '您的订单已被接受，正在备餐。';

  @override
  String get orderNotifyReady => '您的订单已经可以取餐了！';

  @override
  String get orderNotifyTimeProposed => '餐厅建议了新的取餐时间——点击查看。';

  @override
  String get orderNotifyRejected => '您的订单已被拒绝。';

  @override
  String get helpTitle => '帮助';

  @override
  String get helpWelcomeTitle => '欢迎使用';

  @override
  String get helpWelcomeBody => '向餐厅预订并自取——无需账号。一份简短指南会告诉您如何使用；您可随时通过帮助按钮打开它。';

  @override
  String get helpOpenGuide => '看看怎么用';

  @override
  String get helpNotNow => '暂不';
}
