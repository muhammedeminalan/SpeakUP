import Foundation

// Domain entity — JSON parsing datasource'ta yapılır
// neden Hashable: Router payload'larında ve Set işlemlerinde kullanılıyor
struct Word: Hashable, Identifiable {
    let id: Int
    let chapterId: String
    let turkish: String
    let english: String
}
