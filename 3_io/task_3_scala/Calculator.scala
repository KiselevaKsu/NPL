// консольный калькулятор с историей операций в файле

import scala.io.StdIn
import java.io.{File, BufferedWriter, FileWriter}
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

object Calculator {

  val historyFile = "history.txt"

  def parseAndEval(line: String): Option[Double] = {
    val parts = line.trim.split("\\s+")
    if (parts.length != 3) return None
    try {
      val a = parts(0).toDouble
      val op = parts(1)
      val b = parts(2).toDouble
      op match {
        case "+" => Some(a + b)
        case "-" => Some(a - b)
        case "*" => Some(a * b)
        case "/" => if (b == 0) None else Some(a / b)
        case _   => None
      }
    } catch {
      case _: NumberFormatException => None
    }
  }

  def appendHistory(expr: String, result: Double): Unit = {
    val fw = new FileWriter(historyFile, true)
    val bw = new BufferedWriter(fw)
    val time = LocalDateTime.now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
    bw.write(s"$time | $expr = $result")
    bw.newLine()
    bw.close()
  }

  def printHistory(): Unit = {
    val file = new File(historyFile)
    if (!file.exists() || file.length() == 0) {
      println("History is empty.")
      return
    }
    println("History:")
    val source = scala.io.Source.fromFile(historyFile)
    source.getLines().foreach(line => println("  " + line))
    source.close()
  }

  def main(args: Array[String]): Unit = {
    println("Calculator. Format: <number> <op> <number>")
    println("Operators: + - * /")
    println("Commands: history, exit")
    println()

    if (new File(historyFile).exists()) {
      println("Previous history:")
      printHistory()
      println()
    }

    while (true) {
      print("> ")
      val line = StdIn.readLine()
      if (line == null) return
      val trimmed = line.trim

      trimmed.toLowerCase match {
        case "exit" =>
          println("Bye.")
          return
        case "history" =>
          printHistory()
        case "" =>
          println("Empty input.")
        case _ =>
          parseAndEval(trimmed) match {
            case Some(result) =>
              println(s"= $result")
              appendHistory(trimmed, result)
            case None =>
              println("Error: invalid expression or division by zero.")
          }
      }
    }
  }
}