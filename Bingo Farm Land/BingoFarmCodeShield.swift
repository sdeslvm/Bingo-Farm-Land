import Combine
import SwiftUI
import WebKit

// MARK: - Протоколы

/// Протокол для управления состоянием веб-загрузки
protocol WebLoadable: AnyObject {
    var state: BingoFarmWebStatus { get set }
    func setConnectivity(_ available: Bool)
}

/// Протокол для мониторинга прогресса загрузки
protocol ProgressMonitoring {
    func observeProgression()
    func monitor(_ webView: WKWebView)
}

// MARK: - Основной загрузчик веб-представления

/// Класс для управления загрузкой и состоянием веб-представления
final class BingoFarmWebLoader: NSObject, ObservableObject, WebLoadable, ProgressMonitoring {
    // MARK: - Свойства

  @Published var state: BingoFarmWebStatus = .standby

    let resource: URL
    private var cancellables = Set<AnyCancellable>()
    private var progressPublisher = PassthroughSubject<Double, Never>()
    private var webViewProvider: (() -> WKWebView)?

    // MARK: - Инициализация

    init(resourceURL: URL) {
        self.resource = resourceURL
        super.init()
        observeProgression()
    }

    // MARK: - Публичные методы

    /// Привязка веб-представления к загрузчику
    func attachWebView(factory: @escaping () -> WKWebView) {
        webViewProvider = factory
        triggerLoad()
    }

    /// Установка доступности подключения
    func setConnectivity(_ available: Bool) {
        switch (available, state) {
        case (true, .noConnection):
            triggerLoad()
        case (false, _):
            publish(.noConnection)
        default:
            break
        }
    }

    // MARK: - Приватные методы загрузки

    /// Запуск загрузки веб-представления
    private func triggerLoad() {
        guard let webView = webViewProvider?() else { return }

        let request = URLRequest(url: resource, timeoutInterval: 12)
        publish(.progressing(progress: 0))

        webView.navigationDelegate = self
        webView.load(request)
        monitor(webView)
    }

    // MARK: - Методы мониторинга

    /// Наблюдение за прогрессом загрузки
    func observeProgression() {
        progressPublisher
            .removeDuplicates()
            .sink { [weak self] progress in
                guard let self else { return }
                let newState: BingoFarmWebStatus = progress < 1.0 ? .progressing(progress: progress) : .finished
                self.publish(newState)
            }
            .store(in: &cancellables)
    }

    /// Мониторинг прогресса веб-представления
    func monitor(_ webView: WKWebView) {
        webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                self?.progressPublisher.send(progress)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Расширение для обработки навигации

extension BingoFarmWebLoader: WKNavigationDelegate {
    /// Обработка ошибок при навигации
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    /// Обработка ошибок при provisional навигации
    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handleNavigationError(error)
    }

    // MARK: - Приватные методы обработки ошибок

    /// Обобщенный метод обработки ошибок навигации
    private func handleNavigationError(_ error: Error) {
        publish(.failure(reason: error.localizedDescription))
    }
}

// MARK: - Расширения для улучшения функциональности

extension BingoFarmWebLoader {
    /// Создание загрузчика с безопасным URL
    convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(resourceURL: url)
    }

    func publish(_ newState: BingoFarmWebStatus) {
        updateState(newState)
    }
}

// MARK: - Private helpers

private extension BingoFarmWebLoader {
    func updateState(_ newState: BingoFarmWebStatus) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }
}
