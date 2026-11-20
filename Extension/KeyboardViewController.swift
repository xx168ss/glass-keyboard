import UIKit

final class KeyboardViewController: UIInputViewController {

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
    private var shiftOn = true
    private var letterButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
        applyShift()
    }

    private func buildKeyboard() {
        view.backgroundColor = .clear

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        for (index, row) in rows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 6
            rowStack.distribution = .fillEqually

            if index == 2 {
                rowStack.addArrangedSubview(functionKey("⇧", action: #selector(toggleShift)))
            }
            for ch in row {
                let button = letterKey(String(ch))
                letterButtons.append(button)
                rowStack.addArrangedSubview(button)
            }
            if index == 2 {
                rowStack.addArrangedSubview(functionKey("⌫", action: #selector(deleteBackwardKey)))
            }
            root.addArrangedSubview(rowStack)
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 6
        bottom.distribution = .fillEqually

        bottom.addArrangedSubview(functionKey("地球", action: #selector(nextKeyboard)))
        bottom.addArrangedSubview(functionKey(",", action: #selector(insertComma)))
        bottom.addArrangedSubview(spaceKey())
        bottom.addArrangedSubview(functionKey("。", action: #selector(insertPeriod)))
        bottom.addArrangedSubview(functionKey("⏎", action: #selector(insertReturn)))

        root.addArrangedSubview(bottom)
    }

    private func letterKey(_ title: String) -> UIButton {
        let button = baseKey(title)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        button.layer.cornerRadius = 9
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        blur.isUserInteractionEnabled = false
        blur.frame = button.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.insertSubview(blur, at: 0)
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        return button
    }

    private func spaceKey() -> UIButton {
        let button = baseKey("空格")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        button.layer.cornerRadius = 9
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)
        return button
    }

    private func functionKey(_ title: String, action: Selector) -> UIButton {
        let button = baseKey(title)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        button.layer.cornerRadius = 9
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func baseKey(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.label, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    private func applyShift() {
        for button in letterButtons {
            guard let text = button.title(for: .normal) else { continue }
            button.setTitle(shiftOn ? text.uppercased() : text.lowercased(), for: .normal)
        }
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(title)
        if shiftOn {
            shiftOn = false
            applyShift()
        }
    }

    @objc private func toggleShift() {
        shiftOn.toggle()
        applyShift()
    }

    @objc private func deleteBackwardKey() { textDocumentProxy.deleteBackward() }
    @objc private func insertSpace() { textDocumentProxy.insertText(" ") }
    @objc private func insertComma() { textDocumentProxy.insertText("，") }
    @objc private func insertPeriod() { textDocumentProxy.insertText("。") }
    @objc private func insertReturn() { textDocumentProxy.insertText("\n") }
    @objc private func nextKeyboard() { advanceToNextInputMode() }
}
