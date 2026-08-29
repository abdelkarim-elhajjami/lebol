import Foundation
import SwiftData

@Model
final class WaterEntry {
    var id: UUID
    var date: Date
    var amountMl: Double

    init(date: Date = Date(), amountMl: Double = 250) {
        self.id = UUID()
        self.date = date
        self.amountMl = amountMl
    }
}
