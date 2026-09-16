
// import 'dart:developer';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:professional_lawyer/core/common_widget/loading_button.dart';
// import 'package:professional_lawyer/core/router/app_router.dart';
// import 'package:professional_lawyer/core/theme/text_styles.dart';

// import 'package:webview_flutter/webview_flutter.dart';


// class WebViewContainer extends StatefulWidget {
//   const WebViewContainer({super.key, required this.url});
//   final String url;

//   @override
//   State<WebViewContainer> createState() => _WebViewContainerState();
// }

// class _WebViewContainerState extends State<WebViewContainer> {
//   late final WebViewController controller;
//   bool isLoading = true;
//   bool isConnected = true;
//   bool isErorr = false;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize WebView controller
//     controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(NavigationDelegate(
//         onNavigationRequest: (NavigationRequest request) async {
//           // Check for callback URL
//           log(request.url.toString());
//           log("==========================");
//           if (request.url
//               .contains('https://khadmatmantakty.com/api/opay/callback')) {
//             log("=========== ${request.url}");

//             _handleCallback(Uri.parse(request.url));
//             return NavigationDecision.prevent; // Prevent further navigation
//           }
//           return NavigationDecision.navigate;
//         },
//         onPageStarted: (url) {
//           setState(() {
//             isLoading = true;
//             isErorr = false;
//           });
//         },
//         onPageFinished: (url) {
//           setState(() {
//             isLoading = false;
//             isErorr = false;
//           });
//         },
//         onWebResourceError: (error) {
//           setState(() {
//             isLoading = false;
//             isErorr = true;
//           });
//           debugPrint("Failed to load the page: ${error.description}");
//         },
//       ))
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   void _handleCallback(Uri uri) {
//     final status = uri.queryParameters['success'];
//     // final transactionId = uri.queryParameters['id'];
//     log("=========== $status");
//     if (status == 'true') {
//       context.go(AppRouter.initialRoot);
//       log("========2=== $status");
//       // _showDialog('status', "$status");

//       // context.go(AppRouters.kOrderAcceptedScreen);

//       // getIt<GetCartCubit>().fetchCart();
//     } else if (status == 'false') {
//       context.pop();
//       _showDialog('Payment Failed', 'Please try again later');
//     }
//   }

//   void _showDialog(String title, String content) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title.tr()),
//         content: Text(content.tr()),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Close the dialog
//             },
//             child: Text('OK'.tr()),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             if (isConnected && !isErorr) WebViewWidget(controller: controller),
//             if (!isConnected || isErorr)
//               Center(
//                 child: Container(
//                   height: MediaQuery.of(context).size.height * 0.1,
//                   width: MediaQuery.of(context).size.width * 0.9,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     border: Border.all(width: 1, style: BorderStyle.solid),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           'No Internet Connection'.tr(),
//                           style: TextStyles.darkRegular16.copyWith(
//                               color: Colors.black, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             if (isLoading)
//               const Center(
//                 child: LoadingButton(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }