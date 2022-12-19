#include <SPI.h>
#include <SD.h>
#include "RTClib.h"

#define SONIC_STR_LEN 44

RTC_DS3231 rtc;
int iCount = 0;
char sBuffer[SONIC_STR_LEN];

// User interface parameters
const int BUTTON = 3;
const int LED    = 5;
int iRunning     = LOW;

// MicroSD specific
char      sFileName[15];
int       iOldHour;
const int chipSelect = SDCARD_SS_PIN;
File      fDataFile;

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

// ***********************
// * Initialization code *
// ***********************

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
  // RTC programmed and running: we're "go" for MicroSD connection

  // Generate current file name, and set variable to understand it's possibly changed
  DateTime now = rtc.now();
  sprintf(sFileName, "%2.2d%2.2d%2.2d%2.2d.dat", now.year() % 100, now.month(), now.day(), now.hour());
  iOldHour = now.hour();

  // Connect MicroSD under "this" name
  if (!SD.begin(SDCARD_SS_PIN)) {
    Serial.println("MicroSD initialization failed!");
    error(2);
  }
  // MicroSD connected successfully: we're "go" for file initialization

  // Open first data file
  Serial.print("File name: ");
  Serial.println(sFileName);
  fDataFile = SD.open(sFileName, FILE_WRITE);
  if(!fDataFile) {
    Serial.println("First file open failed");
    error(3);
  }
  fDataFile.println("date,quadruple");
  
}

// *******************
// * Functional loop *
// *******************

void loop() {
  
  // Main loop: react to any character presenting over serial
  while (Serial1.available() > 0) {

    // Get a character and append it to in string
    char c = Serial1.read();
    sBuffer[iCount] = c;
    iCount++;

    // If this is the last char (a 0x0A) or no space any more exists in line, save it
    // and process file write
    if(c == 0x0A || iCount >= SONIC_STR_LEN - 1) {

      // Close serial line
      sBuffer[iCount] = 0x00;

      // Generate time stamp
      DateTime now = rtc.now();
      char sTimeStamp[20];
      sprintf(sTimeStamp, "%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d", now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());

      // Check file name should change, and in case close old and open new file
      if(now.hour() != iOldHour) {

        // Close current file, and open new
        sprintf(sFileName, "%2.2d%2.2d%2.2d%2.2d.dat", now.year() % 100, now.month(), now.day(), now.hour());
        fDataFile.close();
        Serial.print("File name: ");
        Serial.println(sFileName);
        fDataFile = SD.open(sFileName, FILE_WRITE);
        if(!fDataFile) {
          Serial.println("First file open failed");
          error(4);
        }
        fDataFile.println("date,quadruple");
  
        // Prepare for next file
        iOldHour = now.hour();

      }

      // Write data
      fDataFile.print(sTimeStamp);
      fDataFile.print(",");
      fDataFile.print(sBuffer);
      Serial.print(sTimeStamp);
      Serial.print(",");
      Serial.print(sBuffer);

      // Invert service LED state and update LED
      iRunning = iRunning == LOW ? HIGH : LOW;
      digitalWrite(LED, iRunning);
      
      // Check button state, and if pressed stop acquisition altogether
      if(digitalRead(BUTTON) == HIGH) {
        fDataFile.close();
        digitalWrite(LED, HIGH);
        while(true);
      }

      // Set line buffer ready for next string
      iCount = 0;
      
    }

  }
}

