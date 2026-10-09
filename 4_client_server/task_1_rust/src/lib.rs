// общий модуль для сервера и клиента: структура голосования

use std::collections::HashMap;

#[derive(Clone)]
pub struct Poll {
    pub question: String,
    pub options: Vec<String>,
    pub votes: HashMap<String, Vec<usize>>, // имя клиента -> список индексов вариантов
}

impl Poll {
    pub fn new(question: String, options: Vec<String>) -> Self {
        Poll {
            question,
            options,
            votes: HashMap::new(),
        }
    }

    pub fn vote(&mut self, voter: String, option_index: usize) {
        self.votes.entry(voter).or_default().push(option_index);
    }

    pub fn stats(&self) -> Vec<usize> {
        let mut counts = vec![0usize; self.options.len()];
        for opts in self.votes.values() {
            for &i in opts {
                if i < counts.len() {
                    counts[i] += 1;
                }
            }
        }
        counts
    }

    pub fn format_stats(&self, id: usize) -> String {
        let counts = self.stats();
        let mut s = format!("Poll #{}: {}\n", id, self.question);
        for (i, opt) in self.options.iter().enumerate() {
            s.push_str(&format!("  {}) {} — {}\n", i + 1, opt, counts[i]));
        }
        s
    }
}