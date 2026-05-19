import Foundation

protocol ShellRunner {
    func run(_ executablePath: String, arguments: [String]) throws -> String
}

enum ShellError: Error {
    case nonZeroExit(Int32)
    case noOutput
}

final class DefaultShellRunner: ShellRunner {
    func run(_ executablePath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        if env["PATH"] == nil {
            env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
        }
        process.environment = env

        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw ShellError.nonZeroExit(process.terminationStatus)
        }
        guard let output = String(data: data, encoding: .utf8) else {
            throw ShellError.noOutput
        }
        return output
    }
}
