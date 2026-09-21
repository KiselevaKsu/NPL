# Задача 5.3. Пользовательский формат «список игроков» → JSON

## Тема

Конвертация данных из одного формата в другой.

## Язык

OCaml.

## Условие

Дан текстовый файл со списком игроков в пользовательском формате:

```
player: name=Alice level=10 score=1500
player: name=Bob level=5 score=800
```

Нужно разобрать его рекурсивно и преобразовать в JSON-массив
объектов:

```json
[
  {"name": "Alice", "level": 10, "score": 1500},
  {"name": "Bob", "level": 5, "score": 800}
]
```

Числовые поля (`level`, `score`) должны выводиться как числа,
строковые (`name`) — как строки.

## Что демонстрирует

- рекурсивный разбор текстового формата;
- работу с рекурсивными типами;
- генерацию JSON с экранированием;
- запись результата в файл.

## Структура

```
task_3_ocaml/
├── README.md        — этот файл
├── players2json.ml  — главная программа
└── input.txt        — пример входного файла
```

## Сборка и запуск

Требуется OCaml (`ocaml` или `ocamlfind`).

```bash
ocamlfind ocamlopt -package str players2json.ml -o players2json
./players2json input.txt output.json
```

Или через интерпретатор:

```bash
ocaml players2json.ml input.txt output.json
```

## Формат ввода

Строки вида:

```
player: name=Alice level=10 score=1500
player: name=Bob level=5 score=800
```

Поля разделены пробелами, пары `ключ=значение`.

## Формат вывода

`output.json`:

```json
[
  {"name": "Alice", "level": 10, "score": 1500},
  {"name": "Bob", "level": 5, "score": 800}
]
```

## Примечания

Специализированные библиотеки не используются — только стандартная
библиотека OCaml (`Str` для разбора, `Printf` для вывода).
