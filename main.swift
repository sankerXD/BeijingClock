import AppKit
import Foundation
import ServiceManagement

// MARK: - App Preferences
class Preferences {
    static let shared = Preferences()
    
    private let defaults = UserDefaults.standard
    
    enum Key: String {
        case showDate = "showDate"
        case showWeekday = "showWeekday"
        case showSeconds = "showSeconds"
        case use24Hour = "use24Hour"
        case languageStyle = "languageStyle" // "chinese", "english"
        case prefixStyle = "prefixStyle" // "none", "flag", "text", "cst"
    }
    
    var showDate: Bool {
        get { defaults.object(forKey: Key.showDate.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showDate.rawValue) }
    }
    
    var showWeekday: Bool {
        get { defaults.object(forKey: Key.showWeekday.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showWeekday.rawValue) }
    }
    
    var showSeconds: Bool {
        get { defaults.object(forKey: Key.showSeconds.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.showSeconds.rawValue) }
    }
    
    var use24Hour: Bool {
        get { defaults.object(forKey: Key.use24Hour.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.use24Hour.rawValue) }
    }
    
    var languageStyle: String {
        get { defaults.string(forKey: Key.languageStyle.rawValue) ?? "chinese" }
        set { defaults.set(newValue, forKey: Key.languageStyle.rawValue) }
    }
    
    var prefixStyle: String {
        get { defaults.string(forKey: Key.prefixStyle.rawValue) ?? "none" }
        set { defaults.set(newValue, forKey: Key.prefixStyle.rawValue) }
    }
}

// MARK: - Launch at Login Helper
class LaunchAtLoginHelper {
    static let shared = LaunchAtLoginHelper()
    private let launchAgentIdentifier = "com.beijingclock.app"
    
    private var launchAgentPlistURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(launchAgentIdentifier).plist")
    }
    
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled || FileManager.default.fileExists(atPath: launchAgentPlistURL.path)
        } else {
            return FileManager.default.fileExists(atPath: launchAgentPlistURL.path)
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                try? FileManager.default.removeItem(at: launchAgentPlistURL)
                return
            } catch {
                // Fallback to LaunchAgent plist below
            }
        }
        
        let fm = FileManager.default
        if enabled {
            let appBundlePath = Bundle.main.bundlePath
            let executablePath = Bundle.main.executablePath ?? appBundlePath
            let plistContent: [String: Any] = [
                "Label": launchAgentIdentifier,
                "ProgramArguments": [executablePath],
                "RunAtLoad": true,
                "KeepAlive": false
            ]
            let launchAgentsDir = launchAgentPlistURL.deletingLastPathComponent()
            try? fm.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
            (plistContent as NSDictionary).write(to: launchAgentPlistURL, atomically: true)
        } else {
            try? fm.removeItem(at: launchAgentPlistURL)
        }
    }
}

// MARK: - Clock Manager
class ClockManager {
    static let shared = ClockManager()
    
    let beijingTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 8 * 3600)!
    
    var beijingCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = beijingTimeZone
        cal.locale = Locale(identifier: "zh_CN")
        cal.firstWeekday = 2 // Monday is 1st day of week
        return cal
    }
    
    func formattedTimeString(date: Date = Date()) -> String {
        let prefs = Preferences.shared
        let formatter = DateFormatter()
        formatter.timeZone = beijingTimeZone
        formatter.locale = (prefs.languageStyle == "english") ? Locale(identifier: "en_US_POSIX") : Locale(identifier: "zh_CN")
        
        var parts: [String] = []
        
        switch prefs.prefixStyle {
        case "flag":
            parts.append("🇨🇳")
        case "text":
            parts.append("北京")
        case "cst":
            parts.append("CST")
        default:
            break
        }
        
        if prefs.languageStyle == "english" {
            var datePatternComponents: [String] = []
            if prefs.showWeekday { datePatternComponents.append("EEE") }
            if prefs.showDate { datePatternComponents.append("MMM d") }
            
            let timePattern = prefs.use24Hour ? (prefs.showSeconds ? "HH:mm:ss" : "HH:mm") : (prefs.showSeconds ? "h:mm:ss a" : "h:mm a")
            
            if !datePatternComponents.isEmpty {
                formatter.dateFormat = "\(datePatternComponents.joined(separator: " ")) \(timePattern)"
            } else {
                formatter.dateFormat = timePattern
            }
            parts.append(formatter.string(from: date))
        } else {
            var datePatternComponents: [String] = []
            if prefs.showDate { datePatternComponents.append("M月d日") }
            if prefs.showWeekday { datePatternComponents.append("EEE") }
            
            let timePattern = prefs.use24Hour ? (prefs.showSeconds ? "HH:mm:ss" : "HH:mm") : (prefs.showSeconds ? "ah:mm:ss" : "ah:mm")
            
            if !datePatternComponents.isEmpty {
                formatter.dateFormat = "\(datePatternComponents.joined(separator: " ")) \(timePattern)"
            } else {
                formatter.dateFormat = timePattern
            }
            parts.append(formatter.string(from: date))
        }
        
        return parts.joined(separator: " ")
    }
    
    func detailedBeijingTimeString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = beijingTimeZone
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 EEEE HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func headerDateString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = beijingTimeZone
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: date)
    }
    
    func headerTimeString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = beijingTimeZone
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func diffDescription(date: Date = Date()) -> String {
        let localTZ = TimeZone.current
        let diffSeconds = beijingTimeZone.secondsFromGMT(for: date) - localTZ.secondsFromGMT(for: date)
        let diffHours = diffSeconds / 3600
        
        let localFormatter = DateFormatter()
        localFormatter.timeZone = localTZ
        localFormatter.dateFormat = "HH:mm"
        let localTimeStr = localFormatter.string(from: date)
        
        if diffHours == 0 {
            return "本机时间: \(localTimeStr) (与北京同区)"
        } else if diffHours > 0 {
            return "本机时间: \(localTimeStr) (比北京慢 \(diffHours)小时)"
        } else {
            return "本机时间: \(localTimeStr) (比北京快 \(-diffHours)小时)"
        }
    }
}

// MARK: - Mini Calendar View Controller
class CalendarViewController: NSViewController {
    private var displayedMonthDate: Date = Date()
    private var selectedDate: Date? = nil
    
    // UI Elements
    private let headerDateLabel = NSTextField(labelWithString: "")
    private let headerTimeLabel = NSTextField(labelWithString: "")
    private let copyButton = NSButton()
    private let diffLabel = NSTextField(labelWithString: "")
    
    private let monthTitleLabel = NSTextField(labelWithString: "")
    private let prevMonthButton = NSButton()
    private let nextMonthButton = NSButton()
    private let todayButton = NSButton()
    
    private let calendarGridView = NSView()
    private var dayButtons: [NSButton] = []
    
    private var secondTimer: Timer?
    
    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 375))
        container.wantsLayer = true
        self.view = container
        
        setupUI()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        displayedMonthDate = Date()
        selectedDate = nil
        updateHeader()
        renderCalendarGrid()
        startLiveTimer()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        secondTimer?.invalidate()
        secondTimer = nil
    }
    
    private func startLiveTimer() {
        secondTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, target: self, selector: #selector(onLiveTimerTick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        secondTimer = t
    }
    
    @objc private func onLiveTimerTick() {
        updateHeader()
    }
    
    private func setupUI() {
        let view = self.view
        
        // 1. Top Section: Header Container
        let headerBox = NSView(frame: NSRect(x: 14, y: 285, width: 252, height: 80))
        
        // Date Label
        headerDateLabel.frame = NSRect(x: 0, y: 56, width: 190, height: 22)
        headerDateLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        headerDateLabel.textColor = .labelColor
        headerBox.addSubview(headerDateLabel)
        
        // Copy Button
        copyButton.frame = NSRect(x: 192, y: 55, width: 60, height: 22)
        copyButton.title = "复制"
        copyButton.bezelStyle = .inline
        copyButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        copyButton.target = self
        copyButton.action = #selector(onCopyClicked)
        headerBox.addSubview(copyButton)
        
        // Time Label (Live)
        headerTimeLabel.frame = NSRect(x: 0, y: 26, width: 252, height: 28)
        headerTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 24, weight: .heavy)
        headerTimeLabel.textColor = .systemBlue
        headerBox.addSubview(headerTimeLabel)
        
        // Diff Label
        diffLabel.frame = NSRect(x: 0, y: 6, width: 252, height: 16)
        diffLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        diffLabel.textColor = .secondaryLabelColor
        headerBox.addSubview(diffLabel)
        
        view.addSubview(headerBox)
        
        // Top Separator
        let sep1 = NSBox(frame: NSRect(x: 14, y: 275, width: 252, height: 1))
        sep1.boxType = .separator
        view.addSubview(sep1)
        
        // 2. Month Navigation Bar
        let navBar = NSView(frame: NSRect(x: 14, y: 240, width: 252, height: 30))
        
        monthTitleLabel.frame = NSRect(x: 0, y: 4, width: 130, height: 22)
        monthTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        monthTitleLabel.textColor = .labelColor
        navBar.addSubview(monthTitleLabel)
        
        todayButton.frame = NSRect(x: 140, y: 3, width: 44, height: 22)
        todayButton.title = "今天"
        todayButton.bezelStyle = .roundRect
        todayButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        todayButton.target = self
        todayButton.action = #selector(onTodayClicked)
        navBar.addSubview(todayButton)
        
        prevMonthButton.frame = NSRect(x: 190, y: 3, width: 26, height: 22)
        prevMonthButton.title = "‹"
        prevMonthButton.bezelStyle = .roundRect
        prevMonthButton.font = NSFont.boldSystemFont(ofSize: 15)
        prevMonthButton.target = self
        prevMonthButton.action = #selector(onPrevMonthClicked)
        navBar.addSubview(prevMonthButton)
        
        nextMonthButton.frame = NSRect(x: 222, y: 3, width: 26, height: 22)
        nextMonthButton.title = "›"
        nextMonthButton.bezelStyle = .roundRect
        nextMonthButton.font = NSFont.boldSystemFont(ofSize: 15)
        nextMonthButton.target = self
        nextMonthButton.action = #selector(onNextMonthClicked)
        navBar.addSubview(nextMonthButton)
        
        view.addSubview(navBar)
        
        // 3. Weekday Header (一 二 三 四 五 六 日)
        let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
        let cellWidth: CGFloat = 36.0
        let cellHeight: CGFloat = 26.0
        
        let weekHeaderView = NSView(frame: NSRect(x: 14, y: 215, width: 252, height: 20))
        for (i, day) in weekDays.enumerated() {
            let lbl = NSTextField(labelWithString: day)
            lbl.frame = NSRect(x: CGFloat(i) * cellWidth, y: 0, width: cellWidth, height: 18)
            lbl.alignment = .center
            lbl.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            lbl.textColor = (i >= 5) ? .systemRed.withAlphaComponent(0.8) : .secondaryLabelColor
            weekHeaderView.addSubview(lbl)
        }
        view.addSubview(weekHeaderView)
        
        // 4. Calendar Matrix Grid (6 rows x 7 cols = 42 cells)
        calendarGridView.frame = NSRect(x: 14, y: 48, width: 252, height: 6 * cellHeight)
        view.addSubview(calendarGridView)
        
        for row in 0..<6 {
            for col in 0..<7 {
                let btn = NSButton(frame: NSRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(5 - row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                ))
                btn.isBordered = false
                btn.wantsLayer = true
                btn.layer?.cornerRadius = 6
                btn.target = self
                btn.action = #selector(onDateCellClicked(_:))
                btn.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
                btn.alignment = .center
                calendarGridView.addSubview(btn)
                dayButtons.append(btn)
            }
        }
        
        // Bottom Separator
        let sep2 = NSBox(frame: NSRect(x: 14, y: 40, width: 252, height: 1))
        sep2.boxType = .separator
        view.addSubview(sep2)
        
        // 5. Bottom Toolbar
        let settingsBtn = NSButton(frame: NSRect(x: 14, y: 8, width: 75, height: 24))
        settingsBtn.title = "⚙️ 设置"
        settingsBtn.bezelStyle = .inline
        settingsBtn.font = NSFont.systemFont(ofSize: 11)
        settingsBtn.target = self
        settingsBtn.action = #selector(onSettingsClicked(_:))
        view.addSubview(settingsBtn)
        
        let quitBtn = NSButton(frame: NSRect(x: 195, y: 8, width: 70, height: 24))
        quitBtn.title = "⏻ 退出"
        quitBtn.bezelStyle = .inline
        quitBtn.font = NSFont.systemFont(ofSize: 11)
        quitBtn.target = self
        quitBtn.action = #selector(onQuitClicked)
        view.addSubview(quitBtn)
    }
    
    private func updateHeader() {
        let now = Date()
        headerDateLabel.stringValue = ClockManager.shared.headerDateString(date: now)
        headerTimeLabel.stringValue = ClockManager.shared.headerTimeString(date: now)
        diffLabel.stringValue = ClockManager.shared.diffDescription(date: now)
    }
    
    @objc private func onCopyClicked() {
        let fullStr = ClockManager.shared.detailedBeijingTimeString() + " (UTC+8)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullStr, forType: .string)
        
        copyButton.title = "✓ 已复制"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.title = "复制"
        }
    }
    
    @objc private func onTodayClicked() {
        displayedMonthDate = Date()
        selectedDate = nil
        renderCalendarGrid()
    }
    
    @objc private func onPrevMonthClicked() {
        let cal = ClockManager.shared.beijingCalendar
        if let prev = cal.date(byAdding: .month, value: -1, to: displayedMonthDate) {
            displayedMonthDate = prev
            renderCalendarGrid()
        }
    }
    
    @objc private func onNextMonthClicked() {
        let cal = ClockManager.shared.beijingCalendar
        if let next = cal.date(byAdding: .month, value: 1, to: displayedMonthDate) {
            displayedMonthDate = next
            renderCalendarGrid()
        }
    }
    
    @objc private func onDateCellClicked(_ sender: NSButton) {
        guard let date = sender.identifier.flatMap({ ISO8601DateFormatter().date(from: $0.rawValue) }) else { return }
        selectedDate = date
        renderCalendarGrid()
    }
    
    @objc private func onSettingsClicked(_ sender: NSButton) {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            delegate.showSettingsMenu(positioningView: sender)
        }
    }
    
    @objc private func onQuitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Calendar Matrix Calculation
    private func renderCalendarGrid() {
        let cal = ClockManager.shared.beijingCalendar
        let now = Date()
        
        let monthFormatter = DateFormatter()
        monthFormatter.timeZone = cal.timeZone
        monthFormatter.locale = Locale(identifier: "zh_CN")
        monthFormatter.dateFormat = "yyyy年 M月"
        monthTitleLabel.stringValue = monthFormatter.string(from: displayedMonthDate)
        
        let comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        guard let startOfMonth = cal.date(from: comps),
              let monthRange = cal.range(of: .day, in: .month, for: startOfMonth) else { return }
        
        let daysInCurrentMonth = monthRange.count
        let firstWeekdayComponent = cal.component(.weekday, from: startOfMonth)
        let firstDayOffset = (firstWeekdayComponent - cal.firstWeekday + 7) % 7
        
        let prevMonthDate = cal.date(byAdding: .month, value: -1, to: startOfMonth)!
        let prevMonthDays = cal.range(of: .day, in: .month, for: prevMonthDate)!.count
        
        let isoFormatter = ISO8601DateFormatter()
        
        for i in 0..<42 {
            let btn = dayButtons[i]
            let dayNumber: Int
            let isCurrentMonth: Bool
            let cellDate: Date
            
            if i < firstDayOffset {
                dayNumber = prevMonthDays - (firstDayOffset - 1 - i)
                isCurrentMonth = false
                var c = cal.dateComponents([.year, .month], from: prevMonthDate)
                c.day = dayNumber
                cellDate = cal.date(from: c) ?? Date()
            } else if i < firstDayOffset + daysInCurrentMonth {
                dayNumber = i - firstDayOffset + 1
                isCurrentMonth = true
                var c = comps
                c.day = dayNumber
                cellDate = cal.date(from: c) ?? Date()
            } else {
                dayNumber = i - (firstDayOffset + daysInCurrentMonth) + 1
                isCurrentMonth = false
                let nextMonthDate = cal.date(byAdding: .month, value: 1, to: startOfMonth)!
                var c = cal.dateComponents([.year, .month], from: nextMonthDate)
                c.day = dayNumber
                cellDate = cal.date(from: c) ?? Date()
            }
            
            btn.identifier = NSUserInterfaceItemIdentifier(isoFormatter.string(from: cellDate))
            btn.title = "\(dayNumber)"
            
            let isToday = cal.isDate(cellDate, inSameDayAs: now)
            let isSelected = (selectedDate != nil && cal.isDate(cellDate, inSameDayAs: selectedDate!))
            
            if isToday {
                btn.layer?.backgroundColor = NSColor.systemBlue.cgColor
                btn.attributedTitle = NSAttributedString(
                    string: "\(dayNumber)",
                    attributes: [
                        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
                        .foregroundColor: NSColor.white
                    ]
                )
            } else if isSelected {
                btn.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
                btn.attributedTitle = NSAttributedString(
                    string: "\(dayNumber)",
                    attributes: [
                        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
                        .foregroundColor: NSColor.labelColor
                    ]
                )
            } else {
                btn.layer?.backgroundColor = NSColor.clear.cgColor
                let textColor: NSColor
                if !isCurrentMonth {
                    textColor = NSColor.quaternaryLabelColor
                } else {
                    let col = i % 7
                    textColor = (col >= 5) ? NSColor.systemRed.withAlphaComponent(0.85) : NSColor.labelColor
                }
                btn.attributedTitle = NSAttributedString(
                    string: "\(dayNumber)",
                    attributes: [
                        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: textColor
                    ]
                )
            }
        }
    }
}

// MARK: - Application Delegate
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var popover: NSPopover!
    private var calendarVC: CalendarViewController!
    private var settingsMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupStatusItem()
        setupSettingsMenu()
        startTimer()
        updateDisplay()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        calendarVC = CalendarViewController()
        popover.contentViewController = calendarVC
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(onStatusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
    }
    
    @objc private func onStatusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showSettingsMenu(positioningView: sender)
        } else {
            togglePopover(sender: sender)
        }
    }
    
    private func togglePopover(sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func showSettingsMenu(positioningView: NSView) {
        buildSettingsMenu()
        settingsMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: positioningView.bounds.height + 4), in: positioningView)
    }
    
    private func setupSettingsMenu() {
        settingsMenu = NSMenu()
        settingsMenu.delegate = self
    }
    
    private func startTimer() {
        timer?.invalidate()
        let currentTimer = Timer(fireAt: Date(), interval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(currentTimer, forMode: .common)
        self.timer = currentTimer
    }
    
    @objc private func timerFired() {
        updateDisplay()
    }
    
    func updateDisplay() {
        guard let button = statusItem?.button else { return }
        let timeString = ClockManager.shared.formattedTimeString()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .foregroundColor: NSColor.controlTextColor
        ]
        button.attributedTitle = NSAttributedString(string: timeString, attributes: attributes)
    }
    
    // MARK: - Settings Menu
    private func buildSettingsMenu() {
        settingsMenu.removeAllItems()
        
        let prefs = Preferences.shared
        
        let titleItem = NSMenuItem(title: "北京时钟设置", action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(string: "北京时钟设置", attributes: [.font: NSFont.boldSystemFont(ofSize: 13)])
        settingsMenu.addItem(titleItem)
        settingsMenu.addItem(NSMenuItem.separator())
        
        let showDateItem = NSMenuItem(title: "显示日期", action: #selector(toggleShowDate), keyEquivalent: "")
        showDateItem.target = self
        showDateItem.state = prefs.showDate ? .on : .off
        settingsMenu.addItem(showDateItem)
        
        let showWeekdayItem = NSMenuItem(title: "显示星期", action: #selector(toggleShowWeekday), keyEquivalent: "")
        showWeekdayItem.target = self
        showWeekdayItem.state = prefs.showWeekday ? .on : .off
        settingsMenu.addItem(showWeekdayItem)
        
        let showSecondsItem = NSMenuItem(title: "显示秒数", action: #selector(toggleShowSeconds), keyEquivalent: "")
        showSecondsItem.target = self
        showSecondsItem.state = prefs.showSeconds ? .on : .off
        settingsMenu.addItem(showSecondsItem)
        
        let use24HourItem = NSMenuItem(title: "使用 24 小时制", action: #selector(toggle24Hour), keyEquivalent: "")
        use24HourItem.target = self
        use24HourItem.state = prefs.use24Hour ? .on : .off
        settingsMenu.addItem(use24HourItem)
        
        let styleMenu = NSMenu()
        let chineseStyle = NSMenuItem(title: "中文风格 (例: 8月26日 周三 17:24)", action: #selector(setChineseStyle), keyEquivalent: "")
        chineseStyle.target = self
        chineseStyle.state = (prefs.languageStyle == "chinese") ? .on : .off
        styleMenu.addItem(chineseStyle)
        
        let englishStyle = NSMenuItem(title: "英文风格 (例: Wed Aug 26 5:24 PM)", action: #selector(setEnglishStyle), keyEquivalent: "")
        englishStyle.target = self
        englishStyle.state = (prefs.languageStyle == "english") ? .on : .off
        styleMenu.addItem(englishStyle)
        
        let styleSubmenuItem = NSMenuItem(title: "语言与日期样式", action: nil, keyEquivalent: "")
        styleSubmenuItem.submenu = styleMenu
        settingsMenu.addItem(styleSubmenuItem)
        
        let prefixMenu = NSMenu()
        let noPrefix = NSMenuItem(title: "无前缀 (推荐)", action: #selector(setPrefixNone), keyEquivalent: "")
        noPrefix.target = self
        noPrefix.state = (prefs.prefixStyle == "none") ? .on : .off
        prefixMenu.addItem(noPrefix)
        
        let flagPrefix = NSMenuItem(title: "🇨🇳 国旗图标", action: #selector(setPrefixFlag), keyEquivalent: "")
        flagPrefix.target = self
        flagPrefix.state = (prefs.prefixStyle == "flag") ? .on : .off
        prefixMenu.addItem(flagPrefix)
        
        let textPrefix = NSMenuItem(title: "“北京” 文字", action: #selector(setPrefixText), keyEquivalent: "")
        textPrefix.target = self
        textPrefix.state = (prefs.prefixStyle == "text") ? .on : .off
        prefixMenu.addItem(textPrefix)
        
        let cstPrefix = NSMenuItem(title: "“CST” 英文缩写", action: #selector(setPrefixCST), keyEquivalent: "")
        cstPrefix.target = self
        cstPrefix.state = (prefs.prefixStyle == "cst") ? .on : .off
        prefixMenu.addItem(cstPrefix)
        
        let prefixSubmenuItem = NSMenuItem(title: "前缀标识", action: nil, keyEquivalent: "")
        prefixSubmenuItem.submenu = prefixMenu
        settingsMenu.addItem(prefixSubmenuItem)
        
        settingsMenu.addItem(NSMenuItem.separator())
        
        let launchItem = NSMenuItem(title: "开机自启动", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LaunchAtLoginHelper.shared.isEnabled ? .on : .off
        settingsMenu.addItem(launchItem)
        
        let quitItem = NSMenuItem(title: "退出北京时钟", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        settingsMenu.addItem(quitItem)
    }
    
    // MARK: - Actions
    @objc private func toggleShowDate() {
        Preferences.shared.showDate.toggle()
        updateDisplay()
    }
    
    @objc private func toggleShowWeekday() {
        Preferences.shared.showWeekday.toggle()
        updateDisplay()
    }
    
    @objc private func toggleShowSeconds() {
        Preferences.shared.showSeconds.toggle()
        updateDisplay()
    }
    
    @objc private func toggle24Hour() {
        Preferences.shared.use24Hour.toggle()
        updateDisplay()
    }
    
    @objc private func setChineseStyle() {
        Preferences.shared.languageStyle = "chinese"
        updateDisplay()
    }
    
    @objc private func setEnglishStyle() {
        Preferences.shared.languageStyle = "english"
        updateDisplay()
    }
    
    @objc private func setPrefixNone() {
        Preferences.shared.prefixStyle = "none"
        updateDisplay()
    }
    
    @objc private func setPrefixFlag() {
        Preferences.shared.prefixStyle = "flag"
        updateDisplay()
    }
    
    @objc private func setPrefixText() {
        Preferences.shared.prefixStyle = "text"
        updateDisplay()
    }
    
    @objc private func setPrefixCST() {
        Preferences.shared.prefixStyle = "cst"
        updateDisplay()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let current = LaunchAtLoginHelper.shared.isEnabled
        LaunchAtLoginHelper.shared.setEnabled(!current)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Application Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
