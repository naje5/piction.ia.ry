// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'game.screen.dart';

// class ScanQRCodePage extends StatefulWidget {
//   const ScanQRCodePage({super.key});

//   @override
//   State<ScanQRCodePage> createState() => _ScanQRCodePageState();
// }

// class _ScanQRCodePageState extends State<ScanQRCodePage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   void _onQRViewCreated(QRViewController ctrl) {
//     controller = ctrl;
//     controller!.scannedDataStream.listen((scanData) {
//       final gameId = scanData.code;
//       if (gameId != null && mounted) {
//         controller!.pauseCamera();
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (_) => GamePage(
//               gameId: gameId,
//               players: [], // on passe une liste vide par défaut
//             ),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Scanner un QR code")),
//       body: QRView(
//         key: qrKey,
//         onQRViewCreated: _onQRViewCreated,
//         overlay: QrScannerOverlayShape(
//           borderColor: Colors.pinkAccent,
//           borderRadius: 10,
//           borderLength: 30,
//           borderWidth: 10,
//           cutOutSize: 250,
//         ),
//       ),
//     );
//   }
// }
