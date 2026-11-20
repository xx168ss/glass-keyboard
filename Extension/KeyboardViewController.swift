import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {

    private var host: UIHostingController<GlassKeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let model = KeyboardModel(
            insert: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            delete: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
            },
            switchKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            }
        )

        let host = UIHostingController(rootView: GlassKeyboardView(model: model))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host

        let height = view.heightAnchor.constraint(equalToConstant: 260)
        height.priority = .defaultHigh
        height.isActive = true
    }
}

@MainActor
final class KeyboardModel: ObservableObject {
    @Published var shift = true
    let insert: (String) -> Void
    let delete: () -> Void
    let switchKeyboard: () -> Void

    init(insert: @escaping (String) -> Void,
         delete: @escaping () -> Void,
         switchKeyboard: @escaping () -> Void) {
        self.insert = insert
        self.delete = delete
        self.switchKeyboard = switchKeyboard
    }

    func tapLetter(_ ch: String) {
        insert(shift ? ch.uppercased() : ch)
        if shift { shift = false }
    }
}

struct GlassKeyboardView: View {
    @ObservedObject var model: KeyboardModel

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        VStack(spacing: 9) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 7) {
                    if index == 2 {
                        KeyCap(title: "⇧") { model.shift.toggle() }
                    }
                    ForEach(Array(row.enumerated()), id: \.offset) { _, ch in
                        KeyCap(title: model.shift ? String(ch).uppercased() : String(ch)) {
                            model.tapLetter(String(ch))
                        }
                    }
                    if index == 2 {
                        KeyCap(title: "⌫") { model.delete() }
                    }
                }
                .frame(height: 50)
            }
            HStack(spacing: 7) {
                KeyCap(title: "地球") { model.switchKeyboard() }
                KeyCap(title: ",") { model.insert("，") }
                KeyCap(title: "空格") { model.insert(" ") }
                KeyCap(title: "。") { model.insert("。") }
                KeyCap(title: "⏎") { model.insert("\n") }
            }
            .frame(height: 50)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 9)
    }
}

struct KeyCap: View {
    let title: String
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .regular))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            .scaleEffect(pressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: pressed)
            .onLongPressGesture(minimumDuration: 0, pressing: { isDown in
                pressed = isDown
            }, perform: {})
            .onTapGesture { action() }
    }
}
