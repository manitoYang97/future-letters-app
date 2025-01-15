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
                // ProfileView()
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

    var filteredCapsules: [Capsule] {
        capsules.filter { capsule in
            Calendar.current.isDate(capsule.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(filteredCapsules) { capsule in
                    CapsuleCard(capsule: capsule, capsules: $capsules)
                }
            }
            .padding()
        }
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
