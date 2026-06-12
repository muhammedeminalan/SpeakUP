import Foundation

/// "Yanlışları Tekrar Et" için kelime seti üretir.
/// Öncelik sırası: yanlışlar → hiç denenmemişler → öğrenilenler
struct RetryWordSetBuilder {
    func build(
        chapterWords: [Word],
        prioritizedWordIds: Set<Int>,
        attemptedWordIds: Set<Int>,
        targetCount: Int
    ) -> [Word] {
        guard !chapterWords.isEmpty, targetCount > 0 else { return [] }

        let safeTarget = min(max(targetCount, 1), chapterWords.count)
        let prioritized = chapterWords.filter { prioritizedWordIds.contains($0.id) }
        let unknown = chapterWords.filter {
            !attemptedWordIds.contains($0.id) && !prioritizedWordIds.contains($0.id)
        }
        let learned = chapterWords.filter {
            attemptedWordIds.contains($0.id) && !prioritizedWordIds.contains($0.id)
        }

        var result = prioritized
        if result.count < safeTarget {
            result.append(contentsOf: unknown.prefix(safeTarget - result.count))
        }
        if result.count < safeTarget {
            result.append(contentsOf: learned.prefix(safeTarget - result.count))
        }
        return Array(result.prefix(safeTarget))
    }
}
