import UIKit
import SwiftUI

// MARK: - 控制器

final class KeyboardViewController: UIInputViewController {

    private var host: UIHostingController<KeyboardRootView>?

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
            paste: { [weak self] in
                guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
                self?.textDocumentProxy.insertText(text)
            },
            dismiss: { [weak self] in
                self?.dismissKeyboard()
            },
            nextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            }
        )

        let host = UIHostingController(rootView: KeyboardRootView(model: model))
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

        let height = view.heightAnchor.constraint(equalToConstant: 245)
        height.priority = .defaultHigh
        height.isActive = true
    }
}

// MARK: - 数据

enum KeyboardMode: String, CaseIterable, Identifiable {
    case qwerty = "26键"
    case doublePinyin = "双拼"
    case t9 = "九宫格"
    case stroke = "笔画"
    case numeric = "数字"

    var id: String { rawValue }
}

@MainActor
final class KeyboardModel: ObservableObject {
    @Published var mode: KeyboardMode = .qwerty
    @Published var shift = true

    let insertText: (String) -> Void
    let deleteBackward: () -> Void
    let pasteText: () -> Void
    let dismissKeyboard: () -> Void
    let nextKeyboard: () -> Void

    init(insert: @escaping (String) -> Void,
         delete: @escaping () -> Void,
         paste: @escaping () -> Void,
         dismiss: @escaping () -> Void,
         nextKeyboard: @escaping () -> Void) {
        self.insertText = insert
        self.deleteBackward = delete
        self.pasteText = paste
        self.dismissKeyboard = dismiss
        self.nextKeyboard = nextKeyboard
    }

    func tapLetter(_ ch: String) {
        insertText(shift ? ch.uppercased() : ch)
        if shift { shift = false }
    }
}

// MARK: - 根视图

struct KeyboardRootView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        VStack(spacing: 6) {
            ToolbarView(model: model)

            Group {
                switch model.mode {
                case .qwerty, .doublePinyin:
                    LetterKeyboard(model: model)
                case .t9:
                    T9Keyboard(model: model)
                case .stroke:
                    StrokeKeyboard(model: model)
                case .numeric:
                    NumericKeyboard(model: model)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Color.clear)
    }
}

// MARK: - 工具栏

struct ToolbarView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        HStack(spacing: 6) {
            ToolButton(icon: "teddybear.fill") {
                model.insertText("🐻")
            }

            Menu {
                ForEach(KeyboardMode.allCases) { m in
                    Button(m.rawValue) {
                        model.mode = m
                    }
                }
            } label: {
                Image(systemName: "keyboard")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 30)
            }

            ToolButton(icon: "character.cursor.ibeam") {}
            ToolButton(icon: "face.smiling") { model.insertText("😊") }
            ToolButton(icon: "magnifyingglass") {}

            Spacer(minLength: 0)

            ToolButton(icon: "doc.on.clipboard") { model.pasteText() }
            ToolButton(icon: "chevron.down") { model.dismissKeyboard() }
        }
        .frame(height: 30)
    }
}

struct ToolButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 30)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 26 键

struct LetterKeyboard: View {
    @ObservedObject var model: KeyboardModel

    private let rows: [[(String, String)]] = [
        [("q", "1"), ("w", "2"), ("e", "3"), ("r", "4"), ("t", "5"),
         ("y", "6"), ("u", "7"), ("i", "8"), ("o", "9"), ("p", "0")],
        [("a", ""), ("s", ""), ("d", ""), ("f", ""), ("g", ""),
         ("h", ""), ("j", ""), ("k", ""), ("l", "")],
        [("z", ""), ("x", ""), ("c", ""), ("v", ""), ("b", ""), ("n", ""), ("m", "")]
    ]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 6) {
                    if r == 2 {
                        FunctionKey(title: "符", size: 16) { model.insertText("符") }
                    }
                    ForEach(0..<rows[r].count, id: \.self) { i in
                        let item = rows[r][i]
                        LetterKey(hint: item.1,
                                  letter: model.shift ? item.0.uppercased() : item.0) {
                            model.tapLetter(item.0)
                        }
                    }
                    if r == 2 {
                        FunctionKey(title: "⌫", size: 17) { model.deleteBackward() }
                    }
                }
                .frame(height: 45)
            }

            HStack(spacing: 6) {
                FunctionKey(title: "ABC", size: 15) { model.shift = true }
                FunctionKey(title: "123", size: 15) { model.mode = .numeric }
                SpaceKey(model: model)
                FunctionKey(title: "，。", size: 15) { model.insertText("，") }
                FunctionKey(title: "发送", size: 15) { model.insertText("\n") }
            }
            .frame(height: 45)
        }
    }
}

// MARK: - 九宫格

struct T9Keyboard: View {
    @ObservedObject var model: KeyboardModel

    private let groups: [[String]] = [
        ["ABC", "DEF", "GHI"],
        ["JKL", "MNO", "PQRS"],
        ["TUV", "WXYZ", "符"]
    ]

    @State private var lastKey: String = ""
    @State private var cycleIndex = 0

    var body: some View {
        VStack(spacing: 7) {
            ForEach(0..<groups.count, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(groups[r], id: \.self) { label in
                        FunctionKey(title: label, size: 20) {
                            t9Tap(label)
                        }
                    }
                    if r == 1 {
                        FunctionKey(title: "⌫", size: 17) { model.deleteBackward() }
                    }
                }
                .frame(height: 50)
            }
            HStack(spacing: 6) {
                FunctionKey(title: "123", size: 15) { model.mode = .numeric }
                FunctionKey(title: "空格", size: 15) { model.insertText(" ") }
                FunctionKey(title: "发送", size: 15) { model.insertText("\n") }
            }
            .frame(height: 45)
        }
    }

    private func t9Tap(_ label: String) {
        guard label.count > 1 || label == "符" else {
            model.insertText(label)
            return
        }
        if label == "符" {
            model.insertText("，")
            return
        }
        if lastKey != label {
            lastKey = label
            cycleIndex = 0
        } else {
            cycleIndex = (cycleIndex + 1) % label.count
        }
        let index = label.index(label.startIndex, offsetBy: cycleIndex)
        model.insertText(String(label[index]).lowercased())
    }
}

// MARK: - 笔画

struct StrokeKeyboard: View {
    @ObservedObject var model: KeyboardModel

    private let strokes = ["一", "丨", "丿", "丶", "乙"]

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                ForEach(strokes.prefix(3), id: \.self) { s in
                    FunctionKey(title: s, size: 22) { model.insertText(s) }
                }
            }
            .frame(height: 50)

            HStack(spacing: 6) {
                ForEach(strokes.suffix(2), id: \.self) { s in
                    FunctionKey(title: s, size: 22) { model.insertText(s) }
                }
                FunctionKey(title: "⌫", size: 17) { model.deleteBackward() }
            }
            .frame(height: 50)

            HStack(spacing: 6) {
                FunctionKey(title: "26键", size: 15) { model.mode = .qwerty }
                FunctionKey(title: "空格", size: 15) { model.insertText(" ") }
                FunctionKey(title: "发送", size: 15) { model.insertText("\n") }
            }
            .frame(height: 45)
        }
    }
}

// MARK: - 数字键盘

struct NumericKeyboard: View {
    @ObservedObject var model: KeyboardModel

    private let leftColumn = ["+", "*", "-", "/"]
    private let grid = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
    private let rightColumn = ["⌫", "@", "符号"]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 6) {
                    FunctionKey(title: leftColumn[r], size: 20) { model.insertText(leftColumn[r]) }

                    ForEach(grid[r], id: \.self) { n in
                        FunctionKey(title: n, size: 22) { model.insertText(n) }
                    }

                    let rk = rightColumn[r]
                    FunctionKey(title: rk, size: rk.count > 1 ? 15 : 20) {
                        if rk == "⌫" {
                            model.deleteBackward()
                        } else if rk == "符号" {
                            model.insertText("。")
                        } else {
                            model.insertText(rk)
                        }
                    }
                }
                .frame(height: 46)
            }

            HStack(spacing: 6) {
                FunctionKey(title: "返回", size: 15) { model.mode = .qwerty }
                SpaceKey(model: model)
                FunctionKey(title: "0", size: 22) { model.insertText("0") }
                FunctionKey(title: ".", size: 22) { model.insertText(".") }
                FunctionKey(title: "换行", size: 15) { model.insertText("\n") }
            }
            .frame(height: 46)
        }
    }
}

// MARK: - 按键

struct LetterKey: View {
    let hint: String
    let letter: String
    let action: () -> Void

    @State private var pressed = false
    @State private var token = 0

    private let blue = Color(red: 0.0, green: 0.478, blue: 1.0)
    private let tint = Color(red: 0.93, green: 0.93, blue: 0.99)

    var body: some View {
        VStack(spacing: 0) {
            if !hint.isEmpty {
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text(letter)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(pressed ? Color.white : Color.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(pressed ? blue : tint.opacity(0.5))
        }
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.8)
                .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(pressed ? 0 : 0.1), radius: 4, x: 0, y: 1)
        .scaleEffect(pressed ? 1.35 : 1.0)
        .zIndex(pressed ? 1 : 0)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(.easeOut(duration: 0.05)) { pressed = true }
                    }
                }
                .onEnded { _ in
                    action()
                    token += 1
                    let current = token
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        guard current == token else { return }
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) {
                            pressed = false
                        }
                    }
                }
        )
    }
}

struct FunctionKey: View {
    let title: String
    var size: CGFloat = 17
    let action: () -> Void

    @State private var pressed = false
    @State private var token = 0

    private let blue = Color(red: 0.0, green: 0.478, blue: 1.0)
    private let grey = Color(red: 0.78, green: 0.80, blue: 0.86)

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(pressed ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pressed ? blue : grey.opacity(0.55))
            }
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(pressed ? 0 : 0.08), radius: 4, x: 0, y: 1)
            .scaleEffect(pressed ? 1.3 : 1.0)
            .zIndex(pressed ? 1 : 0)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            withAnimation(.easeOut(duration: 0.05)) { pressed = true }
                        }
                    }
                    .onEnded { _ in
                        action()
                        token += 1
                        let current = token
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            guard current == token else { return }
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) {
                                pressed = false
                            }
                        }
                    }
            )
    }
}

struct SpaceKey: View {
    @ObservedObject var model: KeyboardModel

    @State private var pressed = false
    @State private var token = 0

    private let blue = Color(red: 0.0, green: 0.478, blue: 1.0)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(pressed ? blue : Color.white.opacity(0.85))

            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("拼音")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.7), lineWidth: 0.8)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(.easeOut(duration: 0.05)) { pressed = true }
                    }
                }
                .onEnded { _ in
                    model.insertText(" ")
                    token += 1
                    let current = token
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        guard current == token else { return }
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) {
                            pressed = false
                        }
                    }
                }
        )
    }
}
