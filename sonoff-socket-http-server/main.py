import machine
import socket

pin = machine.Pin(12, machine.Pin.OUT)
timer = machine.Timer(-1)

s = socket.socket()
s.bind(('', 80))
s.listen(5)

running = True
while running:
    conn, addr = s.accept()
    connfile = conn.makefile('rwb', 0)
    lines = []
    while True:
        line = connfile.readline()
        print(line)
        if not line or line == b'\r\n':
            break
        lines.append(line)
    (method, path, _) = lines[0].decode('latin1').split(' ', 2)
    if method == 'POST':
        if path == '/on':
            pin.high()
            timer.deinit()
        elif path == '/off':
            pin.low()
            timer.deinit()
        elif path.startswith('/expose?time='):
            duration = int(path.lstrip('/expose?time='))
            pin.high()
            timer.init(period=duration, callback=lambda t: pin.low())
        elif path == '/exit':
            running = False
    conn.send('HTTP/1.1 200 OK\r\n')
    conn.send('Content-Type: text/plain\r\n')
    conn.send('Connection: close\r\n\r\n')
    conn.send('OK')
    conn.close()
