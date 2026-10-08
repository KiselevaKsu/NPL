// наибольшая общая подпоследовательность двух строк

val memo = mutableMapOf<Pair<Int, Int>, Int>()

// рекурсивно считаем длину НОП
fun lcsLength(s1: String, s2: String, i: Int, j: Int): Int {
    if (i == 0 || j == 0) return 0
    val key = i to j
    memo[key]?.let { return it }
    val result = if (s1[i - 1] == s2[j - 1]) {
        lcsLength(s1, s2, i - 1, j - 1) + 1
    } else {
        maxOf(lcsLength(s1, s2, i - 1, j), lcsLength(s1, s2, i, j - 1))
    }
    memo[key] = result
    return result
}

// восстанавливаем саму подпоследовательность обратным проходом
fun reconstruct(s1: String, s2: String): String {
    var i = s1.length
    var j = s2.length
    val sb = StringBuilder()
    while (i > 0 && j > 0) {
        if (s1[i - 1] == s2[j - 1]) {
            sb.append(s1[i - 1])
            i--
            j--
        } else if (lcsLength(s1, s2, i - 1, j) >= lcsLength(s1, s2, i, j - 1)) {
            i--
        } else {
            j--
        }
    }
    return sb.reverse().toString()
}

fun main() {
    val s1 = "AGGTAB"
    val s2 = "GXTXAYB"

    println("String 1: $s1")
    println("String 2: $s2")

    val len = lcsLength(s1, s2, s1.length, s2.length)
    val lcs = reconstruct(s1, s2)

    println("LCS length: $len")
    println("LCS: $lcs")
}