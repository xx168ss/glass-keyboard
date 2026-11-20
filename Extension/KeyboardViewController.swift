import UIKit

final class KeyboardViewController: UIInputViewController {

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
    private var shiftOn = true
    private var letterButtons: [GlassKey] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
        applyShift()
    }

    private func buildKeyboard() {
        view.backgroundColor = .clear

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 9
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 9),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -9)
        ])

        for (index, row) in rows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 7
            rowStack.distribution = .fillEqually

            if index == 2 {
                rowStack.addArrangedSubview(functionKey("⇧", action: #selector(toggleShift)))
            }
            for ch in row {
                let key = letterKey(String(ch))
                letterButtons.append(key)
                rowStack.addArrangedSubview(key)
            }
            if index == 2 {
                rowStack.addArrangedSubview(functionKey("⌫", action: #selector(deleteBackwardKey)))
            }
            root.addArrangedSubview(rowStack)
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 7
        bottom.distribution = .fillEqually

        bottom.addArrangedSubview(functionKey("地球", action: #selector(nextKeyboard)))
        bottom.addArrangedSubview(functionKey(",", action: #selector(insertComma)))
        bottom.addArrangedSubview(spaceKey())
        bottom.addArrangedSubview(functionKey("。", action: #selector(insertPeriod)))
        bottom.addArrangedSubview(functionKey("⏎", action: #selector(insertReturn)))

        root.addArrangedSubview(bottom)
    }

    private func letterKey(_ title: String) -> GlassKey {
        let key = GlassKey(title: title, weight: .regular, fontSize: 23, glassy: true)
        key.heightAnchor.constraint(equalToConstant: 50).isActive = true
        key.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        return key
    }

    private func spaceKey() -> GlassKey {
        let key = GlassKey(title: "空格", weight: .medium, fontSize: 16, glassy: true)
        key.heightAnchor.constraint(equalToConstant: 50).isActive = true
        key.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)
        return key
    }

    private func functionKey(_ title: String, action: Selector) -> GlassKey {
        let key = GlassKey(title: title, weight: .medium, fontSize: 16, glassy: false)
        key.heightAnchor.constraint(equalToConstant: 50).isActive = true
        key.addTarget(self, action: action, for: .touchUpInside)
        return key
    }

    private func applyShift() {
        for key in letterButtons {
            key.setTitle(shiftOn ? key.titleText.uppercased() : key.titleText.lowercased())
        }
    }

    @objc private func letterTapped(_ sender: GlassKey) {
        textDocumentProxy.insertText(sender.titleText)
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

// MARK: - 玻璃按键

final class GlassKey: UIControl {

    private(set) var titleText: String = ""
    private let label = UILabel()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let sheen = CAGradientLayer()
    private let rim = CAShapeLayer()
    private let glassy: Bool

    init(title: String, weight: UIFont.Weight, fontSize: CGFloat, glassy: Bool) {
        self.glassy = glassy
        super.init(frame: .zero)
        titleText = title
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = 11
        layer.cornerCurve = .continuous
        clipsToBounds = false

        blur.isUserInteractionEnabled = false
        blur.layer.cornerRadius = 11
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        blur.alpha = glassy ? 0.92 : 0.72
        addSubview(blur)

        sheen.colors = [
            UIColor.white.withAlphaComponent(glassy ? 0.42 : 0.22).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        sheen.locations = [0, 0.55]
        sheen.startPoint = CGPoint(x: 0.5, y: 0)
        sheen.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(sheen)

        label.text = title
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        rim.fillColor = UIColor.clear.cgColor
        rim.strokeColor = UIColor.white.withAlphaComponent(0.55).cgColor
        rim.lineWidth = 1.0
        layer.addSublayer(rim)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = glassy ? 0.10 : 0.06
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setTitle(_ text: String) {
        titleText = text
        label.text = text
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sheen.frame = bounds
                let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: 11).cgPath
        sheen.mask = mask
        rim.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                                cornerRadius: 11).cgPath
        rim.frame = bounds
        CATransaction.commit()
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.4,
                           options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                    : .identity
                self.sheen.opacity = self.isHighlighted ? 1.0 : 0.85
                self.layer.shadowOpacity = self.isHighlighted ? 0.04 : (self.glassy ? 0.10 : 0.06)
            }
        }
    }
}
