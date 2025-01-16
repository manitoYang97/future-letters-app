//
//  ContentView.swift
//  my-mahjong-app
//
//  Created by admin on 2025/1/14.
//

import SwiftUI

// 定义心情胶囊的数据模型
struct Capsule: Identifiable {
    let id = UUID()
    let date: Date
    let mood: String
    let content: String
    let color: Color
}

// 定义时光碎片的数据模型
struct Fragment: Identifiable {
    let id = UUID()
    let price: Double
    let diamonds: Int
    let isPopular: Bool
    var discountPercent: Int?
}

// 主视图
struct ContentView: View {
    // 状态变量
    @State private var selectedTab = 0
    @State private var showingWriteSheet = false
    @State private var viewMode = 0 // 0: 时间流, 1: 时间格
    @State private var capsules: [Capsule] = []
    @State private var selectedDate: Date = Date()
    @State private var diamonds: Int = 0
    @State private var showingPurchaseSheet = false
    @State private var selectedFragment: Fragment?

    let fragments: [Fragment] = [
        Fragment(price: 8.00, diamonds: 1200, isPopular: false),
        Fragment(price: 15.00, diamonds: 2888, isPopular: true, discountPercent: 15),
        Fragment(price: 22.00, diamonds: 3600, isPopular: false),
        Fragment(price: 28.00, diamonds: 5000, isPopular: false)
    ]

    // 底部标签栏的项目
    let tabItems = ["胶囊", "时光", "写信", "工坊", "我的"]
    let tabIcons = ["capsule", "clock", "pencil.circle.fill", "hammer", "person"]

    var body: some View {
        TabView(selection: $selectedTab) {
            // First tab - 胶囊
            NavigationView {
                VStack {
                    // 视图模式切换
                    Picker("View Mode", selection: $viewMode) {
                        Text("时间流").tag(0)
                        Text("时间格").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    if viewMode == 0 {
                        // 时间流视图
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(capsules) { capsule in
                                    CapsuleCard(capsule: capsule, capsules: $capsules)
                                }
                            }
                            .padding()
                        }
                    } else {
                        // 时间格视图
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(capsules) { capsule in
                                    CapsuleIcon(capsule: capsule)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("心情胶囊")
                .navigationBarItems(trailing: Button(action: {
                    showingWriteSheet = true
                }) {
                    Image(systemName: "plus")
                })
                .sheet(isPresented: $showingWriteSheet) {
                    WriteView(isPresented: $showingWriteSheet, capsules: $capsules)
                }
            }
            .tabItem {
                Image(systemName: tabIcons[0])
                Text(tabItems[0])
            }
            .tag(0)

            // Second tab - 时光
            NavigationView {
                TimelineView(capsules: $capsules, selectedDate: $selectedDate)
            }
            .tabItem {
                Image(systemName: tabIcons[1])
                Text(tabItems[1])
            }
            .tag(1)

            // Third tab - 写信
            NavigationView {
                WriteView(isPresented: $showingWriteSheet, capsules: $capsules)
            }
            .tabItem {
                Image(systemName: tabIcons[2])
                Text(tabItems[2])
            }
            .tag(2)

            // Fourth tab - 工坊
            NavigationView {
                ShopView(
                    fragments: fragments,
                    diamonds: $diamonds,
                    showingPurchaseSheet: $showingPurchaseSheet,
                    selectedFragment: $selectedFragment
                )
            }
            .tabItem {
                Image(systemName: tabIcons[3])
                Text(tabItems[3])
            }
            .tag(3)

            // Fifth tab - 我的
            NavigationView {
                ProfileView(capsules: $capsules, diamonds: $diamonds)
            }
            .tabItem {
                Image(systemName: tabIcons[4])
                Text(tabItems[4])
            }
            .tag(4)
        }
        .accentColor(.blue)
    }
}

// 时间流视图
struct TimelineView: View {
    @Binding var capsules: [Capsule]
    @Binding var selectedDate: Date
    @State private var selectedMonth: Date = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    // 添加公开的初始化方法
    public init(capsules: Binding<[Capsule]>, selectedDate: Binding<Date>) {
        self._capsules = capsules
        self._selectedDate = selectedDate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计卡片
                StatisticsCard(capsules: capsules)

                // 日历视图
                VStack(spacing: 10) {
                    // 月份选择器
                    HStack {
                        Button(action: { previousMonth() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }

                        Text(dateFormatter.string(from: selectedMonth))
                            .font(.headline)
                            .frame(width: 120)

                        Button(action: { nextMonth() }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 10)

                    // 星期标题
                    WeekdayHeader()

                    // 日历网格
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(getDaysInMonth(), id: \.self) { date in
                            DayCell(
                                date: date,
                                selectedDate: $selectedDate,
                                capsules: capsules,
                                isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // 选中日期的胶囊列表
                if !filteredCapsules.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedDateFormatter.string(from: selectedDate))
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(filteredCapsules) { capsule in
                            CapsuleCard(capsule: capsule, capsules: $capsules)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    EmptyStateView(date: selectedDate)
                }
            }
            .padding()
        }
        .navigationTitle("时光")
    }

    private var selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    var filteredCapsules: [Capsule] {
        capsules.filter { capsule in
            calendar.isDate(capsule.date, inSameDayAs: selectedDate)
        }
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func getDaysInMonth() -> [Date] {
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let days = calendar.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )

        // 获取月份第一天是星期几
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let prefixDays = (1..<firstWeekday).map { offset in
            calendar.date(byAdding: .day, value: -offset, to: interval.start)!
        }.reversed()

        // 获取月份最后一天后需要补充的天数
        let lastWeekday = calendar.component(.weekday, from: interval.end)
        let suffixDays = (lastWeekday...7).map { offset in
            calendar.date(byAdding: .day, value: offset - lastWeekday, to: interval.end)!
        }

        return Array(prefixDays) + days + suffixDays
    }
}

// 统计卡片视图
struct StatisticsCard: View {
    let capsules: [Capsule]

    public init(capsules: [Capsule]) {
        self.capsules = capsules
    }

    private var totalDays: Int {
        Set(capsules.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private var thisMonthDays: Int {
        let calendar = Calendar.current
        let now = Date()
        let monthCapsules = capsules.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return Set(monthCapsules.map { calendar.startOfDay(for: $0.date) }).count
    }

    private var streakDays: Int {
        calculateStreakDays()
    }

    var body: some View {
        HStack(spacing: 20) {
            StatBox(title: "写信天数", value: "\(totalDays)", color: .blue)
            StatBox(title: "本月天数", value: "\(thisMonthDays)", color: .green)
            StatBox(title: "连续天数", value: "\(streakDays)", color: .orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedDates = capsules
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
            .uniqued()

        var streak = 0
        var currentDate = today

        while sortedDates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streak
    }
}

// 统计框视图
struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// 星期标题视图
struct WeekdayHeader: View {
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// 日期单元格视图
struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let capsules: [Capsule]
    let isCurrentMonth: Bool

    public init(date: Date, selectedDate: Binding<Date>, capsules: [Capsule], isCurrentMonth: Bool) {
        self.date = date
        self._selectedDate = selectedDate
        self.capsules = capsules
        self.isCurrentMonth = isCurrentMonth
    }

    private let calendar = Calendar.current

    private var day: Int {
        calendar.component(.day, from: date)
    }

    private var hasCapsule: Bool {
        capsules.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        Button(action: { selectedDate = date }) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 16))
                    .foregroundColor(textColor)

                if hasCapsule {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 40)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .opacity(isSelected || isToday ? 1 : 0)
            )
        }
        .disabled(!isCurrentMonth)
    }

    private var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.3)
        }
        if isSelected {
            return .white
        }
        if isToday {
            return .blue
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        }
        if isToday {
            return .blue.opacity(0.1)
        }
        return .clear
    }
}

// 空状态视图
struct EmptyStateView: View {
    let date: Date

    public init(date: Date) {
        self.date = date
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("\(dateFormatter.string(from: date))还没有写信哦")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// 扩展 Calendar 添加日期生成方法
extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

// 扩展 Sequence 添加去重方法
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

// 网格视图
struct GridView: View {
    let capsules: [Capsule]
    @Binding var selectedDate: Date

    var filteredCapsules: [Capsule] {
        capsules.filter { capsule in
            Calendar.current.isDate(capsule.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                ForEach(filteredCapsules) { capsule in
                    CapsuleIcon(capsule: capsule)
                }
            }
            .padding()
        }
    }
}

// 写信视图
struct WriteView: View {
    @Binding var isPresented: Bool
    @Binding var capsules: [Capsule]
    var editingCapsule: Capsule?

    @State private var content: String
    @State private var selectedColor: Color
    @State private var selectedDate: Date

    init(isPresented: Binding<Bool>, capsules: Binding<[Capsule]>, editingCapsule: Capsule? = nil) {
        self._isPresented = isPresented
        self._capsules = capsules
        self.editingCapsule = editingCapsule

        // 初始化状态
        _content = State(initialValue: editingCapsule?.content ?? "")
        _selectedColor = State(initialValue: editingCapsule?.color ?? .blue)
        _selectedDate = State(initialValue: editingCapsule?.date ?? Date())
    }

    let colors: [Color] = [.red, .blue, .green, .yellow, .purple]

    var body: some View {
        NavigationView {
            Form {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)

                Section(header: Text("选择心情")) {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(color == selectedColor ? Color.black : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }

                Section(header: Text("写给未来的信")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
            }
            .navigationTitle(editingCapsule == nil ? "写信" : "编辑")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    if let editingCapsule = editingCapsule,
                       let index = capsules.firstIndex(where: { $0.id == editingCapsule.id }) {
                        // 更新现有胶囊
                        let updatedCapsule = Capsule(date: selectedDate, mood: "Happy", content: content, color: selectedColor)
                        capsules[index] = updatedCapsule
                    } else {
                        // 创建新胶囊
                        let newCapsule = Capsule(date: selectedDate, mood: "Happy", content: content, color: selectedColor)
                        capsules.append(newCapsule)
                    }
                    isPresented = false
                }
            )
        }
    }
}

// 胶囊卡片视图
struct CapsuleCard: View {
    let capsule: Capsule
    @Binding var capsules: [Capsule]
    @State private var showingEditSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .fill(capsule.color)
                    .frame(width: 20, height: 20)
                Text(capsule.date, style: .date)
                Spacer()
            }

            Text(capsule.content)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let index = capsules.firstIndex(where: { $0.id == capsule.id }) {
                    capsules.remove(at: index)
                }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            WriteView(isPresented: $showingEditSheet, capsules: $capsules, editingCapsule: capsule)
        }
    }
}

// 胶囊图标视图
struct CapsuleIcon: View {
    let capsule: Capsule

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(capsule.color)
                .frame(width: 40, height: 60)
            Text(capsule.date, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// 添加商店视图
struct ShopView: View {
    let fragments: [Fragment]
    @Binding var diamonds: Int
    @Binding var showingPurchaseSheet: Bool
    @Binding var selectedFragment: Fragment?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 钻石余额
                    HStack {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.blue)
                        Text("\(diamonds)")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    // 碎片列表
                    VStack(spacing: 15) {
                        ForEach(fragments) { fragment in
                            FragmentCard(fragment: fragment)
                                .onTapGesture {
                                    selectedFragment = fragment
                                    showingPurchaseSheet = true
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("时光碎片")
            .sheet(isPresented: $showingPurchaseSheet) {
                if let fragment = selectedFragment {
                    PurchaseView(fragment: fragment, diamonds: $diamonds, isPresented: $showingPurchaseSheet)
                }
            }
        }
    }
}

// 添加碎片卡片视图
struct FragmentCard: View {
    let fragment: Fragment

    var body: some View {
        HStack {
            // 左侧图标
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "diamond.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
            }

            // 中间内容
            VStack(alignment: .leading) {
                Text("💎 \(fragment.diamonds)")
                    .font(.headline)
                if fragment.isPopular {
                    Text("最受欢迎")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }

            Spacer()

            // 右侧价格
            VStack(alignment: .trailing) {
                if let discount = fragment.discountPercent {
                    Text("省\(discount)%")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                Text("¥\(String(format: "%.2f", fragment.price))")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// 添加购买确认视图
struct PurchaseView: View {
    let fragment: Fragment
    @Binding var diamonds: Int
    @Binding var isPresented: Bool
    @State private var isPurchasing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 商品信息
                VStack(spacing: 10) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("\(fragment.diamonds) 碎片")
                        .font(.title2)

                    Text("¥\(String(format: "%.2f", fragment.price))")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()

                // 支付按钮
                Button(action: {
                    isPurchasing = true
                    // 模拟支付过程
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        diamonds += fragment.diamonds
                        isPurchasing = false
                        isPresented = false
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("确认支付")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isPurchasing)

                Spacer()
            }
            .padding()
            .navigationTitle("购买碎片")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var capsules: [Capsule]

    var body: some View {
        VStack {
            Text(selectedDate, style: .date)
                .font(.headline)
                .padding()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    let hasCapusle = capsules.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })

                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .frame(width: 35, height: 35)
                                .background(
                                    Circle()
                                        .fill(Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                            ? Color.blue.opacity(0.3)
                                            : Color.clear)
                                )

                            if hasCapusle {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .foregroundColor(Calendar.current.isDateInToday(date) ? .blue : .primary)
                }
            }
            .padding()
        }
    }

    func getDaysInMonth() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components)!

        var days: [Date] = []
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

struct ProfileView: View {
    @Binding var capsules: [Capsule]
    @Binding var diamonds: Int
    @StateObject private var userSettings = UserSettings()
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("username") private var username = "未设置昵称"
    @State private var showingEditUsername = false
    @State private var showingImagePicker = false
    @State private var showingBackupOptions = false
    @State private var showingDocumentPicker = false
    @State private var showingLogoutAlert = false
    @State private var newUsername = ""
    @State private var showingImageSource = false

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        List {
            // 用户信息区
            Section {
                HStack {
                    if let profileImage = userSettings.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .onTapGesture {
                                showingImageSource = true
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "camera.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                    .padding(4)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .offset(x: 20, y: 20),
                                alignment: .bottomTrailing
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showingImageSource = true
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "camera.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                    .padding(4)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .offset(x: 20, y: 20),
                                alignment: .bottomTrailing
                            )
                    }



                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(username)
                                .font(.headline)
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        Text("ID: \(String(abs(username.hashValue)).prefix(8).description)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        newUsername = username  // 设置当前用户名为默认值
                        showingEditUsername = true
                    }
                }
                .padding(.vertical, 8)
            }

            // 统计区
            Section {
                HStack {
                    StatCard(title: "胶囊总数", value: "\(capsules.count)", icon: "capsule.fill")
                    Divider()
                    StatCard(title: "钻石数量", value: "\(diamonds)", icon: "diamond.fill")
                }
                .frame(height: 80)

                // 添加更多统计
                VStack(spacing: 12) {
                    StatRow(title: "本月新增", value: "\(capsuleThisMonth)", icon: "calendar", color: .green)
                    StatRow(title: "连续写作", value: "\(streakDays)天", icon: "flame.fill", color: .orange)
                    StatRow(title: "收藏数量", value: "\(favoriteCount)", icon: "star.fill", color: .yellow)
                }
            }

            // 功能区
            Section(header: Text("功能")) {
                Button(action: { showingBackupOptions = true }) {
                    SettingRow(icon: "arrow.triangle.2.circlepath", title: "备份与恢复", color: .green)
                }

                // NavigationLink(destination: PrivacyView()) {
                //     SettingRow(icon: "hand.raised.fill", title: "隐私政策", color: .blue)
                // }

//                NavigationLink(destination: HelpCenterView()) {
//                    SettingRow(icon: "questionmark.circle.fill", title: "帮助中心", color: .purple)
//                }
            }

            // 设置区
            Section(header: Text("设置")) {
                Toggle(isOn: $notificationsEnabled) {
                    SettingRow(icon: "bell.fill", title: "消息通知", color: .red)
                }

                Toggle(isOn: $userSettings.isDarkMode) {
                    SettingRow(icon: "moon.fill", title: "深色模式", color: .indigo)
                }

                // NavigationLink(destination: AboutView(version: appVersion)) {
                //     SettingRow(icon: "info.circle.fill", title: "关于我们", color: .orange)
                // }
            }

            // 退出登录
            Section {
                Button(action: { showingLogoutAlert = true }) {
                    Text("退出登录")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $userSettings.profileImage)
        }
        .sheet(isPresented: $showingEditUsername) {
            NavigationView {
                Form {
                    Section(header: Text("修改昵称")) {
                        TextField("请输入新昵称", text: $newUsername)
                            .textContentType(.nickname)
                            .submitLabel(.done)

                        if !newUsername.isEmpty && newUsername != username {
                            Text("新昵称: \(newUsername)")
                                .foregroundColor(.gray)
                        }
                    }

                    Section(footer: Text("昵称长度需要在2-20个字符之间").foregroundColor(.gray)) {
                        // 预览新的用户ID
                        if !newUsername.isEmpty && newUsername != username {
                            Text("新ID: \(String(abs(newUsername.hashValue)).prefix(8).description)")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("修改昵称")
                .navigationBarItems(
                    leading: Button("取消") {
                        showingEditUsername = false
                        newUsername = username
                    },
                    trailing: Button("保存") {
                        if validateUsername(newUsername) {
                            username = newUsername
                            showingEditUsername = false
                        }
                    }
                    .disabled(!validateUsername(newUsername))
                )
            }
        }
        .actionSheet(isPresented: $showingBackupOptions) {
            ActionSheet(
                title: Text("备份与恢复"),
                buttons: [
                    .default(Text("创建备份")) { createBackup() },
                    .default(Text("从备份恢复")) { showingDocumentPicker = true },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(completion: restoreFromBackup)
        }
        .alert("确认退出", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .actionSheet(isPresented: $showingImageSource) {
            ActionSheet(
                title: Text("选择头像"),
                buttons: [
                    .default(Text("拍照")) {
                        showingImagePicker = true
                        // TODO: 设置图片源为相机
                    },
                    .default(Text("从相册选择")) {
                        showingImagePicker = true
                        // TODO: 设置图片源为相册
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }

    // 计算属性
    private var capsuleThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return capsules.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }.count
    }

    private var streakDays: Int {
        // 实现连续写作天数的计算逻辑
        return 7 // 示例返回值
    }

    private var favoriteCount: Int {
        // 实现收藏数量的计算逻辑
        return 12 // 示例返回值
    }

    // 功能方法
    private func createBackup() {
        guard let backupData = userSettings.backupData() else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup_\(Date().timeIntervalSince1970).json")

        do {
            try backupData.write(to: tempURL)
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Backup failed: \(error)")
        }
    }

    private func restoreFromBackup(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try userSettings.restoreFromBackup(data)
        } catch {
            print("Restore failed: \(error)")
        }
    }

    private func logout() {
        // 实现退出登录逻辑
        UserDefaults.standard.removeObject(forKey: "userToken")
        // 跳转到登录页面
    }

    private func validateUsername(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 20 && trimmed != self.username
    }
}

// 统计行组件
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// 设置行组件
struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)
            Text(title)
        }
    }
}

// MARK: - UserSettings
class UserSettings: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            applyTheme()
        }
    }

    @Published var profileImage: UIImage? {
        didSet {
            if let imageData = profileImage?.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(imageData, forKey: "profileImage")
            }
        }
    }

    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        if let imageData = UserDefaults.standard.data(forKey: "profileImage"),
           let image = UIImage(data: imageData) {
            self.profileImage = image
        } else {
            self.profileImage = nil
        }
    }

    private func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }

    func backupData() -> Data? {
        let backup = BackupData(
            capsules: UserDefaults.standard.data(forKey: "capsules"),
            profileImage: UserDefaults.standard.data(forKey: "profileImage"),
            settings: [
                "isDarkMode": isDarkMode,
                "username": UserDefaults.standard.string(forKey: "username") ?? ""
            ]
        )
        return try? JSONEncoder().encode(backup)
    }

    func restoreFromBackup(_ data: Data) throws {
        let backup = try JSONDecoder().decode(BackupData.self, from: data)
        if let capsulesData = backup.capsules {
            UserDefaults.standard.set(capsulesData, forKey: "capsules")
        }
        if let profileImageData = backup.profileImage {
            UserDefaults.standard.set(profileImageData, forKey: "profileImage")
            self.profileImage = UIImage(data: profileImageData)
        }
        self.isDarkMode = backup.settings["isDarkMode"] as? Bool ?? false
        if let username = backup.settings["username"] as? String {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
}

// MARK: - BackupData
struct BackupData: Codable {
    let capsules: Data?
    let profileImage: Data?
    let settings: [String: Any]

    enum CodingKeys: String, CodingKey {
        case capsules, profileImage, settings
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capsules, forKey: .capsules)
        try container.encode(profileImage, forKey: .profileImage)
        try container.encode(settings.compactMapValues { $0 as? String }, forKey: .settings)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capsules = try container.decodeIfPresent(Data.self, forKey: .capsules)
        profileImage = try container.decodeIfPresent(Data.self, forKey: .profileImage)
        settings = try container.decode([String: String].self, forKey: .settings)
    }

    init(capsules: Data?, profileImage: Data?, settings: [String: Any]) {
        self.capsules = capsules
        self.profileImage = profileImage
        self.settings = settings
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true  // 允许编辑（裁剪）
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - DocumentPicker
struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL) -> Void

        init(completion: @escaping (URL) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            completion(url)
        }
    }
}
