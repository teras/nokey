import myexec, json, os

const OPENSSL=
    when system.hostOS == "windows": "openssl.exe"
    else: "openssl"

template echoNoLine(txt:string) =
    stdout.write txt
    stdout.flushFile

proc store(content:string, location:string, pass:string) =
    location.parentDir.createDir
    var(text,_) = myExec(@[OPENSSL, "enc", "-salt", "-a", "-aes-256-cbc", "-pass", "pass:"&pass, "-out", location], $content)
    echoNoLine text

proc read(location:string, pass:string):string =
    result = """{}"""
    if location.fileExists:
        var ec:int
        (result,ec) = myExec(@[OPENSSL, "enc", "-d", "-salt", "-a", "-aes-256-cbc", "-pass", "pass:"&pass, "-in", location])

proc storeKeystore*(content:JsonNode, location:string, pass:string) =
    let data = $content
    store(data, location, pass)
    if data != read(location, pass):
        echo "Unable to save data"

proc readKeystore*(location:string, pass:string):JsonNode = read(location, pass).parseJson
