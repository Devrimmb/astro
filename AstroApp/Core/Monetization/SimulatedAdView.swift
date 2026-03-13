import SwiftUI

struct SimulatedAdView: View {
    @State private var countdown = 5
    @State private var timer: Timer?
    var onComplete: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse)

                Text("Test Reklam")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Bu bir simüle reklamdır.\nGerçek cihazda Google AdMob reklamı gösterilecektir.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                if countdown > 0 {
                    Text("Ödül için bekleyin: \(countdown)s")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: .capsule)
                } else {
                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Ödülü Al")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.yellow, in: .capsule)
                    }
                }

                HStack {
                    Spacer()
                    if countdown <= 0 {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if countdown > 0 {
                    countdown -= 1
                }
                if countdown == 0 {
                    timer?.invalidate()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}
