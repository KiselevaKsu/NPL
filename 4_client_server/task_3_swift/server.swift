// TCP-сервер учёта задач (Windows, через WinSDK)

import Foundation
import WinSDK

let PORT: UInt16 = 8080

var tasks: [String] = []
let stateLock = NSLock()

var clients: [SOCKET] = []
let clientsLock = NSLock()

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

func broadcast(_ message: String) {
    clientsLock.lock()
    let current = clients
    clientsLock.unlock()

    var dead: [SOCKET] = []
    for c in current {
        if !sendAll(c, message) { dead.append(c) }
    }
    if !dead.isEmpty {
        clientsLock.lock()
        clients.removeAll { dead.contains($0) }
        clientsLock.unlock()
    }
}

func formatTasks() -> String {
    stateLock.lock()
    let snapshot = tasks
    stateLock.unlock()

    if snapshot.isEmpty { return "Task list is empty.\n" }
    var s = "Task list:\n"
    for (i, t) in snapshot.enumerated() {
        s += "  \(i + 1). \(t)\n"
    }
    return s
}

func handleClient(_ sock: SOCKET, _ id: Int) {
    print("[server] client \(id) connected")
    _ = sendAll(sock, "Connected. Commands: ADD <text>, DEL <num>, LIST, QUIT\n")
    _ = sendAll(sock, formatTasks())

    while let line = recvLine(sock) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { continue }
        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let cmd = parts[0].uppercased()

        switch cmd {
        case "ADD":
            guard parts.count >= 2 else {
                _ = sendAll(sock, "ERROR: usage ADD <text>\n"); continue
            }
            let text = String(parts[1])
            stateLock.lock(); tasks.append(text); stateLock.unlock()
            _ = sendAll(sock, "Added: \(text)\n")
            broadcast(formatTasks())

        case "DEL":
            guard parts.count >= 2, let num = Int(parts[1]), num >= 1 else {
                _ = sendAll(sock, "ERROR: invalid task number\n"); continue
            }
            stateLock.lock()
            if num <= tasks.count {
                let removed = tasks.remove(at: num - 1)
                stateLock.unlock()
                _ = sendAll(sock, "Deleted: \(removed)\n")
                broadcast(formatTasks())
            } else {
                stateLock.unlock()
                _ = sendAll(sock, "ERROR: task number out of range\n")
            }

        case "LIST":
            _ = sendAll(sock, formatTasks())

        case "QUIT":
            _ = sendAll(sock, "Bye.\n")
            closesocket(sock)
            print("[server] client \(id) disconnected")
            return

        default:
            _ = sendAll(sock, "ERROR: unknown command\n")
        }
    }
    closesocket(sock)
    print("[server] client \(id) disconnected")
}

// запуск
var wsa = WSAData()
if WSAStartup(0x0202, &wsa) != 0 {
    print("WSAStartup failed"); exit(1)
}

let serverSock = socket(AF_INET, SOCK_STREAM, 0)
if serverSock == INVALID_SOCKET {
    print("socket() failed"); exit(1)
}

var addr = sockaddr_in()
addr.sin_family = ADDRESS_FAMILY(AF_INET)
addr.sin_port = PORT.bigEndian
addr.sin_addr.S_un.S_addr = inet_addr("127.0.0.1")

let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
        return bind(serverSock, saPtr, Int32(MemoryLayout<sockaddr_in>.size))
    }
}
if bindResult != 0 { print("bind() failed"); exit(1) }
if listen(serverSock, 10) != 0 { print("listen() failed"); exit(1) }

print("[server] listening on port \(PORT)")

var nextId = 1
while true {
    let clientSock = accept(serverSock, nil, nil)
    if clientSock == INVALID_SOCKET { continue }

    clientsLock.lock(); clients.append(clientSock); clientsLock.unlock()

    let id = nextId
    nextId += 1

    let thread = Thread {
        handleClient(clientSock, id)
    }
    thread.start()
}