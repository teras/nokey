import os, argparse, terminal, json
import enc

const DEFAULT_KEYSTORE = ".ssh/nokey"
const ENV_VARIABLE = "NOKEY_PASSWORD"

const p = newParser("nokey"):
    help("Store and retrieve passwords securely using an openssl backend")
    option("-k", "--keystore", help="Where to store the encrypted file, defaults to ~/" & DEFAULT_KEYSTORE)
    option("-p", "--password", env=ENV_VARIABLE, help="The password of this keychan. Defaults to environmental variable "&ENV_VARIABLE)
    option("-g", "--group", help="Perform action on named group. Defaults to 'common'")
    option("-a", "--add", help="Store a variable ")
    option("-d", "--delete", help="Delete a variable ")
    option("-x", "--export", help="Export commands for given shell (either 'bash' or 'fish')", choices= @["fish", "bash"])
    flag("-c", "--changepass", help="Change the current keystore password")
    flag("-l", "--list", help="Show all variables")
let opts = p.parse(commandLineParams())

let keystoreLocation = if opts.keystore == "": joinPath(getHomeDir(), DEFAULT_KEYSTORE) else: opts.keystore.absolutePath
let group = if opts.group == "": "common" else:opts.group

if opts.changepass:
    let oldPass = readPasswordFromStdin("Old password: " )
    if oldPass == "":
        quit("Empty password provided: aborted")
    let kstore = keystoreLocation.readKeystore(oldPass)
    let newPass = readPasswordFromStdin("New password: " )
    if newPass == "":
        quit("Empty password provided: aborted")
    let newPass2 = readPasswordFromStdin("New password (again): " )
    if newPass != newPass2:
        quit("Password mismatch")
    if newPass == oldPass:
        quit("Password not changed")
    kstore.storeKeystore(keystoreLocation, newPass)
    quit(0)

let pass = opts.password
if pass=="": quit("No password provided, please see --help")

let keystore = keystoreLocation.readKeystore(pass)
if opts.add != "":
    let line = readPasswordFromStdin("Please input data for variable " & opts.add & " (group " & group & "): " )
    if line == "":
        quit("Unable to add empty value")
    let node =
        if keystore.hasKey(group):
            keystore[group]
        else:
            let n = newJObject()
            keystore.add(group, n)
            n
    node.add(opts.add, %line)
    keystore.storeKeystore(keystoreLocation, pass)

elif opts.delete != "":
    if not keystore.hasKey(group):
        quit("Unable to find group common")
    let node = keystore[group]
    node.delete(opts.delete)
    if node.len == 0:
        keystore.delete(group)
    keystore.storeKeystore(keystoreLocation, pass)

elif opts.list:
    echo "List of variables:"
    for group,groupNode in keystore:
        if opts.group == "" or opts.group == group:
            echo "  ", group, ":"
            for entry,value in groupNode:
                echo "    ", entry, "=", value.getStr

elif opts.export != "":
    for group,groupNode in keystore:
        if opts.group == "" or opts.group == group:
            for entry,value in groupNode:
                if opts.export == "fish":
                    echo "set -x -g ", entry, " ", value.getStr.quoteShell, ";"
                else:
                    echo "export ", entry,"=",value.getStr.quoteShell

elif opts.help:
    discard

else:
    quit("I don't know what to do, use the --help switch")
