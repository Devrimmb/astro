import SwiftUI

/// Cam segment kontrolü — seçili hap `matchedGeometryEffect` ile kayar.
/// Sistem `Picker(.segmented)` koyu cam zeminde uyumsuz kaldığı için özel.
struct SegmentedGlass<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(.caption.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .white : AstroTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .overlay {
                                        Capsule().stroke(
                                            LinearGradient(
                                                colors: [AstroTheme.cardSpecular, .clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            ),
                                            lineWidth: 1
                                        )
                                    }
                                    .matchedGeometryEffect(id: "pill", in: pillNamespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(.white.opacity(0.05))
                .overlay { Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1) }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Alt sheet'ler için ortak sunum: yarım/tam detent, cam zemin, 28pt köşe.
struct AstroSheetStyle: ViewModifier {
    var detents: Set<PresentationDetent> = [.fraction(0.7), .large]

    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    AstroTheme.background.opacity(0.78)
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func astroSheetStyle(detents: Set<PresentationDetent> = [.fraction(0.7), .large]) -> some View {
        modifier(AstroSheetStyle(detents: detents))
    }
}
