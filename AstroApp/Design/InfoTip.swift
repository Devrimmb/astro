import SwiftUI

/// Hafif bilgi tooltip'i — "?" ikonuna dokunulunca alt sheet ile açıklama gösterir.
struct InfoTip: View {
    let title: String
    let message: String
    @State private var isShowing = false

    var body: some View {
        Button {
            isShowing = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .sheet(isPresented: $isShowing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AstroTheme.accent)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(red: 0.06, green: 0.07, blue: 0.14))
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }
}

/// Başlık satırına "?" eklemek için yardımcı
struct SectionHeaderWithInfo: View {
    let title: String
    let icon: String
    let color: Color
    let tipTitle: String
    let tipMessage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            InfoTip(title: tipTitle, message: tipMessage)
            Spacer()
        }
    }
}
