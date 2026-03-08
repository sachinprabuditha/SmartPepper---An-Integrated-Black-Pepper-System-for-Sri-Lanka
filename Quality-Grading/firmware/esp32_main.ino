#include <WiFi.h>
#include <WebServer.h>
#include "HX711.h"
#include <ArduinoJson.h> 

/* ========= WIFI SETTINGS ========= */
const char* ssid = "Not STARLINK";
const char* password = "123456789";

/* ========= HX711 ========= */
#define LOADCELL_DOUT_PIN 4
#define LOADCELL_SCK_PIN  2
HX711 scale;
float calibration_factor = 7050; // Initial guess

/* ========= STEPPER ========= */
#define STEP_PIN 16
#define DIR_PIN  17
#define EN_PIN   5

WebServer server(80);

// Motor State
bool isRunning = false;
int motorSpeed = 800; // Microseconds delay (Lower is faster)
unsigned long lastStepTime = 0;

/* ========= SETUP ========= */
void setup() {
  Serial.begin(115200);

  // Stepper setup
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);
  digitalWrite(EN_PIN, LOW); // Enable driver
  digitalWrite(DIR_PIN, HIGH);

  // Load cell
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare();

  // WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected!");
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  /* ========= WEB ROUTES ========= */
  server.enableCORS(true); 

  server.on("/status", HTTP_GET, handleStatus);
  server.on("/control", HTTP_POST, handleControl);
  server.on("/control/tare", HTTP_POST, handleTare);
  server.on("/control/calibrate", HTTP_POST, handleCalibrate);
  
  server.begin();
}

/* ========= LOOP ========= */
void loop() {
  server.handleClient();

  if (isRunning) {
    unsigned long currentMicros = micros();
    if (currentMicros - lastStepTime >= motorSpeed) {
      lastStepTime = currentMicros;
      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(10); // Short pulse
      digitalWrite(STEP_PIN, LOW);
    }
  }
}

/* ========= HELPERS ========= */
void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

/* ========= WEB HANDLERS ========= */
void handleStatus() {
  float weight = scale.get_units(1); // Faster reading
  
  String json = "{";
  json += "\"weight\": " + String(weight, 3) + ",";
  json += "\"running\": " + String(isRunning ? "true" : "false") + ",";
  json += "\"speed\": " + String(motorSpeed) + ",";
  json += "\"factor\": " + String(calibration_factor);
  json += "}";

  sendCorsHeaders();
  server.send(200, "application/json", json);
}

void handleControl() {
  if (server.hasArg("plain") == false) {
    server.send(400, "text/plain", "Body not received");
    return;
  }

  String body = server.arg("plain");
  DynamicJsonDocument doc(1024);
  deserializeJson(doc, body);

  if (doc.containsKey("running")) {
    isRunning = doc["running"];
  }
  
  if (doc.containsKey("speed")) {
    motorSpeed = doc["speed"];
    if (motorSpeed < 200) motorSpeed = 200;
    if (motorSpeed > 5000) motorSpeed = 5000;
  }

  handleStatus();
}

void handleTare() {
  scale.tare();
  sendCorsHeaders();
  server.send(200, "application/json", "{\"message\": \"Scale Tared\"}");
}

void handleCalibrate() {
  if (server.hasArg("plain") == false) {
    server.send(400, "text/plain", "Body not received");
    return;
  }

  String body = server.arg("plain");
  DynamicJsonDocument doc(1024);
  deserializeJson(doc, body);

  if (doc.containsKey("knownWeight")) {
    float knownWeight = doc["knownWeight"]; // in kg
    if (knownWeight != 0) {
      // Logic: RAW / Factor = Weight  =>  Factor = RAW / KnownWeight
      // We assume the user has already Tared (scale reads 0 for 0 weight).
      // Now they placed a known weight.
      // We need raw reading minus tare offset.
      // scale.get_units() returns (raw - offset) / factor.
      // scale.get_value() returns (raw - offset).
      
      long rawValue = scale.get_value(10); // Average of 10 readings
      calibration_factor = (float)rawValue / knownWeight;
      scale.set_scale(calibration_factor);
    }
  }

  handleStatus();
}
