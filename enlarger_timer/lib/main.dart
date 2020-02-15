import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/*

TODO:

- prevent invalid times from being entered on the calculator screen
- scroll to current strip
- 1/3 / + / - / STRIPS buttons should fill space
- enter pressed in settings dialog triggers lamp

 */

void main() {
  runApp(EnlargerTimer());
}

getDimensionScaler(MediaQueryData mediaQueryData) {
  final smallerDimension =
  min(mediaQueryData.size.width, mediaQueryData.size.height * 9 / 16);
  return (logicalPixels) =>
      (logicalPixels * smallerDimension / 411.4).roundToDouble();
}

class EnlargerTimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(Color(0xFFFF0000), BlendMode.multiply),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: MaterialApp(
          title: 'Enlarger timer',
          theme:
          ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
          initialRoute: '/',
          routes: {
            '/': (context) => MainScreen(),
            '/step': (context) => StepScreen(),
            '/time': (context) => TimeScreen(),
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final _urlScheme = 'http://';
  final _enlargerAddressPrefsKey = 'enlargerAddress';
  final _numberOfStrips = 32;

  var _enlargerAddress;

  int _step = 3;
  double _time = 2.0;
  bool _stripsMode = false;
  List<double> _strips = [];
  int _currentStrip = 0;

  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _textEditingController = TextEditingController();

  _setTime(t) {
    _time = t;
    if (_time > 999.9) {
      _time = 999.9;
    }
  }

  _formatTime(double t) {
    return t.toStringAsFixed(1);
  }

  _lampOn() {
    http.post(_urlScheme + _enlargerAddress + '/on');
  }

  _lampOff() {
    http.post(_urlScheme + _enlargerAddress + '/off');
  }

  _expose(double t) {
    http.post(_urlScheme +
        _enlargerAddress +
        '/expose?time=' +
        (double.parse(_formatTime(t)) * 1000).toStringAsFixed(0));
  }

  _startPressed() {
    if (_stripsMode) {
      _expose(_strips[_currentStrip] -
          (_currentStrip == 0 ? 0.0 : _strips[_currentStrip - 1]));
      setState(() {
        _currentStrip++;
        if (_currentStrip >= _strips.length) {
          _stripsMode = false;
        } else {
          // _scrollController.animateTo(offset, duration: Duration(milliseconds: 250), curve: Curves.ease);
        }
      });
    } else {
      _expose(_time);
    }
  }

  _handleKeyEvent(rawKeyEvent) {
    if (rawKeyEvent is RawKeyDownEvent &&
        rawKeyEvent.logicalKey == LogicalKeyboardKey.enter &&
        rawKeyEvent.data is RawKeyEventDataAndroid &&
        ((rawKeyEvent.data as RawKeyEventDataAndroid).repeatCount == 0)) {
      _startPressed();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    RawKeyboard.instance.addListener(_handleKeyEvent);
    SharedPreferences.getInstance().then((prefs) {
      _enlargerAddress =
          prefs.getString(_enlargerAddressPrefsKey) ?? '192.168.0.38';
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final ds = getDimensionScaler(mediaQueryData);

    _showSettingsDialog() {
      _textEditingController.text = _enlargerAddress;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enlarger address'),
          content: TextField(
            controller: _textEditingController,
          ),
          actions: [
            FlatButton(
              child: Text('OK',
                  style: TextStyle(fontSize: ds(32))
              ),
              onPressed: () {
                Navigator.of(context).pop(_textEditingController.text);
              },
            ),
          ],
        ),
      ).then((value) {
        if (value != null) {
          _enlargerAddress = value;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString(_enlargerAddressPrefsKey, value);
          });
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mediaQueryData.size.height),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FlatButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/time').then((time) {
                          if (time != null) {
                            setState(() {
                              _setTime(time);
                              _stripsMode = false;
                            });
                          }
                          _focusNode.requestFocus();
                        });
                      },
                      child: Text(
                        _formatTime(_time),
                        style: TextStyle(fontSize: ds(120)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ButtonTheme(
                      minWidth: ds(64.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FlatButton(
                              child: Text("1/$_step",
                                  style: TextStyle(fontSize: ds(32))),
                              onPressed: () {
                                Navigator.pushNamed(context, '/step')
                                    .then((step) {
                                  if (step != null) {
                                    setState(() {
                                      _step = step;
                                    });
                                  }
                                  _focusNode.requestFocus();
                                });
                              }),
                          FlatButton(
                              child:
                              Text('+', style: TextStyle(fontSize: ds(32))),
                              onPressed: () {
                                setState(() {
                                  _stripsMode = false;
                                  _setTime(_time * pow(2, 1 / _step));
                                });
                              }),
                          FlatButton(
                              child:
                              Text('-', style: TextStyle(fontSize: ds(32))),
                              onPressed: () {
                                setState(() {
                                  _stripsMode = false;
                                  _setTime(_time / pow(2, 1 / _step));
                                });
                              }),
                          FlatButton(
                              child: Text(
                                'STRIPS',
                                style: TextStyle(
                                  decoration: _stripsMode
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  fontSize: ds(32),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _strips = Iterable.generate(_numberOfStrips)
                                      .map((x) => _time * pow(2, x * 1 / _step))
                                      .toList();
                                  _stripsMode = true;
                                  _currentStrip = 0;
                                });
                                _scrollController.animateTo(0.0,
                                    duration: Duration(milliseconds: 1000),
                                    curve: Curves.ease);
                              }),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: ds(16)),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Table(
                            columnWidths: {
                              0: FlexColumnWidth(),
                              1: FixedColumnWidth(ds(32)),
                              2: FlexColumnWidth(),
                            },
                            children: _strips
                                .asMap()
                                .map(
                                  (i, t) => MapEntry(
                                i,
                                TableRow(
                                  children: [
                                    Text("${i + 1}:",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontSize: ds(32))),
                                    Text("",
                                        style: TextStyle(fontSize: ds(32))),
                                    Text(
                                      _formatTime(t),
                                      style: TextStyle(
                                        fontSize: ds(32),
                                        decoration: _stripsMode &&
                                            i == _currentStrip
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ]
                                      .map(
                                        (x) => TableRowInkWell(
                                      child: x,
                                      onTap: () {
                                        setState(() {
                                          _stripsMode = false;
                                          _setTime(t);
                                        });
                                      },
                                    ),
                                  )
                                      .toList(),
                                ),
                              ),
                            )
                                .values
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    ButtonTheme(
                      minWidth: ds(64.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: FlatButton(
                              child: Text('LAMP ON',
                                  style: TextStyle(fontSize: ds(32))),
                              onPressed: () {
                                _lampOn();
                              },
                            ),
                          ),
                          Expanded(
                            child: FlatButton(
                              child: Text('LAMP OFF',
                                  style: TextStyle(fontSize: ds(32))),
                              onPressed: () {
                                _lampOff();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    FlatButton(
                      child: Text('START', style: TextStyle(fontSize: ds(72))),
                      onPressed: _startPressed,
                    )
                  ],
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: FlatButton(
                    onPressed: () => _showSettingsDialog(),
                    child: Icon(Icons.settings, size: ds(36)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StepScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final ds = getDimensionScaler(mediaQueryData);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            physics: ScrollPhysics(),
            shrinkWrap: true,
            children: [2, 3, 4, 6, 12, 24]
                .map((x) => Padding(
                padding: EdgeInsets.all(16),
                child: FlatButton(
                    onPressed: () {
                      Navigator.pop(context, x);
                    },
                    child:
                    Text("1/$x", style: TextStyle(fontSize: ds(48))))))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class TimeScreen extends StatefulWidget {
  @override
  createState() => TimeScreenState();
}

class TimeScreenState extends State<TimeScreen> {
  String _timeText = '';

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final ds = getDimensionScaler(mediaQueryData);

    Widget _digitButton(s) {
      return FlatButton(
        onPressed: () {
          setState(() {
            _timeText += s;
          });
        },
        child: Text(
          s,
          style: TextStyle(fontSize: ds(56)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_timeText,
                style: TextStyle(fontSize: ds(120)),
                textAlign: TextAlign.center),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _digitButton("1"),
                _digitButton("2"),
                _digitButton("3"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _digitButton("4"),
                _digitButton("5"),
                _digitButton("6"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _digitButton("7"),
                _digitButton("8"),
                _digitButton("9"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _digitButton("."),
                _digitButton("0"),
                FlatButton(
                  onPressed: () {
                    if (_timeText.length > 0) {
                      setState(() {
                        _timeText =
                            _timeText.substring(0, _timeText.length - 1);
                      });
                    }
                  },
                  child: Icon(Icons.backspace, size: ds(36)),
                ),
              ],
            ),
            Spacer(),
            FlatButton(
                onPressed: () {
                  Navigator.pop(context, double.tryParse(_timeText));
                },
                child: Text('OK', style: TextStyle(fontSize: ds(72)))),
          ],
        ),
      ),
    );
  }
}
