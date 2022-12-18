const int BUTTON = 3;
const int LED    = 5;

void setup() {
  Serial.begin(57600);
  pinMode(BUTTON, INPUT);
  pinMode(LED,    OUTPUT);
}

int iState = 0;

void loop() {
  iState = digitalRead(BUTTON);
  if(iState == 0) {
    digitalWrite(LED, LOW);
    Serial.println("Off...");
  }
  else {
    digitalWrite(LED, HIGH);
    Serial.println("On....");
  }
}
