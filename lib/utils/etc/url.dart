import 'package:url_launcher/url_launcher.dart';

// 在浏览器中打开链接
Future<void> launchInBrowser(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    return;
  }
}

// 检查链接是否可以打开
Future<bool> canLaunchInBrowser(String url) async {
  return await canLaunchUrl(Uri.parse(url));
}
