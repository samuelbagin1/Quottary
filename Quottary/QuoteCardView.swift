import SwiftUI
import SQLite3
import Foundation


// MARK: - Quote Card View
struct QuoteCardView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.quoteText)
                .foregroundColor(Color("blackColor"))
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.authorText)
                    .foregroundColor(Color("grayColor"))
            }
        }
        .padding()
        .cornerRadius(10)
    }
}



// MARK: - Preview
struct QuoteCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        QuoteCardView(quote: Quote(id: 122, text: "The only way to do great work is to love what you do.", author: "Steve Jobs", dateCreated: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15, hour: 10, minute: 30))!))
    }
}
