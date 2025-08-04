import SwiftUI

// MARK: - Quote Context Menu Actions
struct QuoteContextMenuActions {
    let onSaveScreenshot: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
}

// MARK: - Quote Context Menu Extension
extension View {
    func quoteContextMenu(
        for quote: Quote,
        actions: QuoteContextMenuActions
    ) -> some View {
        self.contextMenu {
            Button(action: actions.onSaveScreenshot) {
                Label("Save Screenshot", systemImage: "camera")
            }

            Button(action: actions.onEdit) {
                Label("Edit Quote", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive, action: actions.onDelete) {
                Label("Delete Quote", systemImage: "trash")
            }
        }
    }
}
