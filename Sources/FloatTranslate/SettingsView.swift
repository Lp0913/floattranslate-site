import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var isAccessibilityTrusted = AccessibilityPermissionManager.isTrusted
    @State private var isInputMonitoringTrusted = InputMonitoringPermissionManager.isTrusted

    var body: some View {
        Form {
            Section("快捷键") {
                Picker("翻译选中文本", selection: $settings.hotKeyChoice) {
                    ForEach(HotKeyChoice.allCases) { choice in
                        Text(choice.displayName).tag(choice)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("英文朗读") {
                Picker("默认口音", selection: $settings.englishAccent) {
                    ForEach(EnglishAccent.allCases) { accent in
                        Text(accent.displayName).tag(accent)
                    }
                }
                .pickerStyle(.segmented)
                Text("普通扬声器将使用这里选择的口音")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("辅助功能权限") {
                HStack {
                    Label(
                        isAccessibilityTrusted ? "已允许" : "尚未允许",
                        systemImage: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.circle"
                    )
                    .foregroundStyle(isAccessibilityTrusted ? Color.green : Color.secondary)
                    Spacer()
                    Button("刷新") {
                        isAccessibilityTrusted = AccessibilityPermissionManager.isTrusted
                    }
                }
                Button("打开系统设置") {
                    AccessibilityPermissionManager.requestAccess()
                    AccessibilityPermissionManager.openSystemSettings()
                }
            }

            Section("输入监控权限") {
                HStack {
                    Label(
                        isInputMonitoringTrusted ? "已允许" : "尚未允许",
                        systemImage: isInputMonitoringTrusted ? "checkmark.circle.fill" : "exclamationmark.circle"
                    )
                    .foregroundStyle(isInputMonitoringTrusted ? Color.green : Color.secondary)
                    Spacer()
                    Button("刷新") {
                        isInputMonitoringTrusted = InputMonitoringPermissionManager.isTrusted
                    }
                }
                Button("打开系统设置") {
                    InputMonitoringPermissionManager.requestAccess()
                    InputMonitoringPermissionManager.openSystemSettings()
                }
            }
        }
        .formStyle(.grouped)
        .padding(4)
        .frame(width: 420, height: 400)
    }
}
