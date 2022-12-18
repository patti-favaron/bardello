void setup() {
  // put your setup code here, to run once:
  Serial.begin(57600);
  Serial1.begin(9600);
}

int iCount = 0;

void loop() {
  // put your main code here, to run repeatedly:
  while (Serial1.available() > 0) {
    char c = Serial1.read();
    Serial.print(c);
  }
}
