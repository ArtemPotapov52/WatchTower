import SwiftUI

struct AccountFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var onSave: (ServiceAccount) -> Void

    @State private var selectedType: ServiceType = .github
    @State private var accountName: String = ""
    @State private var token: String = ""
    @State private var extraToken: String = ""
    @State private var textValues: [String: String] = [:]
    @State private var listValues: [String: [String]] = [:]
    @State private var newItemInput: [String: String] = [:]

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Separator()
            formContent
            Separator()
            footer
        }
        .frame(width: 400)
        .background(colors.background)
        .onAppear {
            accountName = selectedType.rawValue
        }
    }

    private var header: some View {
        HStack {
            Text("Add Service")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                typePicker
                nameField
                let tokenFieldIndices = selectedType.configFields.enumerated().compactMap { (i, f) in
                    if case .token = f { return i }
                    return nil
                }
                ForEach(Array(selectedType.configFields.enumerated()), id: \.offset) { index, field in
                    formField(field, isSecondToken: tokenFieldIndices.count > 1 && tokenFieldIndices[1] == index)
                }
            }
            .padding(16)
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SERVICE TYPE")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(ServiceType.allCases, id: \.rawValue) { type in
                    Button {
                        selectedType = type
                        accountName = type.rawValue
                        token = ""
                        extraToken = ""
                        textValues = [:]
                        listValues = [:]
                        newItemInput = [:]
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            Text(type.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundStyle(selectedType == type ? colors.textPrimary : colors.textTertiary)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedType == type ? Color(white: 0.5).opacity(0.08) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedType == type ? colors.border : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAME")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)
            TextField("Account name", text: $accountName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(colors.textPrimary)
                .frame(height: 32)
                .padding(.horizontal, 10)
                .background(.quaternary.opacity(0.15))
                .cornerRadius(6)
        }
    }

    @ViewBuilder
    private func formField(_ field: ConfigField, isSecondToken: Bool = false) -> some View {
        switch field {
        case .token(let placeholder, let label):
            tokenField(label: label, placeholder: placeholder, text: isSecondToken ? $extraToken : $token)
        case .text(let label, let placeholder, let key):
            textField(label: label, placeholder: placeholder, key: key)
        case .list(let label, let placeholder, let key):
            listField(label: label, placeholder: placeholder, key: key)
        }
    }

    private func tokenField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)
            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(colors.textPrimary)
                .frame(height: 32)
                .padding(.horizontal, 10)
                .background(.quaternary.opacity(0.15))
                .cornerRadius(6)
        }
    }

    private func textField(label: String, placeholder: String, key: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)
            TextField(placeholder, text: Binding(
                get: { textValues[key, default: ""] },
                set: { textValues[key] = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(colors.textPrimary)
            .frame(height: 32)
            .padding(.horizontal, 10)
            .background(.quaternary.opacity(0.15))
            .cornerRadius(6)
        }
    }

    private func listField(label: String, placeholder: String, key: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)

            let items = listValues[key, default: []]
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    Text(items[index])
                        .font(.system(size: 11))
                        .foregroundStyle(colors.textSecondary)
                    Spacer()
                    Button {
                        listValues[key]?.remove(at: index)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(.quaternary.opacity(0.1))
                .cornerRadius(4)
            }

            HStack {
                TextField(placeholder, text: Binding(
                    get: { newItemInput[key, default: ""] },
                    set: { newItemInput[key] = $0 }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(colors.textTertiary)
                .onSubmit { addItem(for: key) }

                Button {
                    addItem(for: key)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 32)
            .padding(.horizontal, 10)
            .background(.quaternary.opacity(0.15))
            .cornerRadius(6)
        }
    }

    private func addItem(for key: String) {
        let val = (newItemInput[key] ?? "").trimmingCharacters(in: .whitespaces)
        guard !val.isEmpty else { return }
        var items = listValues[key, default: []]
        items.append(val)
        listValues[key] = items
        newItemInput[key] = ""
    }

    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(colors.textSecondary)

            Spacer()

            Button {
                var account = ServiceAccount.empty(selectedType)
                account.name = accountName
                account.token = token
                account.extraToken = extraToken
                account.textValues = textValues
                account.listValues = listValues
                onSave(account)
            } label: {
                Text("Add Service")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(height: 32)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0x0A0A0A))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
