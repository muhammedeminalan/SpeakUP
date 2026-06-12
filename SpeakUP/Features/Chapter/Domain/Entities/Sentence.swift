import Foundation

struct Sentence: Hashable, Identifiable {
    let id: Int
    // Doğal Türkçe — kullanıcıya gösterilen: "Ben hayvanları çok severim."
    let turkish: String
    // Devrik yapı — fiil öne alınmış: "Ben severim hayvanları çok."
    let turkishRestructured: String
    let english: String
}
