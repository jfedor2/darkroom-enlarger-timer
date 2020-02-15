#include "DigiKeyboard.h"

#define PIN 0

void setup() {
  pinMode(PIN, INPUT);
  digitalWrite(PIN, HIGH);
}

int prevstate = 1;

void loop() {
  int state = digitalRead(PIN);
  if (state != prevstate) {
    if (state) {
      // release
      DigiKeyboard.sendKeyPress(0);
    } else {
      DigiKeyboard.sendKeyPress(KEY_ENTER);
    }
    DigiKeyboard.delay(50);
  }
  prevstate = state;
  DigiKeyboard.update();
}
