import Foundation

/// Bölüm listesinin ViewModel'i — Flutter'daki ChapterBloc karşılığı
@Observable
final class ChapterListViewModel {
    enum State {
        case loading
        case error(String)
        case loaded([Chapter])
    }

    private(set) var state: State = .loading

    private let getChapters: GetChaptersUseCase

    init(getChapters: GetChaptersUseCase) {
        self.getChapters = getChapters
    }

    func load() async {
        state = .loading
        do {
            let chapters = try await getChapters()
            state = .loaded(chapters)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
