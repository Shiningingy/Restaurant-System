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
  String get connectIntro => '扫描或输入餐厅给您的店铺信息，即可浏览菜单并预订自取。';

  @override
  String get connectUrlLabel => '店铺网址';

  @override
  String get connectKeyLabel => '访问密钥';

  @override
  String get connectButton => '连接';

  @override
  String get connectErrorEmptyFields => '请输入餐厅网址和密钥。';

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
  String get statusSubmittedDetail => '餐厅将很快确认您的订单。';

  @override
  String get statusAcceptedDetail => '准备好取餐时我们会通知您。';

  @override
  String get statusReadyDetail => '请前往柜台取餐并付款。';

  @override
  String get statusRejectedDetail => '抱歉 — 餐厅无法接受此订单。';

  @override
  String statusTotalPayAtPickup(String total) {
    return '合计 $total — 取餐时支付';
  }

  @override
  String get statusBackToMenu => '返回菜单';
}
