import osproc, streams

proc myExec*(command: seq[string], inputData=""): tuple[output: string, exitCode: int] =
    var p = startProcess(command[0], args=command[1..^1], options = {poStdErrToStdOut, poUsePath})
    p.inputStream.write inputData
    p.inputStream.close
    result = (p.outputStream.readAll, p.peekExitCode)
    p.close
