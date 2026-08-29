import Foundation
import SwiftData

@Model
final class SupportMessage {
    var id: UUID
    var text: String
    var isFromUser: Bool
    var timestamp: Date

    init(text: String, isFromUser: Bool = true) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}
