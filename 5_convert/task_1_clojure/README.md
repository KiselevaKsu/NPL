# Задача 5.1. CSV → HTML-таблица

## Тема

Конвертация данных из одного формата в другой.

## Язык

Clojure.

## Условие

Дан CSV-файл. Нужно преобразовать его в HTML-таблицу. Первая строка
CSV считается заголовком. Разбор CSV должен учитывать кавычки,
запятые внутри полей и удвоенные кавычки (`""` → `"`). На выходе —
HTML-файл с таблицей и минимальными стилями.

## Что демонстрирует

- собственный парсер CSV (без сторонних библиотек);
- обработку кавычек и экранирования;
- генерацию HTML;
- запись результата в файл.

## Структура

```
task_1_clojure/
├── README.md       — этот файл
├── csv2html.clj    — главная программа
└── input.csv       — пример входного файла
```

## Сборка и запуск

Требуется Clojure (`clojure` CLI или `clj`).

```bash
clojure -M csv2html.clj input.csv output.html
```

Или как скрипт:

```bash
clj -M csv2html.clj input.csv output.html
```

## Формат ввода

CSV-файл, например:

```
name,age,city
Alice,30,"Moscow, RU"
Bob,25,"Saint ""Petersburg"""
```

## Формат вывода

HTML-файл:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>CSV → HTML</title>
  <style>
    table { border-collapse: collapse; }
    th, td { border: 1px solid #999; padding: 4px 8px; }
    th { background: #eee; }
  </style>
</head>
<body>
  <table>
    <tr><th>name</th><th>age</th><th>city</th></tr>
    <tr><td>Alice</td><td>30</td><td>Moscow, RU</td></tr>
    <tr><td>Bob</td><td>25</td><td>Saint "Petersburg"</td></tr>
  </table>
</body>
</html>
```

## Примечания

Специализированные библиотеки не используются — только стандартная
библиотека Clojure (`clojure.string`, `clojure.java.io`).
