import SwiftUI

@main
struct InsuranceCommissionPalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 产品类型
enum ProductCategory: String, CaseIterable, Identifiable {
    case main = "主险"
    case rider = "附加险/重疾"
    case waiver = "豁免险"
    case accident = "意外险"
    case medical = "医疗险"
    case internet = "互联网产品"

    var id: String { rawValue }
}

// MARK: - 缴费期限选项
enum PaymentTerm: String, CaseIterable, Identifiable {
    case oneYear = "1年"
    case threeYear = "3年"
    case fiveYear = "5年"
    case tenYear = "10年"
    case fifteenYear = "15年"
    case twentyYear = "20年"
    case thirtyYear = "30年"
    case perpetual = "不限"

    var id: String { rawValue }

    var years: Int {
        switch self {
        case .oneYear: return 1
        case .threeYear: return 3
        case .fiveYear: return 5
        case .tenYear: return 10
        case .fifteenYear: return 15
        case .twentyYear: return 20
        case .thirtyYear: return 30
        case .perpetual: return 0
        }
    }

    // 豁免险对应的缴费期
    var waiverTerm: String {
        switch self {
        case .tenYear: return "9年"
        case .fifteenYear: return "14年"
        case .twentyYear: return "19年"
        case .thirtyYear: return "29年"
        default: return rawValue
        }
    }
}

// MARK: - 保额区间
enum CoverageRange: String, CaseIterable, Identifiable {
    case under20万 = "主险保额<20万"
    case from20to30万 = "20万≤主险保额<30万"
    case from30to100万 = "30万≤主险保额<100万"
    case over100万 = "主险保额≥100万"

    var id: String { rawValue }

    static func from(coverage: Double) -> CoverageRange {
        if coverage < 200000 { return .under20万 }
        else if coverage < 300000 { return .from20to30万 }
        else if coverage < 1000000 { return .from30to100万 }
        else { return .over100万 }
    }
}

// MARK: - 少儿重疾保额区间
enum ChildCoverageRange: String, CaseIterable, Identifiable {
    case under60万 = "重疾保额<60万"
    case over60万 = "重疾保额≥60万"

    var id: String { rawValue }

    static func from(coverage: Double) -> ChildCoverageRange {
        return coverage < 600000 ? .under60万 : .over60万
    }
}

// MARK: - FYP类型
enum FYPType {
    case normal // 普通固定佣金率
    case tiered // 分段计算（如智悦人生、智能星）
}

// MARK: - 保险产品
struct InsuranceProduct: Identifiable {
    let id: String
    let name: String
    let category: ProductCategory
    let insuranceTerm: String // 保险期限
    let paymentTerms: [PaymentTerm] // 允许的缴费期限
    let needsCoverage: Bool // 是否需要保额
    let coverageType: CoverageRange.Type? // 保额类型（成人/少儿）
    let fypType: FYPType
    let commissionRules: [CommissionRule] // 佣金规则

    // 豁免险专用：是否跟随主险缴费期
    let isWaiverFollowsMain: Bool
}

// MARK: - 佣金规则
struct CommissionRule {
    let paymentTerm: PaymentTerm?
    let coverageRange: String? // 保额区间
    let fypCondition: String? // FYP条件
    let firstYearRate: Double
    let secondYearRate: Double?
    let thirdYearRate: Double?
}

// MARK: - 产品组合中的单个产品
struct ProductInGroup: Identifiable {
    let id = UUID()
    let product: InsuranceProduct
    var premium: String = "" // 该产品的保费
    var coverage: String = "" // 保额（如果有）
    var calculatedCommission: Int = 0 // 计算的佣金
}

// MARK: - 全局参数
struct GlobalParameters {
    var paymentTerm: PaymentTerm = .twentyYear
    var standardPremiumRate: Double = 100 // 标准保费折算 %
    var coExpandRatio: Double = 1 // 共同展业比例 1=不共展, 0.5=共展
}

// MARK: - ContentView
struct ContentView: View {
    // MARK: - 颜色定义
    let primaryColor = Color(hex: "2563EB")
    let successColor = Color(hex: "10B981")
    let backgroundColor = Color(hex: "F8FAFC")
    let textPrimary = Color(hex: "1E293B")
    let textSecondary = Color(hex: "64748B")
    let borderColor = Color(hex: "E2E8F0")
    let errorColor = Color(hex: "EF4444")

    // MARK: - 全局参数
    @State private var globalParams = GlobalParameters()
    @State private var selectedCategory: ProductCategory? = nil
    @State private var selectedProduct: InsuranceProduct? = nil
    @State private var showCoExpandPicker = false

    // MARK: - 产品组合
    @State private var productGroup: [ProductInGroup] = []

    // MARK: - 错误提示
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - 产品数据
    private let products: [InsuranceProduct] = createProducts()

    // 过滤当前类型的产品
    private var filteredProducts: [InsuranceProduct] {
        guard let category = selectedCategory else { return [] }
        return products.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                Text("保险佣金计算器")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(textPrimary)
                    .padding(.top, 20)

                // 全局参数区域
                globalParamsSection

                // 产品组合区域
                productGroupSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .background(backgroundColor)
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 全局参数区域
    private var globalParamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全局参数")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(textPrimary)

            // 缴费期限
            VStack(alignment: .leading, spacing: 6) {
                Text("缴费期限")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textSecondary)

                Menu {
                    ForEach(PaymentTerm.allCases) { term in
                        Button(term.rawValue) {
                            globalParams.paymentTerm = term
                            recalculateAll()
                        }
                    }
                } label: {
                    HStack {
                        Text(globalParams.paymentTerm.rawValue)
                            .foregroundColor(textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(textSecondary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }
            }

            // 标准保费折算 & 共展比例并排
            HStack(spacing: 12) {
                // 标准保费折算
                VStack(alignment: .leading, spacing: 6) {
                    Text("标准保费折算")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textSecondary)

                    HStack {
                        TextField("100", text: Binding(
                            get: { String(format: "%.0f", globalParams.standardPremiumRate) },
                            set: { globalParams.standardPremiumRate = Double($0) ?? 100 }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("%")
                            .foregroundColor(textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }

                // 共展比例
                VStack(alignment: .leading, spacing: 6) {
                    Text("共展比例")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textSecondary)

                    Menu {
                        Button("不共展 (100%)") {
                            globalParams.coExpandRatio = 1.0
                            recalculateAll()
                        }
                        Button("共展 (50%)") {
                            globalParams.coExpandRatio = 0.5
                            recalculateAll()
                        }
                    } label: {
                        HStack {
                            Text(globalParams.coExpandRatio == 1.0 ? "不共展" : "共展")
                                .foregroundColor(textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 产品组合区域
    private var productGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("产品组合")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textPrimary)

                Spacer()

                Button(action: addProduct) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("添加产品")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(primaryColor)
                }
            }

            if productGroup.isEmpty {
                Text("点击\"添加产品\"开始添加险种")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(productGroup.indices, id: \.self) { index in
                    productCard(at: index)
                }
            }

            // 合计佣金
            if !productGroup.isEmpty {
                totalCommissionCard
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 单个产品卡片
    private func productCard(at index: Int) -> some View {
        let item = productGroup[index]

        return VStack(alignment: .leading, spacing: 12) {
            // 产品信息头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textPrimary)

                    Text(item.product.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                }

                Spacer()

                Button(action: { removeProduct(at: index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(textSecondary)
                }
            }

            // 产品参数
            VStack(spacing: 8) {
                // 保费输入
                HStack {
                    Text("保费（元）")
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                        .frame(width: 80, alignment: .leading)

                    HStack {
                        Text("¥")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textPrimary)

                        TextField("请输入保费", text: $productGroup[index].premium)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .foregroundColor(textPrimary)
                            .onChange(of: productGroup[index].premium) { _, newValue in
                                productGroup[index].premium = filterNonNumeric(newValue)
                                recalculateCommission(at: index)
                            }
                    }
                    .padding(8)
                    .background(Color(hex: "F8FAFC"))
                    .cornerRadius(8)
                }

                // 保额输入（如果有需要）
                if item.product.needsCoverage {
                    HStack {
                        Text("保额（元）")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .leading)

                        HStack {
                            Text("¥")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textPrimary)

                            TextField("请输入保额", text: $productGroup[index].coverage)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16))
                                .foregroundColor(textPrimary)
                                .onChange(of: productGroup[index].coverage) { _, newValue in
                                    productGroup[index].coverage = filterNonNumeric(newValue)
                                    recalculateCommission(at: index)
                                }
                        }
                        .padding(8)
                        .background(Color(hex: "F8FAFC"))
                        .cornerRadius(8)
                    }
                }
            }

            // 佣金显示
            HStack {
                Text("税前首年佣金")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)

                Spacer()

                Text("¥\(item.calculatedCommission)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(successColor)
            }
        }
        .padding(12)
        .background(Color(hex: "F8FAFC"))
        .cornerRadius(12)
    }

    // MARK: - 合计佣金卡片
    private var totalCommissionCard: some View {
        let total = productGroup.reduce(0) { $0 + $1.calculatedCommission }

        return VStack(spacing: 8) {
            Text("合计税前首年佣金")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textSecondary)

            Text("¥\(total)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(successColor)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(hex: "F0FDF4"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(successColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 添加产品
    private func addProduct() {
        // 显示产品选择Sheet
        let alert = UIAlertController(title: "选择产品类型", message: nil, preferredStyle: .actionSheet)

        for category in ProductCategory.allCases {
            let count = products.filter { $0.category == category }.count
            if count > 0 {
                alert.addAction(UIAlertAction(title: "\(category.rawValue) (\(count)个)", style: .default) { _ in
                    showProductSelector(for: category)
                })
            }
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    private func showProductSelector(for category: ProductCategory) {
        let categoryProducts = products.filter { $0.category == category }

        let alert = UIAlertController(title: "选择产品", message: nil, preferredStyle: .actionSheet)

        for product in categoryProducts {
            alert.addAction(UIAlertAction(title: product.name, style: .default) { _ in
                let newItem = ProductInGroup(product: product)
                productGroup.append(newItem)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    // MARK: - 移除产品
    private func removeProduct(at index: Int) {
        productGroup.remove(at: index)
    }

    // MARK: - 重新计算所有佣金
    private func recalculateAll() {
        for index in productGroup.indices {
            recalculateCommission(at: index)
        }
    }

    // MARK: - 计算单个产品佣金
    private func recalculateCommission(at index: Int) {
        let item = productGroup[index]
        let product = item.product

        guard let premium = Double(item.premium), premium > 0 else {
            productGroup[index].calculatedCommission = 0
            return
        }

        // 应用标准保费折算和共展比例
        let adjustedPremium = premium * (globalParams.standardPremiumRate / 100.0) * globalParams.coExpandRatio

        var commissionRate: Double = 0

        // 根据产品类型和参数确定佣金率
        switch product.category {
        case .waiver:
            commissionRate = calculateWaiverCommissionRate(
                product: product,
                paymentTerm: globalParams.paymentTerm
            )

        case .main, .rider:
            let coverageValue = Double(item.coverage) ?? 0
            commissionRate = calculateMainOrRiderCommissionRate(
                product: product,
                paymentTerm: globalParams.paymentTerm,
                coverage: coverageValue,
                totalPremium: premium
            )

        case .accident, .medical, .internet:
            commissionRate = calculateSimpleCommissionRate(
                product: product,
                paymentTerm: globalParams.paymentTerm
            )
        }

        // 计算佣金
        let commission = adjustedPremium * commissionRate
        productGroup[index].calculatedCommission = Int(commission.rounded())
    }

    // MARK: - 豁免险佣金率计算
    private func calculateWaiverCommissionRate(product: InsuranceProduct, paymentTerm: PaymentTerm) -> Double {
        let term = paymentTerm.waiverTerm

        for rule in product.commissionRules {
            if rule.paymentTerm?.rawValue == term {
                return rule.firstYearRate
            }
        }

        // 默认值
        return 0.35
    }

    // MARK: - 主险/附加险佣金率计算
    private func calculateMainOrRiderCommissionRate(
        product: InsuranceProduct,
        paymentTerm: PaymentTerm,
        coverage: Double,
        totalPremium: Double
    ) -> Double {
        // 首先检查是否有特殊FYP规则
        if product.fypType == .tiered {
            return calculateTieredFYP(product: product, premium: totalPremium, baseRate: 0.26)
        }

        // 根据保额确定区间
        let coverageRange: String
        if product.category == .rider && product.name.contains("少儿") {
            coverageRange = ChildCoverageRange.from(coverage: coverage).rawValue
        } else {
            coverageRange = CoverageRange.from(coverage: coverage).rawValue
        }

        // 查找匹配的规则
        for rule in product.commissionRules {
            // 检查缴费期
            let termMatch = rule.paymentTerm == nil || rule.paymentTerm == paymentTerm
            // 检查保额条件
            let coverageMatch = rule.coverageRange == nil || rule.coverageRange == coverageRange
            // 检查FYP条件
            let fypMatch = rule.fypCondition == nil

            if termMatch && coverageMatch && fypMatch {
                return rule.firstYearRate
            }
        }

        // 默认值
        return 0.35
    }

    // MARK: - 简单佣金率计算（意外险、医疗险等）
    private func calculateSimpleCommissionRate(product: InsuranceProduct, paymentTerm: PaymentTerm) -> Double {
        // 一年期产品直接返回固定佣金率
        if product.paymentTerms.contains(.oneYear) {
            return 0.20
        }

        for rule in product.commissionRules {
            if rule.paymentTerm == paymentTerm {
                return rule.firstYearRate
            }
        }

        // 默认值
        return 0.20
    }

    // MARK: - 分段FYP计算
    private func calculateTieredFYP(product: InsuranceProduct, premium: Double, baseRate: Double) -> Double {
        // 智悦人生Ⅱ: 10000以内26%，超过部分1.5%
        if product.name.contains("智悦人生") {
            if premium <= 10000 {
                return 0.26
            } else {
                let commission = (premium - 10000) * 0.015 + 2600
                return commission / premium
            }
        }

        // 智能星Ⅱ: 6000以内23%，6000-10000部分25%，超过部分1.5%
        if product.name.contains("智能星") {
            if premium <= 6000 {
                return 0.23
            } else if premium <= 10000 {
                return 0.25
            } else {
                let commission = (premium - 10000) * 0.015 + 2500
                return commission / premium
            }
        }

        return baseRate
    }

    // MARK: - 过滤非数字
    private func filterNonNumeric(_ text: String) -> String {
        return text.filter { $0.isNumber }
    }
}

// MARK: - 创建产品数据
func createProducts() -> [InsuranceProduct] {
    var products: [InsuranceProduct] = []

    // MARK: - 豁免险
    let waiverProducts: [(String, String, Bool)] = [
        ("豁免定期A14", "30年", true),
        ("豁免B16", "终身", false),
        ("豁免C16", "终身", false),
        ("豁免B加强版", "30年", true),
        ("豁免C加强版", "30年", true),
        ("少儿豁免17", "终身", false),
        ("轻症豁免B", "终身", false),
        ("轻症豁免C", "终身", false),
    ]

    for (name, term, followsMain) in waiverProducts {
        products.append(InsuranceProduct(
            id: name,
            name: name,
            category: .waiver,
            insuranceTerm: term,
            paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
            needsCoverage: false,
            coverageType: nil,
            fypType: .normal,
            commissionRules: [
                CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: 0.03, thirdYearRate: 0.03),
                CommissionRule(paymentTerm: .fifteenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.32, secondYearRate: 0.05, thirdYearRate: 0.05),
                CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.35, secondYearRate: 0.10, thirdYearRate: 0.10),
                CommissionRule(paymentTerm: .thirtyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
            ],
            isWaiverFollowsMain: followsMain
        ))
    }

    // MARK: - 主险
    products.append(InsuranceProduct(
        id: "平安福18",
        name: "平安福18",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: true,
        coverageType: CoverageRange.self,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: "缴费期小于20年", fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "缴费期小于20年", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险保额<20万", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "20万≤主险保额<30万", fypCondition: nil, firstYearRate: 0.50, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "30万≤主险保额<100万", fypCondition: nil, firstYearRate: 0.55, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险保额≥100万", fypCondition: nil, firstYearRate: 0.60, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险保额<20万", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "20万≤主险保额<30万", fypCondition: nil, firstYearRate: 0.50, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "30万≤主险保额<100万", fypCondition: nil, firstYearRate: 0.55, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险保额≥100万", fypCondition: nil, firstYearRate: 0.60, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "金鑫盛17",
        name: "金鑫盛17",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            // 10年缴费
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.37, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.32, secondYearRate: 0.05, thirdYearRate: 0.05),
            // 15年缴费
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.40, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.35, secondYearRate: 0.10, thirdYearRate: 0.10),
            // 20/30年缴费
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "鑫盛17",
        name: "鑫盛17",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.37, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.32, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.40, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.35, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "鑫祥17",
        name: "鑫祥17",
        category: .main,
        insuranceTerm: "至65岁",
        paymentTerms: [.fiveYear, .tenYear, .twentyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .fiveYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.10, secondYearRate: 0.03, thirdYearRate: 0.03),
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.22, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.30, secondYearRate: 0.075, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "安鑫保",
        name: "安鑫保",
        category: .main,
        insuranceTerm: "至70岁",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.32, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.35, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.10),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "鑫利17Ⅱ",
        name: "鑫利17Ⅱ",
        category: .main,
        insuranceTerm: "至80岁",
        paymentTerms: [.fiveYear, .tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .fiveYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.13, secondYearRate: 0.03, thirdYearRate: 0.03),
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.22, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.27, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.35, secondYearRate: 0.075, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.35, secondYearRate: 0.075, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "玺越人生成人",
        name: "玺越人生成人",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.threeYear, .fiveYear, .tenYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .threeYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.09, secondYearRate: 0.02, thirdYearRate: 0.02),
            CommissionRule(paymentTerm: .fiveYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.12, secondYearRate: 0.05, thirdYearRate: 0.04),
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.22, secondYearRate: 0.05, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "玺越人生少儿",
        name: "玺越人生少儿",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.threeYear, .fiveYear, .tenYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .threeYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.09, secondYearRate: 0.02, thirdYearRate: 0.02),
            CommissionRule(paymentTerm: .fiveYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.12, secondYearRate: 0.05, thirdYearRate: 0.04),
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.22, secondYearRate: 0.05, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "传世臻宝",
        name: "传世臻宝",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.threeYear, .fiveYear, .tenYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .threeYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.12, secondYearRate: 0.04, thirdYearRate: 0.04),
            CommissionRule(paymentTerm: .fiveYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.35, secondYearRate: 0.05, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    // MARK: - 分段FYP产品
    products.append(InsuranceProduct(
        id: "智悦人生Ⅱ",
        name: "智悦人生Ⅱ",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.perpetual],
        needsCoverage: false,
        coverageType: nil,
        fypType: .tiered,
        commissionRules: [
            CommissionRule(paymentTerm: .perpetual, coverageRange: nil, fypCondition: nil, firstYearRate: 0.26, secondYearRate: 0.05, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "智能星Ⅱ",
        name: "智能星Ⅱ",
        category: .main,
        insuranceTerm: "终身",
        paymentTerms: [.perpetual],
        needsCoverage: false,
        coverageType: nil,
        fypType: .tiered,
        commissionRules: [
            CommissionRule(paymentTerm: .perpetual, coverageRange: nil, fypCondition: nil, firstYearRate: 0.23, secondYearRate: 0.05, thirdYearRate: 0.05),
        ],
        isWaiverFollowsMain: false
    ))

    // MARK: - 附加险/重疾
    // 平安福重疾18
    products.append(InsuranceProduct(
        id: "平安福重疾18",
        name: "平安福重疾18",
        category: .rider,
        insuranceTerm: "终身",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: true,
        coverageType: CoverageRange.self,
        fypType: .normal,
        commissionRules: [
            // 跟随主险规则，使用与平安福18相同的佣金率
            CommissionRule(paymentTerm: .tenYear, coverageRange: "缴费期小于20年", fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "缴费期小于20年", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险保额<20万", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "20万≤主险保额<30万", fypCondition: nil, firstYearRate: 0.50, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "30万≤主险保额<100万", fypCondition: nil, firstYearRate: 0.55, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险保额≥100万", fypCondition: nil, firstYearRate: 0.60, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险保额<20万", fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "20万≤主险保额<30万", fypCondition: nil, firstYearRate: 0.50, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "30万≤主险保额<100万", fypCondition: nil, firstYearRate: 0.55, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险保额≥100万", fypCondition: nil, firstYearRate: 0.60, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "金鑫盛重疾17",
        name: "金鑫盛重疾17",
        category: .rider,
        insuranceTerm: "终身",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.37, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .tenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.32, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.40, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.35, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP≥3000", fypCondition: "≥3000", firstYearRate: 0.48, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: "主险+重疾FYP<3000", fypCondition: "<3000", firstYearRate: 0.40, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    // MARK: - 意外险
    products.append(InsuranceProduct(
        id: "长期意外13",
        name: "长期意外13",
        category: .accident,
        insuranceTerm: "至70岁",
        paymentTerms: [.tenYear, .fifteenYear, .twentyYear, .thirtyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.40, secondYearRate: 0.05, thirdYearRate: 0.05),
            CommissionRule(paymentTerm: .fifteenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.10, thirdYearRate: 0.10),
            CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
            CommissionRule(paymentTerm: .thirtyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.45, secondYearRate: 0.12, thirdYearRate: 0.12),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "意外伤害13",
        name: "意外伤害13",
        category: .accident,
        insuranceTerm: "1年",
        paymentTerms: [.oneYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .oneYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: nil, thirdYearRate: nil),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "百万任我行",
        name: "百万任我行",
        category: .accident,
        insuranceTerm: "30年",
        paymentTerms: [.tenYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: 0.04, thirdYearRate: 0.04),
        ],
        isWaiverFollowsMain: false
    ))

    // MARK: - 医疗险
    products.append(InsuranceProduct(
        id: "住院费用A",
        name: "住院费用A",
        category: .medical,
        insuranceTerm: "1年",
        paymentTerms: [.oneYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .oneYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: nil, thirdYearRate: nil),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "住院费用B",
        name: "住院费用B",
        category: .medical,
        insuranceTerm: "1年",
        paymentTerms: [.oneYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .oneYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: nil, thirdYearRate: nil),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "健享人生A",
        name: "健享人生A",
        category: .medical,
        insuranceTerm: "1年",
        paymentTerms: [.oneYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .oneYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: nil, thirdYearRate: nil),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "健享人生B",
        name: "健享人生B",
        category: .medical,
        insuranceTerm: "1年",
        paymentTerms: [.oneYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .oneYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.20, secondYearRate: nil, thirdYearRate: nil),
        ],
        isWaiverFollowsMain: false
    ))

    // MARK: - 互联网产品
    products.append(InsuranceProduct(
        id: "保宝乐",
        name: "保宝乐",
        category: .internet,
        insuranceTerm: "30年",
        paymentTerms: [.tenYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .tenYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.32, secondYearRate: 0.02, thirdYearRate: 0.02),
        ],
        isWaiverFollowsMain: false
    ))

    products.append(InsuranceProduct(
        id: "爱优宝",
        name: "爱优宝",
        category: .internet,
        insuranceTerm: "终身",
        paymentTerms: [.twentyYear],
        needsCoverage: false,
        coverageType: nil,
        fypType: .normal,
        commissionRules: [
            CommissionRule(paymentTerm: .twentyYear, coverageRange: nil, fypCondition: nil, firstYearRate: 0.25, secondYearRate: 0.04, thirdYearRate: 0.04),
        ],
        isWaiverFollowsMain: false
    ))

    return products
}

// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
