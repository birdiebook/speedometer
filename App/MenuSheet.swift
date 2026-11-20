import SwiftUI

/// BESLUT B14: the small sheet behind the menu icon. Its one row opens Trail (BESLUT B16); measurements in FORM.md.
struct MenuSheet: View {
    let onTrail: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTrail) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trail")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.primary)
                        Text("This ride, drawn by speed")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.label)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.minorTick)
                }
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.sheet)
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        MenuSheet(onTrail: {})
    }
}
