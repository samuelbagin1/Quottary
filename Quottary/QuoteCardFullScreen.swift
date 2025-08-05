import SwiftUI

/// A fullscreen card displaying a quote. Tapping anywhere or swiping down will dismiss the view.
struct QuoteCardFullScreen: View {
    let quote: Quote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {

            VStack(spacing: 10) {
                Text("Quottary")
                    .font(.sectionTitle)
                    .foregroundColor(Color("grayColor"))

                VStack(spacing: 6) {
                    Text("\"\(quote.text)\"")
                        .font(.quoteText)
                        .foregroundColor(Color("blackColor"))
                        .multilineTextAlignment(.center)

                    Text(quote.author)
                        .font(.authorText)
                        .foregroundColor(Color("grayColor"))
                }
            }.padding(20)

            VStack {
                Spacer()
                Text("Tap anywhere or swipe down to dismiss")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color("grayColor").opacity(0.5))
                    .padding(.bottom, 10)
            }
        }
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                dismiss()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { gesture in
                    // Dismiss on swipe down (or up, if you want both directions)
                    if gesture.translation.height > 80 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dismiss()
                        }
                    }
                }
        )
    }

}


#Preview {
    QuoteCardFullScreen(
        quote: Quote(
            id: 122,
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            dateCreated: Calendar.current.date(
                from: DateComponents(
                    year: 2024,
                    month: 7,
                    day: 15,
                    hour: 10,
                    minute: 30
                )
            )!
        )
    )
}
