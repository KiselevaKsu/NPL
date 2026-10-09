use std::io::{BufRead, BufReader, Write};
use std::net::TcpStream;
use std::thread;

fn main() {
    let addr = std::env::args().nth(1).unwrap_or_else(|| "127.0.0.1:8080".to_string());
    let stream = TcpStream::connect(&addr).expect("cannot connect");
    println!("[client] connected to {}", addr);

    // поток для чтения ответов сервера
    let reader_stream = stream.try_clone().unwrap();
    thread::spawn(move || {
        let reader = BufReader::new(reader_stream);
        for line in reader.lines() {
            match line {
                Ok(l) => println!("{}", l),
                Err(_) => break,
            }
        }
    });

    // чтение команд с консоли и отправка
    let stdin = std::io::stdin();
    let mut writer = stream;
    loop {
        let mut buf = String::new();
        if stdin.read_line(&mut buf).is_err() { break; }
        let line = buf.trim();
        if line.is_empty() { continue; }
        if writer.write_all(line.as_bytes()).is_err() { break; }
        if writer.write_all(b"\n").is_err() { break; }
        if line.eq_ignore_ascii_case("QUIT") { break; }
    }
}