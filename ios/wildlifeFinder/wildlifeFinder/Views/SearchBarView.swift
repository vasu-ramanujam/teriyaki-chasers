import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    var onSubmit: () -> Void
    var onChange: (String) -> Void
    var onClear: () -> Void
    var suggestions: [String]
    var onPickSuggestion: (String) -> Void
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "line.3.horizontal")

                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onChange(of: text) { _, newValue in
                        onChange(newValue)
                    }
                    .onSubmit { onSubmit() }

                if !text.isEmpty {
                    Button(action: { onClear() }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "magnifyingglass")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { s in
                        Button(action: { onPickSuggestion(s) }) {
                            HStack { Text(s); Spacer() }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)

                        if s != suggestions.last { Divider() }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
            }
        }
        .onTapGesture {
            isFocused.toggle()
        }
    }
}
