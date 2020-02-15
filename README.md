# Darkroom enlarger timer

This is code for my darkroom timer solution. There are three components:

* `sonoff-socket-http-server` is MicroPython code that's running on a Sonoff S20 smart plug that the enlarger lamp is connected to. The plug needs to be flashed with MicroPython firmware first.
* `enlarger_timer` is a Flutter smartphone app that allows the user to set the exposure times and talks to the smart plug over HTTP.
* `Footswitch` is an Arduino sketch that's running on a Digispark connected to a foot pedal. It's connected to the smartphone and pretends to be a USB keyboard that only has one key (Enter).

More details here:

https://blog.jfedor.org/2020/02/darkroom-enlarger-timer.html
