// Эхо-сервер с журналированием обращений

package main

import "core:fmt"
import "core:net"
import "core:os"
import "core:strings"
import "core:thread"
import "core:time"
import "core:bytes"

PORT :: 8080
LOG_FILE :: "server.log"

// Записать строку в журнал
log_message :: proc(msg: string) {
	f, err := os.open(LOG_FILE, os.O_CREATE | os.O_APPEND | os.O_WRONLY, os.Permissions_Default)
	if err != nil {
		fmt.eprintln("cannot open log file:", err)
		return
	}
	defer os.close(f)

	t := time.now()
	y, m, d := time.date(t)
	h, mi, s := time.clock(t)
	line := fmt.tprintf("%04d-%02d-%02d %02d:%02d:%02d %s\n", y, int(m), d, h, mi, s, msg)
	os.write_string(f, line)
}

// Обработать одну команду, вернуть ответ
handle_command :: proc(peer: string, line: string) -> string {
	trimmed := strings.trim_space(line)
	log_message(fmt.tprintf("%s %s", peer, trimmed))

	upper := strings.to_upper(trimmed)
	if strings.has_prefix(upper, "ECHO ") {
		return trimmed[5:]
	} else if upper == "TIME" {
		t := time.now()
		y, m, d := time.date(t)
		h, mi, s := time.clock(t)
		return fmt.tprintf("%04d-%02d-%02d %02d:%02d:%02d", y, int(m), d, h, mi, s)
	} else if strings.has_prefix(upper, "UPPER ") {
		return strings.to_upper(trimmed[6:])
	} else if upper == "QUIT" {
		return "Bye."
	} else {
		return "ERROR: unknown command"
	}
}

// Обработать одного клиента
handle_client :: proc(sock: net.TCP_Socket, peer: string) {
	fmt.println("[server] client connected:", peer)
	log_message(fmt.tprintf("%s CONNECTED", peer))
	defer {
		net.close(sock)
		fmt.println("[server] client disconnected:", peer)
		log_message(fmt.tprintf("%s DISCONNECTED", peer))
	}

	buf: [1024]byte
	for {
		n, err := net.recv(sock, buf[:])
		if err != nil || n == 0 {
			break
		}
		text := string(buf[:n])
		lines := strings.split_lines(text)
		for line in lines {
			if len(strings.trim_space(line)) == 0 {
				continue
			}
			response := handle_command(peer, line)
			to_send := fmt.tprintf("%s\n", response)
			net.send(sock, transmute([]byte)to_send)
			if strings.to_upper(strings.trim_space(line)) == "QUIT" {
				return
			}
		}
	}
}

main :: proc() {
	endpoint := net.Endpoint{
		address = net.IP4_Address{127, 0, 0, 1},
		port    = PORT,
	}

	listener, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.eprintln("cannot listen:", err)
		os.exit(1)
	}
	defer net.close(listener)

	fmt.println("[server] listening on port", PORT)

	for {
		client, client_endpoint, err := net.accept_tcp(listener)
		if err != nil {
			fmt.eprintln("accept error:", err)
			continue
		}
		peer := fmt.tprintf("%v", client_endpoint)
		// запускаем поток на клиента
		thread.create_and_start_with_poly_data2(client, peer, handle_client)
	}
}