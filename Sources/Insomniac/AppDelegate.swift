import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let monitor = SleepMonitor()
    private var timer: Timer?
    private var blinkTimer: Timer?
    private var blinkVisible = true
    private var blockingProcesses: [BlockingProcess] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(hasBlockers: false)
        refreshStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    private func updateIcon(hasBlockers: Bool) {
        if hasBlockers {
            startBlinking()
        } else {
            stopBlinking()
            setIcon("moon.zzz")
        }
    }

    private func setIcon(_ symbolName: String) {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Insomniac")
        image?.isTemplate = true
        button.image = image
        button.alphaValue = 1.0
    }

    private func startBlinking() {
        setIcon("exclamationmark.triangle.fill")
        guard blinkTimer == nil else { return }
        blinkVisible = true
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self, let button = self.statusItem.button else { return }
            self.blinkVisible.toggle()
            button.alphaValue = self.blinkVisible ? 1.0 : 0.2
        }
    }

    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        blinkVisible = true
    }

    private func refreshStatus() {
        blockingProcesses = monitor.checkBlockingProcesses()
        updateIcon(hasBlockers: !blockingProcesses.isEmpty)
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        if blockingProcesses.isEmpty {
            let item = NSMenuItem(title: "No processes blocking sleep", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            let header = NSMenuItem(
                title: "\(blockingProcesses.count) process(es) blocking sleep",
                action: nil,
                keyEquivalent: ""
            )
            header.isEnabled = false
            menu.addItem(header)
            menu.addItem(NSMenuItem.separator())

            for process in blockingProcesses {
                let processItem = NSMenuItem(title: process.displayName, action: nil, keyEquivalent: "")
                processItem.isEnabled = false
                menu.addItem(processItem)

                let detailItem = NSMenuItem(title: "  \(process.description)", action: nil, keyEquivalent: "")
                detailItem.isEnabled = false
                menu.addItem(detailItem)

                let terminateItem = NSMenuItem(
                    title: "  Terminate",
                    action: #selector(terminateProcess(_:)),
                    keyEquivalent: ""
                )
                terminateItem.target = self
                terminateItem.representedObject = process.id
                menu.addItem(terminateItem)

                let forceTerminateItem = NSMenuItem(
                    title: "  Force Terminate",
                    action: #selector(forceTerminateProcess(_:)),
                    keyEquivalent: ""
                )
                forceTerminateItem.target = self
                forceTerminateItem.representedObject = process.id
                menu.addItem(forceTerminateItem)

                menu.addItem(NSMenuItem.separator())
            }
        }

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Insomniac", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func terminateProcess(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int32 else { return }
        if monitor.terminateProcess(pid) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.refreshStatus()
            }
        }
    }

    @objc private func forceTerminateProcess(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int32 else { return }
        if monitor.forceTerminateProcess(pid) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.refreshStatus()
            }
        }
    }

    @objc private func refreshClicked() {
        refreshStatus()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
