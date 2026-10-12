;; CSV → HTML-таблица

(require '[clojure.string :as str])

;; Возвращает вектор строк (каждая строка — вектор полей).
;; Учитывает кавычки, запятые внутри полей, удвоенные кавычки.

(defn parse-csv-line [line]
  (loop [chars (seq line)
         field (StringBuilder.)
         fields []
         in-quotes false]
    (if (empty? chars)
      (conj fields (str field))
      (let [c (first chars)
            rest-chars (rest chars)]
        (cond
          ;; внутри кавычек: если две кавычки подряд - экранированная кавычка
          (and in-quotes (= c \") (= (first rest-chars) \"))
          (do (.append field \")
              (recur (rest rest-chars) field fields in-quotes))

          ;; закрывающая кавычка
          (and in-quotes (= c \"))
          (recur rest-chars field fields false)

          ;; открывающая кавычка в начале поля
          (and (not in-quotes) (= c \") (= (.length field) 0))
          (recur rest-chars field fields true)

          ;; запятая вне кавычек - конец поля
          (and (not in-quotes) (= c \,))
          (recur rest-chars (StringBuilder.) (conj fields (str field)) false)

          ;; обычный символ
          :else
          (do (.append field c)
              (recur rest-chars field fields in-quotes)))))))

(defn parse-csv [text]
  (->> (str/split-lines text)
       (remove str/blank?)
       (mapv parse-csv-line)))

;; Экранирование HTML
(defn escape-html [s]
  (-> s
      (str/replace "&" "&amp;")
      (str/replace "<" "&lt;")
      (str/replace ">" "&gt;")
      (str/replace "\"" "&quot;")))

;; Генерация HTML
(defn csv->html [rows]
  (let [header (first rows)
        body (rest rows)]
    (str
      "<!DOCTYPE html>\n"
      "<html>\n<head>\n"
      "  <meta charset=\"utf-8\">\n"
      "  <title>CSV → HTML</title>\n"
      "  <style>\n"
      "    table { border-collapse: collapse; font-family: sans-serif; }\n"
      "    th, td { border: 1px solid #999; padding: 6px 12px; text-align: left; }\n"
      "    th { background: #eee; }\n"
      "    tr:nth-child(even) { background: #f9f9f9; }\n"
      "  </style>\n"
      "</head>\n<body>\n"
      "  <table>\n"
      "    <thead>\n"
      "      <tr>"
      (str/join "" (map #(str "<th>" (escape-html %) "</th>") header))
      "</tr>\n"
      "    </thead>\n"
      "    <tbody>\n"
      (str/join "\n"
        (map (fn [row]
               (str "      <tr>"
                    (str/join "" (map #(str "<td>" (escape-html %) "</td>") row))
                    "</tr>"))
             body))
      "\n    </tbody>\n"
      "  </table>\n"
      "</body>\n</html>\n")))

(defn -main [& args]
  (let [input-file (or (first args) "input.csv")
        output-file (or (second args) "output.html")
        text (slurp input-file)
        rows (parse-csv text)
        html (csv->html rows)]
    (spit output-file html)
    (println (str "Input:  " input-file))
    (println (str "Rows:   " (count rows)))
    (println (str "Output: " output-file))))

(apply -main *command-line-args*)