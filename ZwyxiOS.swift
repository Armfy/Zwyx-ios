import SwiftUI
import Foundation
import CoreLocation
import MapKit

@main
struct ZwyxiOSApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}

struct ContentView: View {
    @StateObject private var systemMonitor = SystemMonitor()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(systemMonitor: systemMonitor)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            ProcessesView(systemMonitor: systemMonitor)
                .tabItem {
                    Label("Processes", systemImage: "list.bullet")
                }
                .tag(1)
            
            NetworkView()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(themeManager.currentTheme.accentColor)
        .onAppear {
            systemMonitor.startMonitoring()
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // System Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "CPU",
                            value: String(format: "%.1f%%", systemMonitor.cpuUsage),
                            icon: "cpu",
                            color: .blue,
                            theme: themeManager.currentTheme
                        )
                        
                        StatCard(
                            title: "RAM",
                            value: String(format: "%.1f%%", systemMonitor.ramUsage),
                            icon: "memorychip",
                            color: .green,
                            theme: themeManager.currentTheme
                        )
                        
                        StatCard(
                            title: "Disk",
                            value: String(format: "%.1f%%", systemMonitor.diskUsage),
                            icon: "internaldrive",
                            color: .orange,
                            theme: themeManager.currentTheme
                        )
                        
                        StatCard(
                            title: "Battery",
                            value: String(format: "%.0f%%", systemMonitor.batteryLevel),
                            icon: systemMonitor.batteryIcon,
                            color: systemMonitor.isCharging ? .green : .red,
                            theme: themeManager.currentTheme
                        )
                    }
                    .padding(.horizontal)
                    
                    // CPU Chart
                    ChartCard(
                        title: "CPU Usage",
                        data: systemMonitor.cpuHistory,
                        color: .blue,
                        theme: themeManager.currentTheme
                    )
                    .padding(.horizontal)
                    
                    // RAM Chart
                    ChartCard(
                        title: "RAM Usage",
                        data: systemMonitor.ramHistory,
                        color: .green,
                        theme: themeManager.currentTheme
                    )
                    .padding(.horizontal)
                    
                    // Device Info
                    DeviceInfoCard(systemMonitor: systemMonitor, theme: themeManager.currentTheme)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("System Monitor")
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}

// MARK: - Processes View
struct ProcessesView: View {
    @ObservedObject var systemMonitor: SystemMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var sortBy: ProcessSortOption = .cpu
    
    var filteredProcesses: [AppProcessInfo] {
        var processes = systemMonitor.topProcesses
        
        if !searchText.isEmpty {
            processes = processes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortBy {
        case .cpu:
            processes.sort { $0.cpuUsage > $1.cpuUsage }
        case .memory:
            processes.sort { $0.memoryUsage > $1.memoryUsage }
        case .name:
            processes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .gpu:
            processes.sort { $0.gpuUsage > $1.gpuUsage }
        }
        
        return processes
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Sort
                VStack(spacing: 12) {
                    TextField("Search processes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Picker("Sort by", selection: $sortBy) {
                        Text("CPU").tag(ProcessSortOption.cpu)
                        Text("Memory").tag(ProcessSortOption.memory)
                        Text("Name").tag(ProcessSortOption.name)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(themeManager.currentTheme.cardBackground)
                
                // Process List
                List(filteredProcesses) { process in
                    ProcessRowiOS(process: process, theme: themeManager.currentTheme)
                        .listRowBackground(themeManager.currentTheme.cardBackground)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Processes")
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}

// MARK: - Network View
struct NetworkView: View {
    @StateObject private var speedTestManager = SpeedTestManager()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Speed Gauges
                    VStack(spacing: 20) {
                        SpeedGauge(
                            title: "Download",
                            value: speedTestManager.downloadSpeed,
                            unit: "Mbps",
                            icon: "arrow.down.circle.fill",
                            color: .blue,
                            maxValue: 1000,
                            theme: themeManager.currentTheme
                        )
                        
                        SpeedGauge(
                            title: "Upload",
                            value: speedTestManager.uploadSpeed,
                            unit: "Mbps",
                            icon: "arrow.up.circle.fill",
                            color: .purple,
                            maxValue: 500,
                            theme: themeManager.currentTheme
                        )
                        
                        SpeedGauge(
                            title: "Ping",
                            value: speedTestManager.ping,
                            unit: "ms",
                            icon: "antenna.radiowaves.left.and.right",
                            color: .green,
                            maxValue: 200,
                            theme: themeManager.currentTheme
                        )
                    }
                    .padding()
                    
                    // Status
                    VStack(spacing: 8) {
                        Text(speedTestManager.currentStatus)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        
                        if speedTestManager.isRunning {
                            ProgressView(value: speedTestManager.progress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    // Test Button
                    Button(action: {
                        if speedTestManager.isRunning {
                            speedTestManager.cancelTest()
                        } else {
                            speedTestManager.runSpeedTest()
                        }
                    }) {
                        HStack {
                            Image(systemName: speedTestManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            Text(speedTestManager.isRunning ? "Cancel Test" : "Start Speed Test")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: speedTestManager.isRunning ? [.red, .orange] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // History
                    if !speedTestManager.testHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test History")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(speedTestManager.testHistory.prefix(5)) { result in
                                SpeedTestHistoryRowiOS(result: result, theme: themeManager.currentTheme)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Network")
            .background(themeManager.currentTheme.backgroundColor)
        }
        .onAppear {
            speedTestManager.locationProvider.requestAuthorizationIfNeeded()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: ThemeType = .dark
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Dark").tag(ThemeType.dark)
                        Text("Light").tag(ThemeType.light)
                        Text("AMOLED").tag(ThemeType.amoled)
                    }
                    .onChange(of: selectedTheme) { newValue in
                        themeManager.setTheme(newValue)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.10.31")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("System Info")) {
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(UIDevice.current.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Component Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

struct ChartCard: View {
    let title: String
    let data: [Double]
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            LineChart(data: data, color: color)
                .frame(height: 120)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

struct LineChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let maxValue = data.max() ?? 100
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                let stepY = geometry.size.height / CGFloat(maxValue)
                
                path.move(to: CGPoint(x: 0, y: geometry.size.height - CGFloat(data[0]) * stepY))
                
                for index in 1..<data.count {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - CGFloat(data[index]) * stepY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
}

struct ProcessRowiOS: View {
    let process: AppProcessInfo
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(process.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("PID: \(process.pid)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(formatBytes(process.memoryUsage))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatBytes(_ bytes: Double) -> String {
        let mb = bytes / 1024 / 1024
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.1f GB", mb / 1024)
        }
    }
}

struct SpeedGauge: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    let maxValue: Double
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(theme.borderColor, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                    
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
    }
}

struct SpeedTestHistoryRowiOS: View {
    let result: SpeedTestResult
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(result.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            // Metrics line
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Text(String(format: "%.1f Mbps", result.downloadSpeed))
                        .font(.caption)
                        .foregroundColor(theme.textPrimary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.purple)
                    Text(String(format: "%.1f Mbps", result.uploadSpeed))
                        .font(.caption)
                        .foregroundColor(theme.textPrimary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                    Text(String(format: "%.0f ms", result.ping))
                        .font(.caption)
                        .foregroundColor(theme.textPrimary)
                }
            }
            
            // IP line
            HStack(spacing: 6) {
                Image(systemName: "ipod") // Not a literal IP icon; closest SF Symbol is "network"
                    .foregroundColor(.orange)
                Text("IP: \(result.ipAddress.isEmpty ? "Unknown" : result.ipAddress)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Spacer()
            }
            
            // Map
            if let mapRegion = result.mapRegion {
                Map(coordinateRegion: .constant(mapRegion), interactionModes: [], annotationItems: [result]) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .frame(height: 140)
                .cornerRadius(10)
            } else {
                Text("Location unavailable")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Device Info Card

struct DeviceInfoCard: View {
    @ObservedObject var systemMonitor: SystemMonitor
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            InfoRow(label: "Device", value: UIDevice.current.name, theme: theme)
            InfoRow(label: "Model", value: UIDevice.current.model, theme: theme)
            InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion, theme: theme)
            InfoRow(label: "RAM", value: String(format: "%.1f / %.1f GB", systemMonitor.ramUsedGB, systemMonitor.ramTotalGB), theme: theme)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let theme: AppTheme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline  )
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)
        }
    }
}

// MARK: - Data Models

struct AppProcessInfo: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let cpuUsage: Double
    let memoryUsage: Double
    let gpuUsage: Double
}

enum ProcessSortOption {
    case cpu, memory, name, gpu
}

struct SpeedTestResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let downloadSpeed: Double
    let uploadSpeed: Double
    let ping: Double
    let server: String
    
    // New fields
    let ipAddress: String
    let latitude: Double?
    let longitude: Double?
}

extension SpeedTestResult {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
    var hasCoordinate: Bool {
        latitude != nil && longitude != nil
    }
    var mapRegion: MKCoordinateRegion? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                  span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
}

// MARK: - Location Provider

final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }
    
    func start() {
        manager.startUpdatingLocation()
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            self.manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // You could log error if needed
    }
}

// MARK: - System Monitor

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var ramUsage: Double = 0
    @Published var ramUsedGB: Double = 0
    @Published var ramTotalGB: Double = 0
    @Published var diskUsage: Double = 0
    @Published var batteryLevel: Double = 100
    @Published var isCharging: Bool = false
    @Published var batteryIcon: String = "battery.100"
    
    @Published var cpuHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var ramHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var topProcesses: [AppProcessInfo] = []
    
    private var timer: Timer?
    
    func startMonitoring() {
        updateStats()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func updateStats() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let cpu = self.getCPUUsage()
            let ramTuple = self.getRAMUsage()
            let ram = ramTuple.percentage
            let disk = self.getDiskUsage()
            let battery = self.getBatteryLevel()
            let charging = self.getChargingStatus()
            
            DispatchQueue.main.async {
                self.cpuUsage = cpu
                self.ramUsage = ram
                self.ramUsedGB = ramTuple.usedGB
                self.ramTotalGB = ramTuple.totalGB
                self.diskUsage = disk
                self.batteryLevel = battery
                self.isCharging = charging
                
                // Update battery icon
                if charging {
                    self.batteryIcon = "bolt.battery.fill"
                } else if battery > 75 {
                    self.batteryIcon = "battery.100"
                } else if battery > 50 {
                    self.batteryIcon = "battery.75"
                } else if battery > 25 {
                    self.batteryIcon = "battery.50"
                } else {
                    self.batteryIcon = "battery.25"
                }
                
                // Update history
                if self.cpuHistory.count >= 60 {
                    self.cpuHistory = Array(self.cpuHistory.dropFirst()) + [cpu]
                } else {
                    self.cpuHistory.append(cpu)
                }
                
                if self.ramHistory.count >= 60 {
                    self.ramHistory = Array(self.ramHistory.dropFirst()) + [ram]
                } else {
                    self.ramHistory.append(ram)
                }
                
                // Update processes (less frequently)
                if Int(Date().timeIntervalSince1970) % 3 == 0 {
                    self.topProcesses = self.getTopProcesses()
                }
            }
        }
    }
    
    private func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else { continue }
                
                let threadBasicInfo = threadInfo
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
            
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }
        
        return totalUsageOfCPU
    }
    
    private func getRAMUsage() -> (percentage: Double, usedGB: Double, totalGB: Double) {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(taskInfo.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            
            let usedGB = usedMemory / 1024 / 1024 / 1024
            let totalGB = totalMemory / 1024 / 1024 / 1024
            let percentage = (usedMemory / totalMemory) * 100
            
            return (percentage, usedGB, totalGB)
        }
        
        return (0, 0, 0)
    }
    
    private func getDiskUsage() -> Double {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let totalSpace = attributes[.systemSize] as? NSNumber,
               let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                let total = totalSpace.doubleValue
                let free = freeSpace.doubleValue
                let used = total - free
                return (used / total) * 100
            }
        }
        return 0
    }
    
    private func getBatteryLevel() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Double(UIDevice.current.batteryLevel * 100)
    }
    
    private func getChargingStatus() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    private func getTopProcesses() -> [AppProcessInfo] {
        // iOS doesn't allow access to system processes, return mock data
        return []
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Speed Test Manager

class SpeedTestManager: ObservableObject {
    @Published var isRunning = false
    @Published var currentStatus = "Ready to test"
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Double = 0
    @Published var progress: Double = 0
    @Published var testHistory: [SpeedTestResult] = []
    
    let locationProvider = LocationProvider()
    
    func runSpeedTest() {
        guard !isRunning else { return }
        
        isRunning = true
        downloadSpeed = 0
        uploadSpeed = 0
        ping = 0
        progress = 0
        currentStatus = "Starting test..."
        
        locationProvider.requestAuthorizationIfNeeded()
        locationProvider.start()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performSpeedTest()
        }
    }
    
    private func performSpeedTest() {
        // Fetch public IP in parallel
        let ipGroup = DispatchGroup()
        var fetchedIP = ""
        ipGroup.enter()
        fetchPublicIP { ip in
            fetchedIP = ip ?? ""
            ipGroup.leave()
        }
        
        // Test ping
        updateStatus("Testing ping...")
        progress = 0.1
        let pingResult = testPing()
        
        DispatchQueue.main.async {
            self.ping = pingResult
            self.progress = 0.3
        }
        
        // Test download
        updateStatus("Testing download speed...")
        let downloadResult = testDownloadSpeed()
        
        DispatchQueue.main.async {
            self.downloadSpeed = downloadResult
            self.progress = 0.7
        }
        
        // Test upload
        updateStatus("Testing upload speed...")
        let uploadResult = testUploadSpeed()
        
        // Wait for IP to finish
        ipGroup.wait()
        
        // Capture last known location
        let location = locationProvider.lastLocation
        let lat = location?.coordinate.latitude
        let lon = location?.coordinate.longitude
        
        DispatchQueue.main.async {
            self.uploadSpeed = uploadResult
            self.progress = 1.0
            self.currentStatus = "Test complete!"
            
            let result = SpeedTestResult(
                timestamp: Date(),
                downloadSpeed: downloadResult,
                uploadSpeed: uploadResult,
                ping: pingResult,
                server: "Auto-selected",
                ipAddress: fetchedIP,
                latitude: lat,
                longitude: lon
            )
            self.testHistory.insert(result, at: 0)
            
            self.isRunning = false
            self.locationProvider.stop()
        }
    }
    
    private func fetchPublicIP(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.ipify.org?format=text") else {
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            let ip = data.flatMap { String(data: $0, encoding: .utf8) }?.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(ip)
        }
        task.resume()
    }
    
    private func testPing() -> Double {
        // Simulate ping test
        Thread.sleep(forTimeInterval: 1.0)
        return Double.random(in: 10...50)
    }
    
    private func testDownloadSpeed() -> Double {
        // Simulate download test
        Thread.sleep(forTimeInterval: 2.0)
        return Double.random(in: 50...500)
    }
    
    private func testUploadSpeed() -> Double {
        // Simulate upload test
        Thread.sleep(forTimeInterval: 2.0)
        return Double.random(in: 20...200)
    }
    
    private func updateStatus(_ status: String) {
        DispatchQueue.main.async {
            self.currentStatus = status
        }
    }
    
    func cancelTest() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.currentStatus = "Test cancelled"
            self.progress = 0
            self.locationProvider.stop()
        }
    }
}

// MARK: - Theme Manager

enum ThemeType: String, CaseIterable {
    case dark, light, amoled
}

struct AppTheme {
    let backgroundColor: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let accentColor: Color
    let borderColor: Color
}

class ThemeManager: ObservableObject {
    @Published var currentThemeType: ThemeType = .dark
    
    var currentTheme: AppTheme {
        switch currentThemeType {
        case .dark:
            return AppTheme(
                backgroundColor: Color(red: 0.11, green: 0.11, blue: 0.12),
                cardBackground: Color(red: 0.15, green: 0.15, blue: 0.17),
                textPrimary: .white,
                textSecondary: Color.gray,
                accentColor: Color.blue,
                borderColor: Color.gray.opacity(0.3)
            )
        case .light:
            return AppTheme(
                backgroundColor: Color(red: 0.95, green: 0.95, blue: 0.97),
                cardBackground: .white,
                textPrimary: .black,
                textSecondary: Color.gray,
                accentColor: Color.blue,
                borderColor: Color.gray.opacity(0.2)
            )
        case .amoled:
            return AppTheme(
                backgroundColor: .black,
                cardBackground: Color(red: 0.05, green: 0.05, blue: 0.05),
                textPrimary: .white,
                textSecondary: Color.gray,
                accentColor: Color.blue,
                borderColor: Color.gray.opacity(0.2)
            )
        }
    }
    
    func setTheme(_ theme: ThemeType) {
        currentThemeType = theme
    }
}
