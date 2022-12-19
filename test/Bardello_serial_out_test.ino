void setup() {
  // put your setup code here, to run once:
  Serial.begin(57600);
  Serial1.begin(115200);
}

int iCount = 0;

void loop() {
  // put your main code here, to run repeatedly:
  Serial.println("Sent.");
  Serial1.println(iCount++);
  delay(1000);
}
