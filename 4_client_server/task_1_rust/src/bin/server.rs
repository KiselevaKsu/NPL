use std::collections::HashMap;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use std::thread;

use voting::Poll;

type Polls = Arc<Mutex<HashMap<usize, Poll>>>;
type Clients = Arc<Mutex<Vec<TcpStream>>>;

fn broadcast(clients: &Clients, message: &str) {
    let mut list = clients.lock().unwrap();
    list.retain_mut(|c| c.write_all(message.as_bytes()).is_ok());
}

fn handle_client(
    stream: TcpStream,
    polls: Polls,
    clients: Clients,
    client_id: usize,
) {
    let peer = stream.peer_addr().map(|a| a.to_string()).unwrap_or_else(|_| "unknown".into());
    println!("[server] client {} connected: {}", client_id, peer);

    let reader = BufReader::new(stream.try_clone().unwrap());
    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        let line = line.trim().to_string();
        if line.is_empty() { continue; }

        let parts: Vec<&str> = line.splitn(3, ' ').collect();
        let cmd = parts[0].to_uppercase();

        match cmd.as_str() {
            "CREATE" => {
                if parts.len() < 2 {
                    let _ = stream.try_clone().unwrap().write_all(b"ERROR: usage CREATE <question>|<opt1>|<opt2>|...\n");
                    continue;
                }
                let rest = parts[1..].join(" ");
                let tokens: Vec<&str> = rest.split('|').map(|s| s.trim()).collect();
                if tokens.len() < 2 {
                    let _ = stream.try_clone().unwrap().write_all(b"ERROR: need at least 2 options\n");
                    continue;
                }
                let question = tokens[0].to_string();
                let options: Vec<String> = tokens[1..].iter().map(|s| s.to_string()).collect();
                let mut p = polls.lock().unwrap();
                let id = p.len() + 1;
                p.insert(id, Poll::new(question.clone(), options));
                let msg = format!("Poll #{} created: {}\n", id, question);
                let _ = stream.try_clone().unwrap().write_all(msg.as_bytes());
                broadcast(&clients, &format!("[new poll] #{} {}\n", id, question));
            }
            "VOTE" => {
                if parts.len() < 3 {
                    let _ = stream.try_clone().unwrap().write_all(b"ERROR: usage VOTE <id> <option_number>\n");
                    continue;
                }
                let id: usize = match parts[1].parse() {
                    Ok(v) => v,
                    Err(_) => {
                        let _ = stream.try_clone().unwrap().write_all(b"ERROR: invalid poll id\n");
                        continue;
                    }
                };
                let opt: usize = match parts[2].parse::<usize>() {
                    Ok(v) if v >= 1 => v - 1,
                    _ => {
                        let _ = stream.try_clone().unwrap().write_all(b"ERROR: invalid option number\n");
                        continue;
                    }
                };
                let voter = format!("client{}", client_id);
                let stats_text = {
                    let mut p = polls.lock().unwrap();
                    match p.get_mut(&id) {
                        Some(poll) => {
                            if opt >= poll.options.len() {
                                let _ = stream.try_clone().unwrap().write_all(b"ERROR: option out of range\n");
                                continue;
                            }
                            poll.vote(voter, opt);
                            poll.format_stats(id)
                        }
                        None => {
                            let _ = stream.try_clone().unwrap().write_all(b"ERROR: poll not found\n");
                            continue;
                        }
                    }
                };
                let _ = stream.try_clone().unwrap().write_all(b"Vote accepted.\n");
                broadcast(&clients, &stats_text);
            }
            "STATS" => {
                if parts.len() < 2 {
                    let _ = stream.try_clone().unwrap().write_all(b"ERROR: usage STATS <id>\n");
                    continue;
                }
                let id: usize = match parts[1].parse() {
                    Ok(v) => v,
                    Err(_) => {
                        let _ = stream.try_clone().unwrap().write_all(b"ERROR: invalid poll id\n");
                        continue;
                    }
                };
                let text = {
                    let p = polls.lock().unwrap();
                    match p.get(&id) {
                        Some(poll) => poll.format_stats(id),
                        None => "ERROR: poll not found\n".to_string(),
                    }
                };
                let _ = stream.try_clone().unwrap().write_all(text.as_bytes());
            }
            "QUIT" => {
                let _ = stream.try_clone().unwrap().write_all(b"Bye.\n");
                break;
            }
            _ => {
                let _ = stream.try_clone().unwrap().write_all(b"ERROR: unknown command\n");
            }
        }
    }
    println!("[server] client {} disconnected", client_id);
}

fn main() {
    let addr = std::env::args().nth(1).unwrap_or_else(|| "127.0.0.1:8080".to_string());
    let listener = TcpListener::bind(&addr).expect("cannot bind");
    println!("[server] listening on {}", addr);

    let polls: Polls = Arc::new(Mutex::new(HashMap::new()));
    let clients: Clients = Arc::new(Mutex::new(Vec::new()));

    let mut next_id = 1usize;
    for stream in listener.incoming() {
        match stream {
            Ok(s) => {
                let s2 = s.try_clone().unwrap();
                clients.lock().unwrap().push(s2);
                let polls = Arc::clone(&polls);
                let clients = Arc::clone(&clients);
                let id = next_id;
                next_id += 1;
                thread::spawn(move || handle_client(s, polls, clients, id));
            }
            Err(e) => eprintln!("[server] accept error: {}", e),
        }
    }
}