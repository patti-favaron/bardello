#include "RTClib.h"

#define SONIC_STR_LEN 44

RTC_DS3231 rtc;
int iCount = 0;
char sBuffer[SONIC_STR_LEN];

// User interface parameters
const int BUTTON = 3;
const int LED    = 5;

void error(const int iNum) {

  while(true) {
    
    // Preamble: "line" followed by a long rest
    digitalWrite(LED, HIGH);
    delay(300);
    digitalWrite(LED, LOW);
    delay(200);
  
    // Actual message
    for(int i = 0; i < iNum; i++) {
  
      // "Dot" followed by short rest
      digitalWrite(LED, HIGH);
      delay(150);
      digitalWrite(LED, LOW);
      delay(75);
    }
  
    // 1s pause
    delay(1000);
  
  }
  
}

void setup() {

  // User interface pin function assignment
  pinMode(BUTTON, INPUT);
  pinMode(LED,    OUTPUT);
  
  // Serial data
  Serial.begin(57600);
  Serial1.begin(19200);

  // Activate the RTC without resetting it: in case of power failure it should hold
  // the correct date/time thanks to the CR2032 battery. Wrong or missing answer by
  // the RTC is considered a critical error, and blocks execution with error 1.
  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    Serial.flush();
    error(1);
  }
  
}


void loop() {
  // put your main code here, to run repeatedly:
  while (Serial1.available() > 0) {
    char c = Serial1.read();
    sBuffer[iCount] = c;
    iCount++;
    if(c == 0x0A || iCount >= SONIC_STR_LEN - 1) {

      // Close serial line
      sBuffer[iCount] = 0x00;

      // Generate time stamp
      DateTime now = rtc.now();
      char sTimeStamp[20];
      sprintf(sTimeStamp, "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d", now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());

      // Write data
      Serial.print(sTimeStamp);
      Serial.print(",");
      Serial.print(sBuffer);

      // Set line buffer ready for next string
      iCount = 0;
      
    }
  }
}

