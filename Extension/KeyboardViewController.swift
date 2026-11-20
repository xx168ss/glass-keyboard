import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {

    private var host: UIHostingController<GlassKeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false

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
        host.view.isOpaque = false
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

        let height = view.heightAnchor.constraint(equalToConstant: 250)
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
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 8) {
                    if index == 2 {
                        KeyCap(title: "⇧", weight: .medium, size: 16) { model.shift.toggle() }
                    }
                    ForEach(Array(row.enumerated()), id: \.offset) { _, ch in
                        KeyCap(title: model.shift ? String(ch).uppercased() : String(ch),
                               weight: .regular, size: 23) {
                            model.tapLetter(String(ch))
                        }
                    }
                    if index == 2 {
                        KeyCap(title: "⌫", weight: .medium, size: 16) { model.delete() }
                    }
                }
                .frame(height: 49)
            }
            HStack(spacing: 8) {
                KeyCap(title: "地球", weight: .medium, size: 16) { model.switchKeyboard() }
                KeyCap(title: ",", weight: .medium, size: 16) { model.insert("，") }
                KeyCap(title: "空格", weight: .medium, size: 16) { model.insert(" ") }
                KeyCap(title: "。", weight: .medium, size: 16) { model.insert("。") }
                KeyCap(title: "⏎", weight: .medium, size: 16) { model.insert("\n") }
            }
            .frame(height: 49)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(Color.clear)
    }
}

struct KeyCap: View {
    let title: String
    var weight: Font.Weight = .regular
    var size: CGFloat = 22
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: weight))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
            .scaleEffect(pressed ? 1.06 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.65), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed { pressed = true }
                    }
                    .onEnded { _ in
                        pressed = false
                        action()
                    }
            )
    }
}
