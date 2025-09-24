import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Activity App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: PatientActivityScreen(),
    );
  }
}

class PatientActivityScreen extends StatefulWidget {
  @override
  _PatientActivityScreenState createState() => _PatientActivityScreenState();
}

class _PatientActivityScreenState extends State<PatientActivityScreen> {
  static const String BASE_URL = "https://weep.uz/api/";

  final TextEditingController _phoneController = TextEditingController();
  String _savedPhoneNumber = "";
  bool _isActivityActive = false;
  bool _isStartLoading = false;
  bool _isStopLoading = false;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneNumber();
  }

  // Saqlangan telefon raqamini yuklash
  Future<void> _loadSavedPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPhoneNumber = prefs.getString('phone_number') ?? "";
      _phoneController.text = _savedPhoneNumber;
    });
  }

  // Telefon raqamini saqlash
  Future<void> _savePhoneNumber() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar("Telefon raqamini kiriting!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', _phoneController.text.trim());

    setState(() {
      _savedPhoneNumber = _phoneController.text.trim();
    });

    _showSnackBar("Telefon raqam saqlandi!");
  }

  // Start activity API chaqiruv
  Future<void> _startActivity() async {
    if (_savedPhoneNumber.isEmpty) {
      _showSnackBar("Avval telefon raqamini saqlang!");
      return;
    }

    setState(() {
      _isStartLoading = true;
      _statusMessage = "";
    });

    try {
      final url = BASE_URL + "patients/start/$_savedPhoneNumber/";
      print("Sending START request to: $url");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print("START Response status: ${response.statusCode}");
      print("START Response body: ${response.body}");

      dynamic responseData;

      if (response.body.trim().startsWith('<')) {
        responseData = "HTML sahifa qaytdi - URL noto'g'ri yoki server xatolik";
        setState(() {
          _isStartLoading = false;
          _statusMessage = "START ACTIVITY: ${response.statusCode} - $responseData";
        });
      } else {
        try {
          responseData = json.decode(response.body);
          setState(() {
            _isStartLoading = false;
            // Muvaffaqiyatli bo'lsa faoliyatni boshlangan deb belgilaymiz
            if (response.statusCode == 200 || response.statusCode == 201) {
              _isActivityActive = true;
            }
            _statusMessage = "START ACTIVITY: ${response.statusCode}";
          });
        } catch (jsonError) {
          setState(() {
            _isStartLoading = false;
            // JSON xatolik bo'lsa ham status code ga qarab belgilaymiz
            if (response.statusCode == 200 || response.statusCode == 201) {
              _isActivityActive = true;
            }
            _statusMessage = "START ACTIVITY: ${response.statusCode}";
          });
        }
      }

      print("START ACTIVITY: ${response.statusCode} $responseData");

    } catch (e) {
      setState(() {
        _isStartLoading = false;
        _statusMessage = "START Tarmoq xatoligi: $e";
      });
      print("Error starting activity: $e");
    }
  }

  // End activity API chaqiruv
  Future<void> _endActivity() async {
    if (_savedPhoneNumber.isEmpty) {
      _showSnackBar("Avval telefon raqamini saqlang!");
      return;
    }

    print("STOP tugmasi bosildi!");

    setState(() {
      _isStopLoading = true;
      _statusMessage = "STOP so'rovi yuborilmoqda...";
    });

    try {
      final url = BASE_URL + "patients/end/$_savedPhoneNumber/";
      print("Sending END request to: $url");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print("END Response status: ${response.statusCode}");
      print("END Response body: ${response.body}");

      dynamic responseData;

      if (response.body.trim().startsWith('<')) {
        responseData = "HTML sahifa qaytdi - URL noto'g'ri yoki server xatolik";
        setState(() {
          _isStopLoading = false;
          _isActivityActive = false; // Har doim to'xtatamiz
          _statusMessage = "END ACTIVITY: ${response.statusCode} - $responseData";
        });
      } else {
        try {
          responseData = json.decode(response.body);
          setState(() {
            _isStopLoading = false;
            _isActivityActive = false; // Har doim to'xtatamiz
            _statusMessage = "END ACTIVITY: ${response.statusCode}";
          });
        } catch (jsonError) {
          setState(() {
            _isStopLoading = false;
            _isActivityActive = false; // Har doim to'xtatamiz
            _statusMessage = "END ACTIVITY: ${response.statusCode}";
          });
        }
      }

      print("END ACTIVITY: ${response.statusCode} $responseData");
      _showSnackBar("STOP so'rovi yuborildi!");

    } catch (e) {
      setState(() {
        _isStopLoading = false;
        _isActivityActive = false; // Xatolik bo'lsa ham to'xtatamiz
        _statusMessage = "END Tarmoq xatoligi: $e";
      });
      _showSnackBar("STOP so'rovi yuborildi (xatolik bilan)!");
      print("Error ending activity: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Activity'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Telefon raqam kiritish
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telefon raqam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '932608005',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePhoneNumber,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Saqlash',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Saqlangan telefon raqam ko'rsatish
            if (_savedPhoneNumber.isNotEmpty)
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        'Saqlangan raqam: $_savedPhoneNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 30),

            // Start va Stop tugmalari
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isStartLoading ? null : _startActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isStartLoading
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                      'START',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isStopLoading ? null : _endActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isStopLoading
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                      'STOP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Holat ko'rsatgichi
            Card(
              elevation: 2,
              color: _isActivityActive ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isActivityActive ? Icons.play_circle : Icons.stop_circle,
                      color: _isActivityActive ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      _isActivityActive ? 'Faoliyat boshlangan' : 'Faoliyat to\'xtatilgan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isActivityActive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                elevation: 2,
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'So\'nggi javob:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}