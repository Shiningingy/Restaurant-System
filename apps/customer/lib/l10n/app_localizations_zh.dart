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
  String get orderNotifyAccepted => '您的订单已被接受，正在备餐。';

  @override
  String get orderNotifyReady => '您的订单已经可以取餐了！';

  @override
  String get orderNotifyTimeProposed => '餐厅建议了新的取餐时间——点击查看。';

  @override
  String get orderNotifyRejected => '您的订单已被拒绝。';
}
