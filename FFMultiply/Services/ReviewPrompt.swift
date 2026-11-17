import Foundation

/// App Store のレビュー依頼を、ハイスコアを更新したリザルトでだけ出すかを決める。
/// 最初の起動から 3 日経ち、更新を 3 回してから、1 つの版につき 1 回まで（実際に出すかはさらにシステムが決める）
enum ReviewPrompt {
    private static let firstLaunchKey = "reviewFirstLaunchDate"
    private static let achievementCountKey = "reviewAchievementCount"
    private static let requestedVersionKey = "reviewRequestedVersion"

    static let minimumDays = 3
    static let minimumAchievements = 3

    static func recordLaunch(defaults: UserDefaults = .standard, now: Date = .now) {
        if defaults.object(forKey: firstLaunchKey) == nil { defaults.set(now, forKey: firstLaunchKey) }
    }

    /// ハイスコアを更新したら呼ぶ。今レビュー依頼を出すべきなら true を返し、この版では出したことにする
    static func recordAchievement(defaults: UserDefaults = .standard, now: Date = .now) -> Bool {
        let count = defaults.integer(forKey: achievementCountKey) + 1
        defaults.set(count, forKey: achievementCountKey)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let firstLaunch = defaults.object(forKey: firstLaunchKey) as? Date ?? now
        let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: now).day ?? 0
        let requests = count >= minimumAchievements && days >= minimumDays
            && defaults.string(forKey: requestedVersionKey) != version
        if requests { defaults.set(version, forKey: requestedVersionKey) }
        return requests
    }
}
