import myexec, json, os

proc storeKeystore*(content:JsonNode, location:string, pass:string) =
    location.parentDir.createDir
    var(text,exitCode) = myExec(@["openssl", "enc", "-salt", "-aes-256-cbc", "-pass", "pass:"&pass, "-out", location], $content)
    if exitCode != 0 or text.len>0:
        quit("Unable to store keychain under " & location)

proc readKeystore*(location:string, pass:string):JsonNode =
    var text = """{}"""
    if location.fileExists:
        var exitCode:int
        (text,exitCode) = myExec(@["openssl", "enc", "-d", "-salt", "-aes-256-cbc", "-pass", "pass:"&pass, "-in", location])
        if exitCode != 0 or text.len < 1: quit("Unable to read keystore")
    result = text.parseJson
    result.storeKeystore(location, pass)
