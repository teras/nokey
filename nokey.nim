import os, argparse, terminal, json, re
import enc

const DEFAULT_KEYSTORE = ".ssh/nokey"
const ENV_VARIABLE = "NOKEY_PASSWORD"

const p = newParser("nokey"):
    help("Store and retrieve passwords securely using an openssl backend")
    option("-k", "--keystore", help="Where to store the encrypted file, defaults to ~/" & DEFAULT_KEYSTORE)
    option("-p", "--password", env=ENV_VARIABLE, help="The password of this keychan.")
    option("-g", "--group", help="Perform action on named group. Defaults to 'common'")
    option("-a", "--add", help="Store variable ADD")
    option("-d", "--delete", help="Delete variable DELETE")
    option("-m", "--move", help="Move variable MOVE from current group to GROUP")
    option("-r", "--rename", help="Rename variable MOVE from current group to GROUP")
    option("--to", help="When renaming variables, the new name of the variable")
    flag("--bash", help="Export commands for bash shell")
    flag("--fish", help="Export commands for fish shell")
    flag("-c", "--changepass", help="Change the current keystore password")
    flag("-l", "--list", help="Show all variables")
let opts = p.parse(commandLineParams())

let keystoreLocation = if opts.keystore == "": joinPath(getHomeDir(), DEFAULT_KEYSTORE) else: opts.keystore.absolutePath
let group = if opts.group == "": "common" else:opts.group.toLowerAscii

if opts.changepass:
    let oldPass = readPasswordFromStdin("Old password: " )
    if oldPass == "":
        quit("Empty password provided: aborted")
    let kstore = keystoreLocation.readKeystore(oldPass)
    let newPass = readPasswordFromStdin("New password: ").strip
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

proc delete(variable:string, failOnError=true):(string,string) = 
    for groupName,groupNode in keystore:
        for key,value in groupNode:
            if key == variable:
                groupNode.delete(key)
                if groupNode.len == 0:
                    keystore.delete(groupName)
                return (groupName,value.getStr)
    if failOnError:
        quit("Unable to locate variable " & variable)
    return ("", "")

proc add(variable:string, value:string, newgroup="") =
    let (oldgroup,_) = delete(variable, false)
    let cgroup = if newgroup == "": (if oldgroup != "" and opts.group == "": oldgroup else: group) else: newgroup
    var value = value
    if not variable.match(re"[A-Z][A-Z0-9_]*"):
        quit("Invalid variable name: " & variable)
    if value == "":
        value = readPasswordFromStdin("Please input data for variable " & variable & " (group " & cgroup & "): " ).strip
    if value == "":
        quit("Unable to add empty value")
    let node =
        if keystore.hasKey(cgroup):
            keystore[cgroup]
        else:
            let n = newJObject()
            keystore.add(cgroup, n)
            n
    node.add(variable, %value)

if opts.rename != "":
    if opts.to == "":
        quit("--to parameter is required with the --rename parameter")
    if opts.group != "":
        quit("--group parameter not compatible with the --rename parameter")
    let (oldgroup,value) = delete(opts.rename.toUpperAscii)
    add(opts.to.toUpperAscii, value, oldgroup)
    keystore.storeKeystore(keystoreLocation, pass)
elif opts.to != "":
    quit("--to parameter can only be used together with --rename parameter")
elif opts.add != "":
    add(opts.add.toUpperAscii, "")
    keystore.storeKeystore(keystoreLocation, pass)
elif opts.delete != "":
    discard delete(opts.delete.toUpperAscii)
    keystore.storeKeystore(keystoreLocation, pass)
elif opts.move != "":
    let (_,value) = delete(opts.move.toUpperAscii)
    add(opts.move.toUpperAscii, value)
    keystore.storeKeystore(keystoreLocation, pass)
elif opts.list:
    echo "List of variables:"
    for group,groupNode in keystore:
        if opts.group == "" or opts.group == group:
            echo "  ", group, ":"
            for entry,value in groupNode:
                echo "    ", entry, "=", value.getStr
elif opts.bash or opts.fish:
    for group,groupNode in keystore:
        if opts.group == "" or opts.group == group:
            for entry,value in groupNode:
                if opts.fish:
                    echo "set -x -g ", entry, " ", value.getStr.quoteShell, ";"
                else:
                    echo "export ", entry,"=",value.getStr.quoteShell
else:
    stdout.write p.help
