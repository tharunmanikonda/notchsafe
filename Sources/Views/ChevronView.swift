import SwiftUI

struct ChevronView: View {
    let onTap: () -> Void
    @State private isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.7))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
