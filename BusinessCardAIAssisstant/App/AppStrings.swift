import Foundation

enum AppStringKey {
    case captureTitle
    case captureSubtitle
    case addButton
    case recentCaptures
    case recentDocuments
    case noRecentDocuments
    case noCaptures
    case directoryTitle
    case companies
    case contacts
    case filters
    case filterTitle
    case companyLocation
    case serviceType
    case targetAudience
    case marketRegion
    case resetFilters
    case done
    case noCompanies
    case noContacts
    case settingsTitle
    case appearance
    case appearanceMode
    case language
    case preferences
    case enableHaptics
    case autoSaveCaptures
    case keepOriginalPhotos
    case enableEnrichment
    case searchPrompt
    case company
    case contact
    case business
    case relatedContacts
    case noRelatedContacts
    case photos
    case addPhoto
    case noPhotos
    case edit
    case save
    case create
    case cancel
    case name
    case summary
    case website
    case phone
    case address
    case notes
    case tags
    case title
    case email
    case location
    case marketRegionLabel
    case serviceTypeLabel
    case keywords
    case companySection
    case targetAudienceSection
    case createDocumentTitle
    case documentType
    case companyName
    case ocrText
    case noOCRText
    case duplicateFoundTitle
    case duplicateFoundMessage
    case updateExisting
    case createNew
    case enrichButton
    case enrichConfirmTitle
    case enrichConfirmMessage
    case department
    case linkedin
    case personalSite
    case industry
    case companySize
    case revenue
    case foundedYear
    case headquarters
    case originalName
    case originalCompanyName
    case profile
    case links
    case companyDetails
    case contactDetails
    case relatedCompany
}

enum AppStrings {
    private static let english: [AppStringKey: String] = [
        .captureTitle: "Capture",
        .captureSubtitle: "Capture a card or brochure to start building documents.",
        .addButton: "Add",
        .recentCaptures: "Recent Captures",
        .recentDocuments: "Recent Documents",
        .noRecentDocuments: "No documents yet",
        .noCaptures: "No captures yet",
        .directoryTitle: "Directory",
        .companies: "Companies",
        .contacts: "Contacts",
        .filters: "Filter",
        .filterTitle: "Filters",
        .companyLocation: "Company Location",
        .serviceType: "Service Type",
        .targetAudience: "Target Audience",
        .marketRegion: "Market Region",
        .resetFilters: "Reset Filters",
        .done: "Done",
        .noCompanies: "No companies found",
        .noContacts: "No contacts found",
        .settingsTitle: "Settings",
        .appearance: "Appearance",
        .appearanceMode: "Color Mode",
        .language: "Language",
        .preferences: "Preferences",
        .enableHaptics: "Enable haptics",
        .autoSaveCaptures: "Auto-save captures",
        .keepOriginalPhotos: "Keep original photos",
        .enableEnrichment: "Enable online enrichment",
        .searchPrompt: "Search people, companies, keywords",
        .company: "Company",
        .contact: "Contact",
        .business: "Business",
        .relatedContacts: "Related Contacts",
        .noRelatedContacts: "No related contacts",
        .photos: "Photos",
        .addPhoto: "Add Photo",
        .noPhotos: "No photos attached",
        .edit: "Edit",
        .save: "Save",
        .create: "Create",
        .cancel: "Cancel",
        .name: "Name",
        .summary: "Summary",
        .website: "Website",
        .phone: "Phone",
        .address: "Address",
        .notes: "Notes",
        .tags: "Tags",
        .title: "Title",
        .email: "Email",
        .location: "Location",
        .marketRegionLabel: "Market region",
        .serviceTypeLabel: "Service type",
        .keywords: "Service keywords",
        .companySection: "Company",
        .targetAudienceSection: "Target Audience",
        .createDocumentTitle: "Create Document",
        .documentType: "Document Type",
        .companyName: "Company Name",
        .ocrText: "OCR Text",
        .noOCRText: "No OCR text available",
        .duplicateFoundTitle: "Possible Duplicate",
        .duplicateFoundMessage: "A similar contact exists. Update the existing contact or create a new one?",
        .updateExisting: "Update Existing",
        .createNew: "Create New",
        .enrichButton: "Enrich with AI",
        .enrichConfirmTitle: "Confirm Enrichment",
        .enrichConfirmMessage: "Use online search to enrich this document now?",
        .department: "Department",
        .linkedin: "LinkedIn",
        .personalSite: "Website",
        .industry: "Industry",
        .companySize: "Company Size",
        .revenue: "Revenue",
        .foundedYear: "Founded",
        .headquarters: "Headquarters",
        .originalName: "Original Name",
        .originalCompanyName: "Original Company Name",
        .profile: "Profile",
        .links: "Links",
        .companyDetails: "Company Details",
        .contactDetails: "Contact Details",
        .relatedCompany: "Company"
    ]

    private static let chinese: [AppStringKey: String] = [
        .captureTitle: "拍照",
        .captureSubtitle: "拍摄名片或资料，快速建立文档。",
        .addButton: "添加",
        .recentCaptures: "最近拍摄",
        .recentDocuments: "最近创建",
        .noRecentDocuments: "暂无创建的档案",
        .noCaptures: "暂无拍摄",
        .directoryTitle: "名录",
        .companies: "公司",
        .contacts: "联系人",
        .filters: "筛选",
        .filterTitle: "筛选",
        .companyLocation: "公司位置",
        .serviceType: "服务类型",
        .targetAudience: "服务对象",
        .marketRegion: "市场区域",
        .resetFilters: "重置筛选",
        .done: "完成",
        .noCompanies: "暂无公司",
        .noContacts: "暂无联系人",
        .settingsTitle: "设置",
        .appearance: "外观",
        .appearanceMode: "主题模式",
        .language: "语言",
        .preferences: "偏好设置",
        .enableHaptics: "开启触感反馈",
        .autoSaveCaptures: "自动保存拍摄",
        .keepOriginalPhotos: "保留原始图片",
        .enableEnrichment: "启用在线补全",
        .searchPrompt: "搜索人名、公司或关键词",
        .company: "公司",
        .contact: "联系人",
        .business: "业务",
        .relatedContacts: "相关联系人",
        .noRelatedContacts: "暂无关联联系人",
        .photos: "图片",
        .addPhoto: "添加照片",
        .noPhotos: "暂无图片",
        .edit: "编辑",
        .save: "保存",
        .create: "创建",
        .cancel: "取消",
        .name: "姓名",
        .summary: "简介",
        .website: "官网",
        .phone: "电话",
        .address: "地址",
        .notes: "备注",
        .tags: "标签",
        .title: "职位",
        .email: "邮箱",
        .location: "位置",
        .marketRegionLabel: "市场区域",
        .serviceTypeLabel: "服务类型",
        .keywords: "业务关键词",
        .companySection: "公司信息",
        .targetAudienceSection: "服务对象",
        .createDocumentTitle: "创建文档",
        .documentType: "文档类型",
        .companyName: "公司名称",
        .ocrText: "OCR 文本",
        .noOCRText: "暂无 OCR 文本",
        .duplicateFoundTitle: "可能重复",
        .duplicateFoundMessage: "检测到相似联系人，是否更新现有联系人或创建新联系人？",
        .updateExisting: "更新现有",
        .createNew: "创建新档案",
        .enrichButton: "使用 AI 补全",
        .enrichConfirmTitle: "确认补全",
        .enrichConfirmMessage: "现在使用联网搜索补全该文档信息吗？",
        .department: "部门",
        .linkedin: "领英",
        .personalSite: "个人网站",
        .industry: "行业",
        .companySize: "公司规模",
        .revenue: "营收",
        .foundedYear: "成立时间",
        .headquarters: "总部",
        .originalName: "原始姓名",
        .originalCompanyName: "原始公司名称",
        .profile: "档案",
        .links: "链接",
        .companyDetails: "公司详情",
        .contactDetails: "联系详情",
        .relatedCompany: "所属公司"
    ]

    static func text(_ key: AppStringKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            return english[key] ?? ""
        case .chinese:
            return chinese[key] ?? ""
        }
    }
}
