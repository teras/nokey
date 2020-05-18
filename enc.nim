import myexec, json, os

const OPENSSL=
    when system.hostOS == "windows": "openssl.exe"
    else: "openssl"

template echoNoLine(txt:string) =
    stdout.write txt
    stdout.flushFile

proc storeKeystore*(content:JsonNode, location:string, pass:string) =
    location.parentDir.createDir
    var(text,exitCode) = myExec(@[OPENSSL, "enc", "-salt", "-a", "-aes-256-cbc", "-pass", "pass:"&pass, "-out", location], $content)
    echoNoLine text
    if exitCode != 0:
        quit("Unable to store keychain under " & location)

proc readKeystore*(location:string, pass:string):JsonNode =
    var text = """{}"""
    if location.fileExists:
        var exitCode:int
        (text,exitCode) = myExec(@[OPENSSL, "enc", "-d", "-salt", "-a", "-aes-256-cbc", "-pass", "pass:"&pass, "-in", location])
        if exitCode != 0: quit("Unable to read keystore")
    result = text.parseJson
    result.storeKeystore(location, pass)
