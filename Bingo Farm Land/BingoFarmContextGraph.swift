import SwiftUI
import UIKit
import WebKit

// MARK: - Протоколы и расширения

/// Протокол для создания градиентных представлений
protocol GradientProviding {
    func createGradientLayer() -> CAGradientLayer
}

// MARK: - Улучшенный контейнер с градиентом

/// Кастомный контейнер с градиентным фоном
final class GradientContainerView: UIView, GradientProviding {
    // MARK: - Приватные свойства

    private let gradientLayer = CAGradientLayer()

    // MARK: - Инициализаторы

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Методы настройки

    private func setupView() {
        layer.insertSublayer(createGradientLayer(), at: 0)
    }

    /// Создание градиентного слоя
    func createGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#1BD8FD").cgColor,
            UIColor(hex: "#0FC9FA").cgColor,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }

    // MARK: - Обновление слоя

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - Расширения для цветов

extension UIColor {
    /// Инициализатор цвета из HEX-строки с улучшенной обработкой
    convenience init(hex hexString: String) {
        let sanitizedHex =
            hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        var colorValue: UInt64 = 0
        Scanner(string: sanitizedHex).scanHexInt64(&colorValue)

        let redComponent = CGFloat((colorValue & 0xFF0000) >> 16) / 255.0
        let greenComponent = CGFloat((colorValue & 0x00FF00) >> 8) / 255.0
        let blueComponent = CGFloat(colorValue & 0x0000FF) / 255.0

        self.init(red: redComponent, green: greenComponent, blue: blueComponent, alpha: 1.0)
    }
}

// MARK: - Представление веб-вида

struct BingoFarmWebViewBox: UIViewControllerRepresentable {
    // MARK: - Свойства

    @ObservedObject var loader: BingoFarmWebLoader
    var defaultOrientations: UIInterfaceOrientationMask = .landscape

    // MARK: - Координатор

    func makeCoordinator() -> BingoFarmWebCoordinator {
        BingoFarmWebCoordinator { [weak loader] status in
            loader?.publish(status)
        }
    }

    // MARK: - Создание представления

    func makeUIViewController(context: Context) -> BingoFarmBaseWebViewController {
        let configuration = createWebViewConfiguration()
        return BingoFarmBaseWebViewController(
            defaultOrientations: defaultOrientations,
            loader: loader,
            coordinator: context.coordinator,
            configuration: configuration
        )
    }

    func updateUIViewController(_ uiViewController: BingoFarmBaseWebViewController, context: Context) {
        // Left intentionally blank; loader drives updates.
    }

    // MARK: - Приватные методы настройки

    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        // Включаем поддержку медиа-функций
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Настройки для доступа к камере и микрофону
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        // Additional tuning for smoother loading
        configuration.suppressesIncrementalRendering = false

        return configuration
    }
}

// MARK: - Расширение для типов данных

extension String {
    static let diskCache = WKWebsiteDataTypeDiskCache
    static let memoryCache = WKWebsiteDataTypeMemoryCache
    static let cookies = WKWebsiteDataTypeCookies
    static let localStorage = WKWebsiteDataTypeLocalStorage
}
