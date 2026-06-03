import Foundation

class SleepMonitor {
    private static let assertionPattern = try! NSRegularExpression(
        pattern: #"pid\s+(\d+)\(([^)]+)\):\s+\[0x[0-9a-f]+\]\s+(\d{2}:\d{2}:\d{2})\s+(Prevent\w+|NoIdleSleepAssertion)\s+named:\s+"([^"]+)""#
    )

    private static let relevantAssertions: Set<String> = [
        "PreventUserIdleDisplaySleep",
        "PreventUserIdleSystemSleep",
        "PreventSystemSleep",
        "NoIdleSleepAssertion"
    ]

    private static let systemProcesses: Set<String> = [
        "powerd", "WindowServer", "timed", "bluetoothd", "sharingd", "useractivityd"
    ]

    func checkBlockingProcesses() -> [BlockingProcess] {
        let output = runPmset()
        return parse(output)
    }

    private func runPmset() -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "assertions"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func parse(_ output: String) -> [BlockingProcess] {
        let range = NSRange(output.startIndex..., in: output)
        let matches = Self.assertionPattern.matches(in: output, range: range)

        return matches.compactMap { match in
            guard match.numberOfRanges == 6,
                  let pidRange = Range(match.range(at: 1), in: output),
                  let nameRange = Range(match.range(at: 2), in: output),
                  let durationRange = Range(match.range(at: 3), in: output),
                  let typeRange = Range(match.range(at: 4), in: output),
                  let assertionNameRange = Range(match.range(at: 5), in: output)
            else { return nil }

            let processName = String(output[nameRange])
            let assertionType = String(output[typeRange])

            guard Self.relevantAssertions.contains(assertionType),
                  !Self.systemProcesses.contains(processName)
            else { return nil }

            guard let pid = Int32(output[pidRange]) else { return nil }

            let parentName = (processName == "caffeinate") ? Self.parentProcessName(of: pid) : nil

            return BlockingProcess(
                id: pid,
                name: processName,
                assertionType: assertionType,
                assertionName: String(output[assertionNameRange]),
                duration: String(output[durationRange]),
                parentName: parentName
            )
        }
    }

    private static func parentProcessName(of pid: Int32) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "ppid="]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let ppidStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let ppid = Int32(ppidStr), ppid > 1
        else { return nil }

        let nameProcess = Process()
        let namePipe = Pipe()
        nameProcess.executableURL = URL(fileURLWithPath: "/bin/ps")
        nameProcess.arguments = ["-p", "\(ppid)", "-o", "comm="]
        nameProcess.standardOutput = namePipe
        nameProcess.standardError = FileHandle.nullDevice

        do {
            try nameProcess.run()
            nameProcess.waitUntilExit()
        } catch { return nil }

        let nameData = namePipe.fileHandleForReading.readDataToEndOfFile()
        guard let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty
        else { return nil }

        return URL(fileURLWithPath: name).lastPathComponent
    }

    func terminateProcess(_ pid: Int32) -> Bool {
        kill(pid, SIGTERM) == 0
    }

    func forceTerminateProcess(_ pid: Int32) -> Bool {
        kill(pid, SIGKILL) == 0
    }
}
