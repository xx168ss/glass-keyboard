import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {

    private var host: UIHostingController<GlassKeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        clearBackdrop()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearBackdrop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.clearBackdrop()
        }
    }

    private func clearBackdrop() {
        view.backgroundColor = .clear
        view.isOpaque = false
        inputView?.backgroundColor = .clear

        var node: UIView? = view
        while let current = node {
            current.backgroundColor = .clear
            current.isOpaque = false
            if let effect = current as? UIVisualEffectView {
                effect.effect = nil
            }
            node = current.superview
        }
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

    private let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(pressed ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(pressed ? systemBlue.opacity(0.92) : Color.clear)
            }
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
            .overlay {
                if pressed {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.38), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(pressed ? 1.6 : 1.0)
            .zIndex(pressed ? 1 : 0)
            .shadow(color: pressed ? systemBlue.opacity(0.5) : .clear, radius: 18)
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
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                            pressed = false
                        }
                        action()
                    }
            )
    }
}
