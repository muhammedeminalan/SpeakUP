import Foundation

/// Yarıda bırakılan quiz oturumlarını bellekte tutar.
/// neden @Observable: dashboard "Devam Et" bölümü oturum değişince anında güncellensin
@Observable
final class QuizSessionStore {
    private(set) var wordSession: WordQuizSession?
    private(set) var sentenceSession: SentenceBuilderSession?

    func wordSession(forChapter chapterId: String) -> WordQuizSession? {
        guard let session = wordSession, session.chapterId == chapterId else { return nil }
        return session
    }

    func sentenceSession(forChapter chapterId: String) -> SentenceBuilderSession? {
        guard let session = sentenceSession, session.chapterId == chapterId else { return nil }
        return session
    }

    func saveWordSession(_ session: WordQuizSession) {
        wordSession = session
    }

    func saveSentenceSession(_ session: SentenceBuilderSession) {
        sentenceSession = session
    }

    func clearWordSession(chapterId: String? = nil) {
        guard wordSession != nil else { return }
        if let chapterId, wordSession?.chapterId != chapterId { return }
        wordSession = nil
    }

    func clearSentenceSession(chapterId: String? = nil) {
        guard sentenceSession != nil else { return }
        if let chapterId, sentenceSession?.chapterId != chapterId { return }
        sentenceSession = nil
    }
}
