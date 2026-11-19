import UIKit

final class KeyboardViewController: UIInputViewController {

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
    private var shiftOn = true

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
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
                rowStack.addArrangedSubview(letterKey(String(ch)))
            }
            if index == 2 {
                rowStack.addArrangedSubview(functionKey("⌫", action: #selector(deleteBackward)))
            }
            root.addArrangedSubview(rowStack)
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 6
        bottom.distribution = .fillEqually

        bottom.addArrangedSubview(functionKey("地球", action: #selector(nextKeyboard)))
        bottom.addArrangedSubview(functionKey(",", action: #selector(insertComma)))
        let space = letterKey("空格")
        bottom.addArrangedSubview(space)
        bottom.addArrangedSubview(functionKey("。", action: #selector(insertPeriod)))
        bottom.addArrangedSubview(functionKey("⏎", action: #selector(insertReturn)))

        space.heightAnchor.constraint(equalToConstant: 46).isActive = true
        root.addArrangedSubview(bottom)
    }

    private func letterKey(_ title: String) -> UIButton {
        let button = makeKey(title, weight: .regular)
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
        return button
    }

    private func functionKey(_ title: String, action: Selector) -> UIButton {
        let button = makeKey(title, weight: .medium)
        button.layer.cornerRadius = 9
        button.layer.cornerCurve = .continuous
        button.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeKey(_ title: String, weight: UIFont.Weight) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: weight)
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), title.count == 1 else { return }
        let text = shiftOn ? title.uppercased() : title
        (textDocumentProxy as UIKeyInput).insertText(text)
        if shiftOn { shiftOn = false }
    }

    @objc private func toggleShift() { shiftOn.toggle() }
    @objc private func deleteBackward() { (textDocumentProxy as UIKeyInput).deleteBackward() }
    @objc private func insertComma() { (textDocumentProxy as UIKeyInput).insertText("，") }
    @objc private func insertPeriod() { (textDocumentProxy as UIKeyInput).insertText("。") }
    @objc private func insertReturn() { (textDocumentProxy as UIKeyInput).insertText("\n") }
    @objc private func nextKeyboard() { advanceToNextInputMode() }
}
