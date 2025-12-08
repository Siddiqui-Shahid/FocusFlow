import SwiftUI

struct CapsuleButton: View {
    let title: String
    let action: () -> Void
    var filled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(filled ? Color(.systemBlue) : Color.white)
                .foregroundStyle(filled ? Color.white : .secondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray4), lineWidth: filled ? 0 : 1)
                )
                .cornerRadius(20)
        }
    }
}

#if DEBUG
struct CapsuleButton_Previews: PreviewProvider {
    static var previews: some View {
        CapsuleButton(title: "Pomodoro 25m", action: {}, filled: true)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
