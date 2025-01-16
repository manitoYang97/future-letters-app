import SwiftUI
import Combine

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
}
