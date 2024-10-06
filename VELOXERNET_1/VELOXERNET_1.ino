#include <WiFi.h>
#include <WebServer.h>
#include <SinricPro.h>
#include <SinricProSwitch.h>

const char* ssid = "Figuis";       
const char* password = "veloz490128";   

const char* appKey = "ea9cff8e-4e7c-464c-aa3e-a3b289740809";     
const char* appSecret = "5ead32ed-ea2c-4391-898e-c72cca74438b-78823172-e45f-48d9-9b7b-77707613de86"; 
const char* deviceId = "66d3ffc954041e4ff627ab96";  

#define RELAY_PIN 2  

WebServer server(80);  // Crea un servidor web en el puerto 80

bool onPowerState(const String &deviceId, bool &state) {
  Serial.printf("Device %s turned %s\r\n", deviceId.c_str(), state ? "ON" : "OFF");
  digitalWrite(RELAY_PIN, state ? LOW : HIGH);
  return true;
}

void handleRoot() {
  server.send(200, "text/plain", "hello from esp32!");
}

void handleOn() {
  digitalWrite(RELAY_PIN, LOW);  // Enciende el relé
  server.send(200, "text/plain", "Encendido");
}

void handleOff() {
  digitalWrite(RELAY_PIN, HIGH);  // Apaga el relé
  server.send(200, "text/plain", "Apagado");
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConectado a WiFi");

  // Imprimir la dirección IP asignada al ESP32
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());

  SinricProSwitch &mySwitch = SinricPro[deviceId];
  mySwitch.onPowerState(onPowerState);

  SinricPro.begin(appKey, appSecret);

  server.on("/", handleRoot);
  server.on("/accion", [](){
    if (server.hasArg("state")) {
      String state = server.arg("state");
      if (state == "on") {
        handleOn();
      } else if (state == "off") {
        handleOff();
      }
    }
  });
  server.begin();
}

void loop() {
  SinricPro.handle();
  server.handleClient();
}
