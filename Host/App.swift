import SwiftUI

@main
struct GlassKeyboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用步骤")
                    .font(.headline)
                Text("""
                1. 设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 玻璃键盘
                2. 在输入框里点地球键切换到玻璃键盘
                3. 回到这里试试下面的输入框
                """)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextEditor(text: $text)
                    .frame(minHeight: 160)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))

                Spacer()
            }
            .padding()
            .navigationTitle("玻璃键盘")
        }
    }
}
