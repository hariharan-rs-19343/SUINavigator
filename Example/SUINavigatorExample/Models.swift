import Foundation

struct Product: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let emoji: String
    let blurb: String

    static let samples: [Product] = [
        Product(id: 1, name: "Aurora Headphones", emoji: "🎧", blurb: "Spatial audio with a 40-hour battery."),
        Product(id: 2, name: "Halo Smart Watch", emoji: "⌚️", blurb: "Always-on display, ECG, GPS."),
        Product(id: 3, name: "Pebble Speaker", emoji: "🔊", blurb: "Pocket-sized, room-filling sound.")
    ]
}
