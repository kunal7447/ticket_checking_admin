import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerPage extends StatefulWidget {
  final String museumId;

  const QRScannerPage({Key? key, required this.museumId}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey();
  Barcode? result;
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('QR Scanner Example'),
        ),
        body: Column(
          children: [
            Expanded(
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            Expanded(
              child: Center(
                child: result != null 
                    ? FutureBuilder<String>(
                        future: _checkTicket("${result!.code}"),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text("Checking...");
                          } else if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          } else if (snapshot.hasData) {
                            // Navigate to the ResultScreen with the message
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResultScreen(
                                    message: snapshot.data!,
                                  ),
                                ),
                              );
                            });
                            return Container(); // Return an empty container while navigating
                          } else {
                            return Text("No data found");
                          }
                        },
                      )
                    : Text("Scan a QR code"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  Future<String> _checkTicket(String code) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference tickets = firestore.collection('ticket');

    try {
      // Check if the code exists in the collection and belongs to the current museum
      final querySnapshot = await tickets
          .where('ticketId', isEqualTo: code)
          .where('museumId', isEqualTo: widget.museumId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // If found, delete the document
        await tickets.doc(querySnapshot.docs.first.id).delete();
        return "User is authenticated";
      } else {
        return "User is fraud";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Result Screen
class ResultScreen extends StatelessWidget {
  final String message;

  const ResultScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}