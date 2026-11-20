import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {

    private var host: UIHostingController<GlassKeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
        inputView?.backgroundColor = .clear

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

        let height = view.heightAnchor.constraint(equalToConstant: 255)
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
                HStack(spacing: 7) {
                    if index == 2 {
                        KeyCap(title: "⇧", weight: .medium, size: 16) { model.shift.toggle() }
                    }
                    ForEach(Array(row.enumerated()), id: \.offset) { _, ch in
                        KeyCap(title: model.shift ? String(ch).uppercased() : String(ch),
                               weight: .regular, size: 22) {
                            model.tapLetter(String(ch))
                        }
                    }
                    if index == 2 {
                        KeyCap(title: "⌫", weight: .medium, size: 16) { model.delete() }
                    }
                }
                .frame(height: 46)
            }
            HStack(spacing: 7) {
                KeyCap(title: "123", weight: .medium, size: 15) { model.insert("1") }
                KeyCap(title: ",", weight: .medium, size: 16) { model.insert("，") }
                KeyCap(title: "空格", weight: .medium, size: 15) { model.insert(" ") }
                KeyCap(title: "。", weight: .medium, size: 16) { model.insert("。") }
                KeyCap(title: "⏎", weight: .medium, size: 16) { model.insert("\n") }
            }
            .frame(height: 46)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 30))
                .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 10)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

struct KeyCap: View {
    let title: String
    var weight: Font.Weight = .regular
    var size: CGFloat = 22
    let action: () -> Void

    @State private var pressed = false
    @State private var hideToken = 0

    private let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(pressed ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(pressed ? systemBlue : Color.white.opacity(0.55))
            }
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 14))
            .shadow(color: Color.black.opacity(pressed ? 0.0 : 0.14), radius: 5, x: 0, y: 2)
            .overlay {
                if pressed {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(pressed ? 1.5 : 1.0)
            .zIndex(pressed ? 1 : 0)
            .shadow(color: pressed ? systemBlue.opacity(0.55) : .clear, radius: 18)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            withAnimation(.easeOut(duration: 0.05)) {
                                pressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        action()
                        hideToken += 1
                        let token = hideToken
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            guard token == hideToken else { return }
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) {
                                pressed = false
                            }
                        }
                    }
            )
    }
}
