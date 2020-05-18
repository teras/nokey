import osproc, streams

proc myExec*(command: seq[string], inputData=""): tuple[output: string, exitCode: int] =
    var p = startProcess(command[0], args=command[1..^1], options = {poStdErrToStdOut, poUsePath})
    var outp = outputStream(p)
    p.inputStream.write inputData
    p.inputStream.close
    
    result = ("", -1)
    var line = newStringOfCap(120).TaintedString
    while true:
        if outp.readLine(line):
            result[0].add(line.string)
            result[0].add("\n")
        else:
            result[1] = peekExitCode(p)
            if result[1] != -1: break
    close(p)