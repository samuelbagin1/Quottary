import SwiftUI
import UIKit
import Photos

// MARK: - Screenshot Manager
class ScreenshotManager: ObservableObject {

    static let shared = ScreenshotManager()

    private init() {}

    @MainActor
    func saveQuoteScreenshot(quote: Quote, completion: @escaping (Bool, String) -> Void) {
        // Check photo library permission first
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            performScreenshotSave(quote: quote, completion: completion)
        case .denied, .restricted:
            completion(false, "Photo library access denied. Please enable it in Settings.")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.performScreenshotSave(quote: quote, completion: completion)
                    } else {
                        completion(false, "Photo library access is required to save screenshots.")
                    }
                }
            }
        @unknown default:
            completion(false, "Unknown photo library authorization status.")
        }
    }

    @MainActor
    private func performScreenshotSave(quote: Quote, completion: @escaping (Bool, String) -> Void) {
        let renderer = ImageRenderer(content: QuoteScreenshotView(quote: quote))

        // Set the size to be square (1:1 aspect ratio)
        renderer.proposedSize = .init(width: 400, height: 500)

        guard let uiImage = renderer.uiImage else {
            completion(false, "Failed to create screenshot image.")
            return
        }

        // Save to photo library
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Screenshot saved to Photos!")
                } else {
                    completion(false, error?.localizedDescription ?? "Failed to save screenshot.")
                }
            }
        }
    }
}

// MARK: - Quote Screenshot View
struct QuoteScreenshotView: View {
    let quote: Quote

    var body: some View {
        ZStack {

            VStack(spacing: 6) {
                Spacer()

                VStack(spacing: 12) {

                    Text("\"\(quote.text)\"")
                        .font(.instrumentSerif(size: 40, italic: true))
                        .foregroundColor(Color("blackColor"))
                        .multilineTextAlignment(.leading)

                    HStack {
                        Spacer()
                        Text("— \(quote.author)")
                            .font(.instrumentSerif(size: 35, italic: true))
                            .foregroundColor(Color("grayColor"))
                    }

                }.padding(60)

                Spacer()

                // App title in bottom left corner
                HStack {
                    Text("Quottary")
                        .font(.instrumentSerif(size: 30, italic: false))
                        .foregroundColor(Color("grayColor"))

                    Spacer()
                }.padding(10)
            }
        }
        .frame(width: 1080, height: 1350)
        .padding(30)
        .background(Color("whiteColor"))
    }
}


#Preview {
    QuoteScreenshotView(quote: Quote(id: 122, text: "The only way to do great work is to love what you do. aaaaaaaaaaaaaaaaa", author: "Steve Jobs", dateCreated: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15, hour: 10, minute: 30))!))
}
