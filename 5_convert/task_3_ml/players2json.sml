(* Custom TXT → JSON: разбор списка игроков *)

structure Players2Json = struct

  (* убрать пробелы в начале и конце *)
  fun strip s =
    let
      fun dropLeft str =
        if size str = 0 then ""
        else
          let val c = String.sub (str, 0)
          in
            if Char.isSpace c then dropLeft (String.extract (str, 1, NONE))
            else str
          end
      fun dropRight str =
        let val n = size str
        in
          if n = 0 then ""
          else
            let val c = String.sub (str, n - 1)
            in
              if Char.isSpace c then dropRight (String.substring (str, 0, n - 1))
              else str
            end
        end
    in
      dropRight (dropLeft s)
    end

  (* разделить строку по разделителю *)
  fun splitOn delim s = String.tokens (fn c => c = delim) s

  (* разобрать пару key=value *)
  fun parsePair pair =
    case splitOn #"=" pair of
        [k, v] => (k, v)
      | _ => ("", "")

  (* разобрать одну строку player: key1=val1 key2=val2 ... *)
  fun parseLine line =
    let
      val trimmed = strip line
      val tokens = String.tokens Char.isSpace trimmed
    in
      case tokens of
          ("player:" :: rest) => List.map parsePair rest
        | _ => []
    end

  (* прочитать все строки файла *)
  fun readLines filename =
    let
      val f = TextIO.openIn filename
      fun loop acc =
        case TextIO.inputLine f of
            NONE => List.rev acc
          | SOME line => loop (strip line :: acc)
      val lines = loop []
    in
      TextIO.closeIn f;
      lines
    end

  (* экранировать строку для JSON *)
  fun jsonEscape s =
    let
      fun esc #"\"" = "\\\""
        | esc #"\\" = "\\\\"
        | esc #"\n" = "\\n"
        | esc #"\t" = "\\t"
        | esc c = String.str c
    in
      String.translate (fn c => esc c) s
    end

  (* превратить поле key=value в JSON-фрагмент *)
  fun fieldToJson (k, v) =
    let
      val numOpt = Int.fromString v
    in
      case numOpt of
          SOME n => "\"" ^ jsonEscape k ^ "\": " ^ Int.toString n
        | NONE => "\"" ^ jsonEscape k ^ "\": \"" ^ jsonEscape v ^ "\""
    end

  (* превратить одну запись игрока в JSON-объект *)
  fun recordToJson fields =
    "{" ^ String.concatWith ", " (List.map fieldToJson fields) ^ "}"

  (* превратить все записи в JSON-массив *)
  fun toJson lines =
    let
      val records = List.map parseLine lines
      val recordsJson = List.map recordToJson records
    in
      "[\n  " ^ String.concatWith ",\n  " recordsJson ^ "\n]\n"
    end

  (* записать строку в файл *)
  fun writeFile filename contents =
    let
      val out = TextIO.openOut filename
    in
      TextIO.output (out, contents);
      TextIO.closeOut out
    end

  (* main *)
  fun main () =
    let
      val inputFile = "input.txt"
      val outputFile = "output.json"
      val lines = readLines inputFile
      val json = toJson lines
    in
      writeFile outputFile json;
      print ("Input:  " ^ inputFile ^ "\n");
      print ("Output: " ^ outputFile ^ "\n")
    end

end

val _ = Players2Json.main ()