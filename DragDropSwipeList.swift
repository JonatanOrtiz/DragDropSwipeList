class ViewController: UIViewController {

    override func viewDidLoad() {

        super.viewDidLoad()



        let listView = CustomListView(items: ["Item 1", "Item 2", "Item 3", "Item 4"])

        listView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(listView)



        NSLayoutConstraint.activate([

            listView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)

        ])

    }

}



class CustomListItemView: UIView {

    let label = UILabel()

    let deleteButton = UIButton()

    private var panGesture: UIPanGestureRecognizer!

    private var originalCenter: CGPoint = .zero



    var onDelete: ((CustomListItemView) -> Void)?

    var onReorder: ((UIPanGestureRecognizer, CustomListItemView) -> Void)?

    var onEndReorder: ((CustomListItemView) -> Void)?



    init(text: String) {

        super.init(frame: .zero)

        setupView()

        label.text = text

    }



    required init?(coder: NSCoder) {

        fatalError("init(coder:) has not been implemented")

    }



    private func setupView() {

        backgroundColor = .white

        layer.cornerRadius = 8

        layer.shadowColor = UIColor.black.cgColor

        layer.shadowOpacity = 0.1

        layer.shadowOffset = CGSize(width: 0, height: 2)

        layer.shadowRadius = 4



        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        addSubview(label)



        deleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)

        deleteButton.backgroundColor = .red

        deleteButton.tintColor = .white

        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)

        addSubview(deleteButton)



        setupGestures()



        NSLayoutConstraint.activate([

            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),



            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 80),

            deleteButton.widthAnchor.constraint(equalToConstant: 60),

            deleteButton.heightAnchor.constraint(equalTo: heightAnchor)

        ])

    }



    private func setupGestures() {

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))

        addGestureRecognizer(panGesture)

    }



    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {

        let translation = gesture.translation(in: self)

        let deleteButtonWidth: CGFloat = 80

        let spaces: CGFloat = 16 * 2

        let screenWidth = UIScreen.main.bounds.width

        let viewTrailing = frame.origin.x + frame.width



        switch gesture.state {

            case .changed:

                let buttonFrameInScreen = deleteButton.convert(deleteButton.bounds, to: nil)

                let buttonTrailingInScreen = buttonFrameInScreen.origin.x + buttonFrameInScreen.width



                if abs(translation.x) > abs(translation.y) {

                    let newCenterX = center.x + translation.x



                    if viewTrailing + deleteButtonWidth + spaces >= screenWidth && !(viewTrailing + spaces > screenWidth) {

                        center.x = newCenterX

                    }



                    gesture.setTranslation(.zero, in: self)

                } else {

                    onReorder?(gesture, self)

                }



            case .ended, .cancelled:

                if viewTrailing + deleteButtonWidth <= screenWidth {

                    UIView.animate(withDuration: 0.2) {

                        self.frame.origin.x = screenWidth - self.frame.width - deleteButtonWidth - spaces

                    }

                } else {

                    onEndReorder?(self)

                }



            default:

                break

        }

    }



    @objc private func handleDelete() {

        onDelete?(self)

    }

}



class CustomListView: UIView {

    private var items: [String]

    private var itemViews: [CustomListItemView] = []



    init(items: [String]) {

        self.items = items

        super.init(frame: .zero)

        setupViews()

        setupTapGesture()

    }



    required init?(coder: NSCoder) {

        fatalError("init(coder:) has not been implemented")

    }



    private func setupViews() {

        for (index, item) in items.enumerated() {

            let itemView = CustomListItemView(text: item)

            itemView.tag = index

            itemView.onDelete = { [weak self] view in

                self?.deleteItem(view)

            }

            itemView.onReorder = { [weak self] gesture, view in

                self?.handleReorder(gesture, view)

            }

            itemView.onEndReorder = { [weak self] view in

                self?.finalizeReorder(view)

            }



            addSubview(itemView)

            itemViews.append(itemView)

        }

        layoutItems()

    }



    private func layoutItems() {

        let spacing: CGFloat = 10



        for (index, itemView) in itemViews.enumerated() {

            let yPosition = CGFloat(index) * (60 + spacing)

            itemView.frame = CGRect(x: 0, y: yPosition, width: bounds.width, height: 60)

        }

    }



    private func setupTapGesture() {

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

        tapGesture.cancelsTouchesInView = false

        self.addGestureRecognizer(tapGesture)

    }



    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {

        let location = gesture.location(in: self)



        for itemView in itemViews {

            let deleteButtonFrame = itemView.deleteButton.convert(itemView.deleteButton.bounds, to: self)



            if deleteButtonFrame.contains(location) {

                deleteItem(itemView)

                break

            }

        }

    }



    private func deleteItem(_ view: CustomListItemView) {

        guard let index = itemViews.firstIndex(of: view) else { return }



        UIView.animate(withDuration: 0.3, animations: {

            view.alpha = 0

            view.transform = CGAffineTransform(translationX: -self.bounds.width, y: 0)

        }, completion: { _ in

            view.removeFromSuperview()

            self.itemViews.remove(at: index)

            self.items.remove(at: index)

            self.animateRearrange()

        })

    }



    private func handleReorder(_ gesture: UIPanGestureRecognizer, _ view: CustomListItemView) {

        guard let index = itemViews.firstIndex(of: view) else { return }

        let translation = gesture.translation(in: self)



        switch gesture.state {

            case .began:

                UIView.animate(withDuration: 0.2) {

                    view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)

                    view.alpha = 0.9

                }



            case .changed:

                let newCenterY = view.center.y + translation.y

                gesture.setTranslation(.zero, in: self)



                let firstViewY = itemViews.first?.center.y ?? 0

                let lastViewY = itemViews.last?.center.y ?? 0



                if newCenterY < firstViewY {

                    view.center.y = firstViewY

                } else if newCenterY > lastViewY {

                    view.center.y = lastViewY

                } else {

                    view.center.y = newCenterY

                }



                for otherView in itemViews {

                    guard otherView != view else { continue }



                    let distance = abs(view.center.y - otherView.center.y)

                    if distance < 30 {

                        swapItems(view, otherView)

                        break

                    }

                }



            default:

                break

        }

    }



    private func finalizeReorder(_ view: CustomListItemView) {

        if let correctIndex = itemViews.firstIndex(of: view) {

            UIView.animate(withDuration: 0.3) {

                view.center.y = CGFloat(correctIndex * 60) + 30

                self.layoutItems()

            }

        }

    }



    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {

            let velocity = panGesture.velocity(in: self)



            if abs(velocity.y) > abs(velocity.x) {

                return true

            }

        }

        return false

    }



    private func swapItems(_ first: CustomListItemView, _ second: CustomListItemView) {

        guard let firstIndex = itemViews.firstIndex(of: first),

                let secondIndex = itemViews.firstIndex(of: second) else { return }



        itemViews.swapAt(firstIndex, secondIndex)

        items.swapAt(firstIndex, secondIndex)



        UIView.animate(withDuration: 0.3) {

            self.layoutItems()

        }

    }



    private func animateRearrange() {

        UIView.animate(withDuration: 0.3) {

            self.layoutItems()

        }

    }



    override func layoutSubviews() {

        super.layoutSubviews()

        layoutItems()

    }

}
