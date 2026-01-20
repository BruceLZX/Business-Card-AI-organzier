import Foundation
import UIKit

final class LocalStore {
    private let fileManager: FileManager
    private let baseURL: URL
    private let companiesURL: URL
    private let contactsURL: URL
    private let capturesURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = supportURL.appendingPathComponent("BusinessCardData", isDirectory: true)
        companiesURL = baseURL.appendingPathComponent("Companies", isDirectory: true)
        contactsURL = baseURL.appendingPathComponent("Contacts", isDirectory: true)
        capturesURL = baseURL.appendingPathComponent("Captures", isDirectory: true)
        createDirectoriesIfNeeded()
    }

    func loadCompanies() -> [CompanyDocument] {
        loadDocuments(from: companiesURL, fileName: "company.json")
    }

    func loadContacts() -> [ContactDocument] {
        loadDocuments(from: contactsURL, fileName: "contact.json")
    }

    func saveCompany(_ company: CompanyDocument) {
        let companyFolder = companiesURL.appendingPathComponent(company.id.uuidString, isDirectory: true)
        saveDocument(company, to: companyFolder, fileName: "company.json")
    }

    func saveContact(_ contact: ContactDocument) {
        let contactFolder = contactsURL.appendingPathComponent(contact.id.uuidString, isDirectory: true)
        saveDocument(contact, to: contactFolder, fileName: "contact.json")
    }

    func deleteCompany(_ id: UUID) {
        let url = companiesURL.appendingPathComponent(id.uuidString, isDirectory: true)
        deleteItemIfExists(at: url)
    }

    func deleteContact(_ id: UUID) {
        let url = contactsURL.appendingPathComponent(id.uuidString, isDirectory: true)
        deleteItemIfExists(at: url)
    }

    func saveCapture(_ image: UIImage) -> UUID? {
        let id = UUID()
        let url = capturesURL.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return id
        } catch {
            return nil
        }
    }

    func saveCompanyPhoto(_ image: UIImage, companyID: UUID) -> UUID? {
        let photoFolder = companiesURL
            .appendingPathComponent(companyID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
        return savePhoto(image, to: photoFolder)
    }

    func saveContactPhoto(_ image: UIImage, contactID: UUID) -> UUID? {
        let photoFolder = contactsURL
            .appendingPathComponent(contactID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
        return savePhoto(image, to: photoFolder)
    }

    func loadCapture(id: UUID) -> UIImage? {
        let url = capturesURL.appendingPathComponent("\(id.uuidString).jpg")
        return UIImage(contentsOfFile: url.path)
    }

    func loadCompanyPhoto(companyID: UUID, photoID: UUID) -> UIImage? {
        let url = companiesURL
            .appendingPathComponent(companyID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
            .appendingPathComponent("\(photoID.uuidString).jpg")
        return UIImage(contentsOfFile: url.path)
    }

    func loadContactPhoto(contactID: UUID, photoID: UUID) -> UIImage? {
        let url = contactsURL
            .appendingPathComponent(contactID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
            .appendingPathComponent("\(photoID.uuidString).jpg")
        return UIImage(contentsOfFile: url.path)
    }

    func deleteCompanyPhoto(companyID: UUID, photoID: UUID) {
        let url = companiesURL
            .appendingPathComponent(companyID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
            .appendingPathComponent("\(photoID.uuidString).jpg")
        deleteItemIfExists(at: url)
    }

    func deleteContactPhoto(contactID: UUID, photoID: UUID) {
        let url = contactsURL
            .appendingPathComponent(contactID.uuidString, isDirectory: true)
            .appendingPathComponent("photos", isDirectory: true)
            .appendingPathComponent("\(photoID.uuidString).jpg")
        deleteItemIfExists(at: url)
    }

    private func loadDocuments<T: Decodable>(from root: URL, fileName: String) -> [T] {
        guard let directoryContents = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        return directoryContents.compactMap { folder in
            let url = folder.appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }

    private func saveDocument<T: Encodable>(_ document: T, to folder: URL, fileName: String) {
        do {
            try createDirectoryIfNeeded(folder)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(document)
            let fileURL = folder.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    private func savePhoto(_ image: UIImage, to folder: URL) -> UUID? {
        let id = UUID()
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try createDirectoryIfNeeded(folder)
            let url = folder.appendingPathComponent("\(id.uuidString).jpg")
            try data.write(to: url, options: .atomic)
            return id
        } catch {
            return nil
        }
    }

    private func createDirectoriesIfNeeded() {
        do {
            try createDirectoryIfNeeded(baseURL)
            try createDirectoryIfNeeded(companiesURL)
            try createDirectoryIfNeeded(contactsURL)
            try createDirectoryIfNeeded(capturesURL)
        } catch {
            return
        }
    }

    private func createDirectoryIfNeeded(_ url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func deleteItemIfExists(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }
}
