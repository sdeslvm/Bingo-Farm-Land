import Foundation
import SwiftUI

struct BingoFarmEntryScreen: View {
    @StateObject private var loader: BingoFarmWebLoader

    init(loader: BingoFarmWebLoader) {
        _loader = StateObject(wrappedValue: loader)
    }

    var body: some View {
        ZStack {
            BingoFarmWebViewBox(loader: loader)
                .opacity(loader.state == .finished ? 1 : 0.5)
            switch loader.state {
            case .progressing(let percent):
                BingoFarmProgressIndicator(value: percent)
            case .failure(let err):
                BingoFarmErrorIndicator(err: err)  // err теперь String
            case .noConnection:
                BingoFarmOfflineIndicator()
            default:
                EmptyView()
            }
        }
    }
}

private struct BingoFarmProgressIndicator: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            BingoFarmLoadingOverlay(progress: value)
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black)
        }
    }
}

private struct BingoFarmErrorIndicator: View {
    let err: String  // было Error, стало String
    var body: some View {
        Text("Ошибка: \(err)").foregroundColor(.red)
    }
}

private struct BingoFarmOfflineIndicator: View {
    var body: some View {
        Text("Нет соединения").foregroundColor(.gray)
    }
}
