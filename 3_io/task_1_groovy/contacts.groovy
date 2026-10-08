// консольный редактор списка контактов с хранением в файле

List<Map> loadContacts() {
    def file = new File("contacts.txt")
    if (!file.exists()) return []
    def result = []
    file.eachLine { line ->
        def parts = line.split("\\|")
        if (parts.length == 3) {
            result << [name: parts[0], phone: parts[1], email: parts[2]]
        }
    }
    return result
}

void saveContacts(List<Map> contacts) {
    def file = new File("contacts.txt")
    file.withWriter { w ->
        contacts.each { c ->
            w.println("${c.name}|${c.phone}|${c.email}")
        }
    }
}

void printContacts(List<Map> contacts) {
    if (contacts.isEmpty()) {
        println "No contacts."
        return
    }
    contacts.eachWithIndex { c, i ->
        println "${i + 1}. ${c.name} | ${c.phone} | ${c.email}"
    }
}

boolean isValidPhone(String phone) {
    return phone ==~ /^[+]?[0-9\s\-()]{5,20}$/
}

boolean isValidEmail(String email) {
    return email ==~ /^[^@\s]+@[^@\s]+\.[^@\s]+$/
}

def contacts = loadContacts()
def reader = new BufferedReader(new InputStreamReader(System.in))

println "Contact manager. Commands: add, list, find, del, exit"

while (true) {
    print "> "
    def cmd = reader.readLine()
    if (cmd == null) break
    cmd = cmd.trim().toLowerCase()

    if (cmd.isEmpty()) {
        println "Empty command. Use: add, list, find, del, exit"
        continue
    }

    switch (cmd) {
        case "add":
            print "Name: "
            def name = reader.readLine()?.trim()
            print "Phone: "
            def phone = reader.readLine()?.trim()
            print "Email: "
            def email = reader.readLine()?.trim()

            if (!name || !phone || !email) {
                println "Error: all fields are required."
                break
            }
            if (!isValidPhone(phone)) {
                println "Error: invalid phone format."
                break
            }
            if (!isValidEmail(email)) {
                println "Error: invalid email format."
                break
            }
            if (contacts.any { it.name.equalsIgnoreCase(name) }) {
                println "Error: contact with this name already exists."
                break
            }

            contacts << [name: name, phone: phone, email: email]
            saveContacts(contacts)
            println "Contact added."
            break

        case "list":
            printContacts(contacts)
            break

        case "find":
            print "Name: "
            def q = reader.readLine()?.trim()
            if (!q) {
                println "Error: empty query."
                break
            }
            def found = contacts.findAll { it.name.toLowerCase().contains(q.toLowerCase()) }
            if (found.isEmpty()) {
                println "Not found."
            } else {
                printContacts(found)
            }
            break

        case "del":
            print "Name: "
            def d = reader.readLine()?.trim()
            if (!d) {
                println "Error: empty name."
                break
            }
            def before = contacts.size()
            contacts.removeAll { it.name.equalsIgnoreCase(d) }
            if (contacts.size() < before) {
                saveContacts(contacts)
                println "Deleted ${before - contacts.size()} contact(s)."
            } else {
                println "Not found."
            }
            break

        case "exit":
            println "Bye."
            return

        default:
            println "Unknown command. Use: add, list, find, del, exit"
    }
}