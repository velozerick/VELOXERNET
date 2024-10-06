import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

void main() {
  runApp(VeloxerLightApp());
}

class VeloxerLightApp extends StatelessWidget {
  VeloxerLightApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veloxer Light Control',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenido a VELOXERNET',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ControlRoomPage()),
                );
              },
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlRoomPage extends StatefulWidget {
  ControlRoomPage({Key? key}) : super(key: key);

  @override
  ControlRoomPageState createState() => ControlRoomPageState();
}

class ControlRoomPageState extends State<ControlRoomPage> {
  bool _isDeskOn = false;
  bool _isProcessing = false;

  final String deskDeviceId = '66d3ffc954041e4ff627ab96';

  final List<String> _logs = []; // Declarado como final

  String _statusMessage = "Sistema en Espera";

  void _toggleDesk() async {
    _startProcessing();
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isDeskOn = !_isDeskOn;
      _addLog("Luz del Escritorio ${_isDeskOn ? 'Encendida' : 'Apagada'}");
      _updateStatusMessage();
    });
    _stopProcessing();

    // Enviar solicitud a SinricPro para controlar el dispositivo
    await http.get(Uri.parse('http://192.168.1.83/accion?state=${_isDeskOn ? "on" : "off"}'));

  }

  void _startProcessing() {
    setState(() {
      _isProcessing = true;
    });
  }

  void _stopProcessing() {
    setState(() {
      _isProcessing = false;
    });
  }

  void _addLog(String action) {
    String timestamp = DateTime.now().toIso8601String();
    setState(() {
      _logs.add("$action a las $timestamp");
    });
    _removeLogAfterDelay(10); // Eliminar después de 10 segundos
  }

  void _removeLogAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      setState(() {
        if (_logs.isNotEmpty) {
          _logs.removeAt(0);
        }
      });
    });
  }

  void _updateStatusMessage() {
    if (_isDeskOn) {
      _statusMessage = "Luz del Escritorio Encendida";
    } else {
      _statusMessage = "Luz del Escritorio Apagada";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VELOXERNET',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        backgroundColor: Colors.black87,
        centerTitle: true,
        shadowColor: Colors.cyanAccent,
        toolbarHeight: 70,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(),
                ),
              SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildGridButtons(),
                ),
              ),
              _buildLogs(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridButtons() {
    return GridView.count(
      crossAxisCount: 1,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      children: <Widget>[
        _buildControlButton(
          'Escritorio',
          _isDeskOn,
          _toggleDesk,
          Icons.lightbulb_outline,
          Icons.lightbulb,
        ),
      ],
    );
  }

  Widget _buildControlButton(String label, bool isActive, Function onTap, IconData iconOff, IconData iconOn) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: isActive ? [Colors.greenAccent.shade400, Colors.greenAccent.shade700] : [Colors.redAccent.shade400, Colors.redAccent.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: Colors.greenAccent.shade400.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 4,
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(2, 2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconOn : iconOff,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.blueGrey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      height: 120,
      color: Colors.black54,
      padding: EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          return Text(
            _logs[index],
            style: TextStyle(color: Colors.white, fontSize: 14),
          );
        },
      ),
    );
  }
}
