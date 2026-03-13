import SwiftUI

/// Markdown formatlı tarot yorumlarını okunaklı şekilde gösterir.
struct MarkdownTextView: View {
    let markdown: String

    init(_ markdown: String) {
        self.markdown = markdown
    }

    var body: some View {
        Text(attributedString)
            .font(.subheadline)
            .foregroundStyle(AstroTheme.textSecondary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tint(AstroTheme.accent)
    }

    private var attributedString: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
    }
}
