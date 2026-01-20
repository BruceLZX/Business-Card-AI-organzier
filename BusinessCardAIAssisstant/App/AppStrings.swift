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
    case tagFilter
    case selectCompany
    case createNewCompany
    case linkExisting
    case selectTags
    case deleteDocument
    case deleteConfirmTitle
    case deleteConfirmMessage
    case confirmDelete
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
    case aiSummaryTitle
    case aiSummaryPlaceholder
    case aiSummaryEmpty
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
    case parseErrorTitle
    case parseFailedMessage
    case multipleEntitiesMessage
    case duplicateFoundTitle
    case duplicateFoundMessage
    case possibleCompanyMatchTitle
    case possibleCompanyMatchMessage
    case useExistingCompany
    case keepNewCompany
    case updateExisting
    case createNew
    case enrichButton
    case enrichingTitle
    case enrichConfirmTitle
    case enrichConfirmMessage
    case undoReplace
    case enrichFailedTitle
    case enrichFailedMessage
    case enrichMissingKeyMessage
    case enrichNoChangesMessage
    case originalValue
    case enrichStageAnalyzing
    case enrichStageSearching
    case enrichStageMerging
    case enrichStageComplete
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
    case originalLocation
    case profile
    case links
    case companyDetails
    case contactDetails
    case relatedCompany
    case relatedCompanies
    case linkNewCompany
    case linkNewContact
    case addFromLibrary
    case takePhoto
    case existingCompany
    case existingContact
    case newInfo
    case discardCreateTitle
    case discardCreateMessage
    case discardCreateAction
    case confirm
    case unlinkConfirmTitle
    case unlinkConfirmMessage
    case unlinkAction
    case enrichAgainButton
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
        .tagFilter: "Tag",
        .selectCompany: "Select Existing",
        .createNewCompany: "Create New Company",
        .linkExisting: "Link",
        .selectTags: "Select Tags",
        .deleteDocument: "Delete Document",
        .deleteConfirmTitle: "Delete Document",
        .deleteConfirmMessage: "This action cannot be undone.",
        .confirmDelete: "Delete",
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
        .aiSummaryTitle: "AI Summary",
        .aiSummaryPlaceholder: "Use AI to generate a summary for this profile.",
        .aiSummaryEmpty: "No summary found.",
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
        .parseErrorTitle: "Unable to Continue",
        .parseFailedMessage: "We couldn't understand this scan. Please retake a clearer photo or create manually.",
        .multipleEntitiesMessage: "Multiple contacts or companies detected. Please retake a focused photo or split into separate scans.",
        .duplicateFoundTitle: "Possible Duplicate",
        .duplicateFoundMessage: "A similar contact exists. Update the existing contact or create a new one?",
        .possibleCompanyMatchTitle: "Similar Company Found",
        .possibleCompanyMatchMessage: "We found a similar company:",
        .useExistingCompany: "Use Existing",
        .keepNewCompany: "Create New",
        .updateExisting: "Update Existing",
        .createNew: "Create New",
        .enrichButton: "Enrich with AI",
        .enrichingTitle: "Enriching with AI...",
        .enrichConfirmTitle: "Confirm Enrichment",
        .enrichConfirmMessage: "Use online search to enrich this document now?",
        .undoReplace: "Undo replace",
        .enrichFailedTitle: "Enrichment Failed",
        .enrichFailedMessage: "We couldn't fetch enrichment data right now. Please try again later.",
        .enrichMissingKeyMessage: "Missing API key. Add it to AIConfig.swift and try again.",
        .enrichNoChangesMessage: "No new information was found for this profile.",
        .originalValue: "Original",
        .enrichStageAnalyzing: "Analyzing photos",
        .enrichStageSearching: "Searching online (%d/%d)",
        .enrichStageMerging: "Merging results",
        .enrichStageComplete: "Done!",
        .department: "Department",
        .linkedin: "LinkedIn",
        .personalSite: "Website",
        .industry: "Industry",
        .companySize: "Company Size",
        .revenue: "Revenue",
        .foundedYear: "Founded",
        .headquarters: "Headquarters",
        .originalName: "Chinese Name",
        .originalCompanyName: "Chinese Company Name",
        .originalLocation: "Chinese Location",
        .profile: "Profile",
        .links: "Links",
        .companyDetails: "Company Details",
        .contactDetails: "Contact Details",
        .relatedCompany: "Company",
        .relatedCompanies: "Companies",
        .linkNewCompany: "Link New Company",
        .linkNewContact: "Link New Contact",
        .addFromLibrary: "Choose from Library",
        .takePhoto: "Take Photo",
        .existingCompany: "Existing Company",
        .existingContact: "Existing Contact",
        .newInfo: "New Info",
        .discardCreateTitle: "Discard Changes?",
        .discardCreateMessage: "Your current inputs will be lost.",
        .discardCreateAction: "Discard",
        .confirm: "Confirm",
        .unlinkConfirmTitle: "Remove Link?",
        .unlinkConfirmMessage: "This will only remove the association.",
        .unlinkAction: "Remove",
        .enrichAgainButton: "Enrich Again with AI"
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
        .tagFilter: "标签",
        .selectCompany: "选择已有公司",
        .createNewCompany: "新建公司",
        .linkExisting: "关联",
        .selectTags: "选择标签",
        .deleteDocument: "删除档案",
        .deleteConfirmTitle: "删除档案",
        .deleteConfirmMessage: "删除后无法恢复。",
        .confirmDelete: "删除",
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
        .aiSummaryTitle: "AI 总结",
        .aiSummaryPlaceholder: "使用 AI 生成该档案总结。",
        .aiSummaryEmpty: "未找到有效信息。",
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
        .parseErrorTitle: "无法继续",
        .parseFailedMessage: "无法识别此次扫描内容，请重新拍摄更清晰的照片或手动创建。",
        .multipleEntitiesMessage: "检测到多个联系人或公司，请重新拍摄更聚焦的内容或拆分创建。",
        .duplicateFoundTitle: "可能重复",
        .duplicateFoundMessage: "检测到相似联系人，是否更新现有联系人或创建新联系人？",
        .possibleCompanyMatchTitle: "发现相似公司",
        .possibleCompanyMatchMessage: "检测到相似公司：",
        .useExistingCompany: "使用已有公司",
        .keepNewCompany: "继续新建",
        .updateExisting: "更新现有",
        .createNew: "创建新档案",
        .enrichButton: "使用 AI 补全",
        .enrichingTitle: "AI 补全中...",
        .enrichConfirmTitle: "确认补全",
        .enrichConfirmMessage: "现在使用联网搜索补全该文档信息吗？",
        .undoReplace: "撤销替换",
        .enrichFailedTitle: "补全失败",
        .enrichFailedMessage: "暂时无法获取补全信息，请稍后再试。",
        .enrichMissingKeyMessage: "未检测到 API Key，请在 AIConfig.swift 中填写后重试。",
        .enrichNoChangesMessage: "未找到新的补全信息。",
        .originalValue: "原有内容",
        .enrichStageAnalyzing: "正在分析照片",
        .enrichStageSearching: "正在联网搜索（%d/%d）",
        .enrichStageMerging: "正在合并结果",
        .enrichStageComplete: "完成！",
        .department: "部门",
        .linkedin: "领英",
        .personalSite: "个人网站",
        .industry: "行业",
        .companySize: "公司规模",
        .revenue: "营收",
        .foundedYear: "成立时间",
        .headquarters: "总部",
        .originalName: "中文名",
        .originalCompanyName: "中文公司名",
        .originalLocation: "中文位置",
        .profile: "档案",
        .links: "链接",
        .companyDetails: "公司详情",
        .contactDetails: "联系详情",
        .relatedCompany: "所属公司",
        .relatedCompanies: "所属公司",
        .linkNewCompany: "关联新公司",
        .linkNewContact: "关联新联系人",
        .addFromLibrary: "从图库选择",
        .takePhoto: "拍摄照片",
        .existingCompany: "已有公司",
        .existingContact: "已有联系人",
        .newInfo: "新信息",
        .discardCreateTitle: "确认放弃当前创建？",
        .discardCreateMessage: "当前填写内容将被丢弃。",
        .discardCreateAction: "放弃",
        .confirm: "确认",
        .unlinkConfirmTitle: "取消关联？",
        .unlinkConfirmMessage: "仅移除关联，不会删除档案。",
        .unlinkAction: "移除",
        .enrichAgainButton: "再次使用 AI 搜索/补全"
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
