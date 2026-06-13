import Foundation

struct Chapter: Hashable, Identifiable {
    // Dosya adından türetilir: "bolum-1"
    let id: String
    // "bolum-1" → "Bölüm 1"
    let name: String
    let words: [Word]
    let sentences: [Sentence]
}
