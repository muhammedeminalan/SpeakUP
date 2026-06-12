import Foundation

/// Quiz sayfalarında swipe-back geçmişini yönetir.
/// Generic Snapshot: WordQuizQuestionState veya SentenceQuestionState.
/// ViewModel'e dokunmaz — tamamen UI navigasyon state'i.
@Observable
final class QuizHistory<Snapshot> {
    /// Cevaplanan soruların snapshot'ları
    private(set) var history: [Snapshot] = []

    /// 0 = aktif soru, >0 = geçmişten kaç soru geri
    private(set) var historyOffset = 0

    /// neden: cevap verilince snapshot tutulur, yeni soru gelince history'e eklenir
    private var pendingSnapshot: Snapshot?

    var isInHistory: Bool { historyOffset > 0 }

    /// Geçmişte görüntülenen soruyu döner, nil ise aktif soru gösterilmeli
    var historyItem: Snapshot? {
        isInHistory ? history[history.count - historyOffset] : nil
    }

    var canGoBack: Bool { historyOffset < history.count }

    /// Cevap verilince çağrılır — snapshot bekletilir
    func onAnswered(_ snapshot: Snapshot) {
        guard historyOffset == 0 else { return }
        pendingSnapshot = snapshot
    }

    /// Yeni soru gelince çağrılır — bekleyen snapshot history'e eklenir
    func onNewQuestion() {
        guard let pending = pendingSnapshot else { return }
        history.append(pending)
        pendingSnapshot = nil
        historyOffset = 0
    }

    /// Sola swipe: geçmişte ileri git
    func goForwardInHistory() {
        guard isInHistory else { return }
        historyOffset -= 1
    }

    /// Sağa swipe: geçmişe geri git
    func goBack() {
        guard canGoBack else { return }
        historyOffset += 1
    }
}
