// TCP-клиент для эхо-сервера

package main

import "core:fmt"
import "core:net"
import "core:os"
import "core:strings"
import "core:thread"

HOST :: "127.0.0.1"
PORT :: 8080

// поток для чтения ответов сервера
reader_thread :: proc(sock: net.TCP_Socket) {
	buf: [1024]byte
	for {
		n, err := net.recv(sock, buf[:])
		if err != nil || n == 0 {
			fmt.println("[client] server closed connection")
			return
		}
		fmt.print(string(buf[:n]))
	}
}

main :: proc() {
	endpoint := net.Endpoint{
		address = net.IP4_Address{127, 0, 0, 1},
		port    = PORT,
	}

	sock, err := net.dial_tcp_from_endpoint(endpoint)
	if err != nil {
		fmt.eprintln("cannot connect:", err)
		os.exit(1)
	}
	defer net.close(sock)

	fmt.println("[client] connected to", HOST, ":", PORT)

	thread.create_and_start_with_poly_data(sock, reader_thread)

	// главный цикл: читаем stdin по строкам
	buf: [4096]byte
	acc: [dynamic]u8
	defer delete(acc)

	for {
		n, read_err := os.read(os.stdin, buf[:])
		if read_err != nil || n == 0 {
			break
		}
		for i in 0 ..< n {
			c := buf[i]
			if c == '\n' {
				line := strings.trim_space(string(acc[:]))
				clear(&acc)
				if len(line) == 0 {
					continue
				}
				to_send := fmt.tprintf("%s\n", line)
				net.send(sock, transmute([]byte)to_send)
				if strings.to_upper(line) == "QUIT" {
					return
				}
			} else {
				append(&acc, c)
			}
		}
	}
}