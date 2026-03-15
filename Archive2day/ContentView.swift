import SwiftUI

struct ContentView: View {
    @State private var urlInput: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "#0A0F0A").ignoresSafeArea()

            // Subtle grid texture
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 40
                    let color = Color.white.opacity(0.025)
                    var x: CGFloat = 0
                    while x < size.width {
                        ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) }, with: .color(color), lineWidth: 1)
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(color), lineWidth: 1)
                        y += spacing
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color(hex: "#4ADE80"))
                        Text("Archive2day")
                            .font(.custom("Georgia-Bold", size: 30))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 64)

                    Text("Instant archive.today lookup")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#4A5A4A"))
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .padding(.bottom, 44)

                // How to use card
                VStack(alignment: .leading, spacing: 14) {
                    Label("How to use", systemImage: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ADE80"))
                        .textCase(.uppercase)
                        .tracking(1)

                    VStack(alignment: .leading, spacing: 10) {
                        StepRow(n: "1", text: "Open any webpage in Safari or another browser")
                        StepRow(n: "2", text: "Tap Share → Archive2day")
                        StepRow(n: "3", text: "Safari opens the archived version — or asks if you want to create one")
                    }
                }
                .padding(20)
                .background(Color(hex: "#111811"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#1E2E1E"), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                // Manual input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Or paste a URL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#3A4A3A"))
                        .textCase(.uppercase)
                        .tracking(1)
                        .padding(.horizontal, 24)

                    HStack(spacing: 0) {
                        TextField("https://example.com/article...", text: $urlInput)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .focused($fieldFocused)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                        Button(action: lookupURL) {
                            if isLoading {
                                ProgressView().tint(.white).scaleEffect(0.8).frame(width: 52, height: 52)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 52, height: 52)
                            }
                        }
                        .background(Color(hex: "#4ADE80").opacity(urlInput.isEmpty ? 0.4 : 1))
                        .disabled(urlInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .background(Color(hex: "#111811"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(fieldFocused ? Color(hex: "#4ADE80").opacity(0.5) : Color(hex: "#1E2E1E"), lineWidth: 1))
                    .padding(.horizontal, 24)
                }

                if let err = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(err)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(hex: "#F87171"))
                    .padding(.top, 14)
                    .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Powered by archive.today")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#2A3A2A"))
                    Text("Not affiliated with archive.today")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#1E2E1E"))
                }
                .padding(.bottom, 32)
            }
        }
    }

    func lookupURL() {
        fieldFocused = false
        errorMessage = nil
        isLoading = true

        let trimmed = urlInput.trimmingCharacters(in: .whitespaces)
        guard URL(string: trimmed) != nil else {
            isLoading = false
            errorMessage = "That doesn't look like a valid URL."
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isLoading = false
            if let url = URLCleaner.archiveSearchURL(for: trimmed) {
                UIApplication.shared.open(url)
            } else {
                errorMessage = "Couldn't build archive.today URL."
            }
        }
    }
}

struct StepRow: View {
    let n: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#4ADE80"))
                .frame(width: 20, height: 20)
                .background(Color(hex: "#4ADE80").opacity(0.1))
                .cornerRadius(4)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8A9A8A"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview {
    ContentView()
}
