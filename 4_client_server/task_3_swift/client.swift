// TCP-клиент учёта задач (Windows, через WinSDK)

import Foundation
import WinSDK

let HOST = "127.0.0.1"
let PORT: UInt16 = 8080

func sendAll(_ sock: SOCKET, _ text: String) -> Bool {
    let data = Array(text.utf8)
    var sent = 0
    while sent < data.count {
        let result = data.withUnsafeBytes { buf -> Int in
            let ptr = buf.baseAddress!.advanced(by: sent).assumingMemoryBound(to: CChar.self)
            return Int(send(sock, ptr, Int32(data.count - sent), 0))
        }
        if result <= 0 { return false }
        sent += result
    }
    return true
}

func recvLine(_ sock: SOCKET) -> String? {
    var buffer: [UInt8] = []
    var byte: UInt8 = 0
    while true {
        let n = withUnsafeMutablePointer(to: &byte) { ptr -> Int in
            return Int(recv(sock, ptr, 1, 0))
        }
        if n <= 0 { return nil }
        if byte == 0x0A { return String(bytes: buffer, encoding: .utf8) }
        buffer.append(byte)
    }
}

var wsa = WSAData()
if WSAStartup(0x0202, &wsa) != 0 {
    print("WSAStartup failed"); exit(1)
}

let sock = socket(AF_INET, SOCK_STREAM, 0)
if sock == INVALID_SOCKET { print("socket() failed"); exit(1) }

var addr = sockaddr_in()
addr.sin_family = ADDRESS_FAMILY(AF_INET)
addr.sin_port = PORT.bigEndian
addr.sin_addr.S_un.S_addr = inet_addr(HOST)

let connectResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
        return connect(sock, saPtr, Int32(MemoryLayout<sockaddr_in>.size))
    }
}
if connectResult != 0 { print("connect() failed"); exit(1) }

print("[client] connected to \(HOST):\(PORT)")

let readerThread = Thread {
    while let line = recvLine(sock) {
        print(line, terminator: "\r\n")
        fflush(stdout)
    }
    print("[client] server closed connection")
}
readerThread.start()

while let line = readLine(strippingNewline: true) {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { continue }
    if !sendAll(sock, trimmed + "\n") { break }
    if trimmed.uppercased() == "QUIT" { break }
}