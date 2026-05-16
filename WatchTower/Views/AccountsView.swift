import SwiftUI

struct AccountsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var state

    @State private var selectedAccount: ServiceAccount?
    @State private var showAddSheet = false

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        HStack(spacing: 0) {
            listPanel
            Separator()
                .frame(width: 1)
            detailPanel
        }
    }

    private var listPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CONNECTED SERVICES")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(colors.textTertiary)
                    .tracking(0.5)
                Spacer()
                Text("\(state.accounts.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(state.accounts) { account in
                        accountRow(account)
                    }
                }
                .padding(.horizontal, 8)
            }

            Separator()

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Add Service")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(colors.textSecondary)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(colors.surface)
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 260)
        .background(colors.surface)
        .sheet(isPresented: $showAddSheet) {
            AccountFormView { account in
                state.addAccount(account)
                selectedAccount = account
                showAddSheet = false
            }
        }
    }

    private func accountRow(_ account: ServiceAccount) -> some View {
        Button {
            selectedAccount = account
        } label: {
            HStack(spacing: 10) {
                Image(systemName: account.serviceType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(account.isEnabled ? colors.textPrimary : colors.textTertiary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    Text(account.serviceType.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(colors.textTertiary)
                }

                Spacer()

                statusDot(for: account)
            }
            .frame(height: 40)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedAccount?.id == account.id ? Color(white: 0.5).opacity(0.08) : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusDot(for account: ServiceAccount) -> some View {
        let items = state.sectionItems[account.id.uuidString] ?? []
        let hasIssues = items.contains { $0.status == .danger || $0.status == .warning }
        let isLoading = state.sectionStates[account.id.uuidString] == .loading

        if isLoading {
            return Circle()
                .fill(AppColors.neutral)
                .frame(width: 6, height: 6)
        }
        return Circle()
            .fill(hasIssues ? AppColors.danger : AppColors.success)
            .frame(width: 6, height: 6)
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let account = selectedAccount {
            AccountDetailView(account: account) { updated in
                state.updateAccount(updated)
                selectedAccount = updated
            } onDelete: {
                state.deleteAccount(account)
                selectedAccount = state.accounts.first
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "link")
                    .font(.system(size: 28))
                    .foregroundStyle(colors.textTertiary)
                Text("Select or add a service")
                    .font(.system(size: 13))
                    .foregroundStyle(colors.textTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Account Detail

struct AccountDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    let account: ServiceAccount
    var onUpdate: (ServiceAccount) -> Void
    var onDelete: () -> Void

    @State private var editAccount: ServiceAccount
    @State private var newListItemInput: [String: String] = [:]

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    init(account: ServiceAccount, onUpdate: @escaping (ServiceAccount) -> Void, onDelete: @escaping () -> Void) {
        self.account = account
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editAccount = State(initialValue: account)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                configSection
                actionsSection
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: account.id) { _, _ in
            editAccount = account
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: account.serviceType.icon)
                .font(.system(size: 20))
                .foregroundStyle(colors.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                TextField("Name", text: $editAccount.name)
                    .font(.system(size: 15, weight: .medium))
                    .textFieldStyle(.plain)
                    .foregroundStyle(colors.textPrimary)

                Text(account.serviceType.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $editAccount.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: editAccount.isEnabled) { _, _ in
                    onUpdate(editAccount)
                }
        }
    }

    @ViewBuilder
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CONFIGURATION")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(account.serviceType.configFields.enumerated()), id: \.offset) { _, field in
                    configField(field)
                    if field.key != account.serviceType.configFields.last?.key {
                        Separator()
                    }
                }
            }
            .background(.quaternary.opacity(0.15))
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func configField(_ field: ConfigField) -> some View {
        switch field {
        case .token(let placeholder, let label):
            tokenRow(label: label, placeholder: placeholder, text: $editAccount.token)
        case .text(let label, let placeholder, let key):
            textRow(label: label, placeholder: placeholder, text: binding(for: key))
        case .list(let label, let placeholder, let key):
            listRow(label: label, placeholder: placeholder, items: listBinding(for: key), key: key)
        }
    }

    private func tokenRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(colors.textPrimary)
                .frame(width: 100, alignment: .leading)
            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(colors.textSecondary)
            Button {
                onUpdate(editAccount)
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.success)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }

    private func textRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(colors.textPrimary)
                .frame(width: 100, alignment: .leading)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(colors.textSecondary)
            Button {
                onUpdate(editAccount)
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.success)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }

    private func listRow(label: String, placeholder: String, items: Binding<[String]>, key: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(colors.textPrimary)
                    .frame(width: 100, alignment: .leading)
                Spacer()
            }
            .frame(height: 36)
            .padding(.horizontal, 12)

            ForEach(items.wrappedValue.indices, id: \.self) { index in
                HStack {
                    Text(items.wrappedValue[index])
                        .font(.system(size: 11))
                        .foregroundStyle(colors.textSecondary)
                    Spacer()
                    Button {
                        items.wrappedValue.remove(at: index)
                        onUpdate(editAccount)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            HStack {
                TextField(placeholder, text: Binding(
                    get: { newListItemInput[key, default: ""] },
                    set: { newListItemInput[key] = $0 }
                ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(colors.textTertiary)
                    .onSubmit { addItemToList(for: key) }
                Button {
                    addItemToList(for: key)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 36)
            .padding(.horizontal, 12)
        }
    }

    private func addItemToList(for key: String) {
        let val = (newListItemInput[key] ?? "").trimmingCharacters(in: .whitespaces)
        guard !val.isEmpty else { return }
        var items = editAccount.listValues[key, default: []]
        items.append(val)
        editAccount.listValues[key] = items
        newListItemInput[key] = ""
        onUpdate(editAccount)
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { editAccount.textValues[key, default: ""] },
            set: { editAccount.textValues[key] = $0 }
        )
    }

    private func listBinding(for key: String) -> Binding<[String]> {
        Binding(
            get: { editAccount.listValues[key, default: []] },
            set: { editAccount.listValues[key] = $0 }
        )
    }

    private var actionsSection: some View {
        HStack {
            Button {
                onUpdate(editAccount)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Refresh")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(colors.textPrimary)
                .frame(height: 32)
                .padding(.horizontal, 14)
                .background(colors.surface)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Delete")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(AppColors.danger)
                .frame(height: 32)
                .padding(.horizontal, 14)
                .background(AppColors.danger.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - ConfigField key helper

extension ConfigField {
    var key: String {
        switch self {
        case .token: return "token"
        case .text(_, _, let k): return k
        case .list(_, _, let k): return k
        }
    }
}
