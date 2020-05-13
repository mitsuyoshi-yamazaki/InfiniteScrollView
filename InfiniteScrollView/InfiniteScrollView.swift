//
//  InfiniteScrollView.swift
//  InfiniteScrollView
//
//  Created by Yamazaki Mitsuyoshi on 2020/05/14.
//  Copyright © 2020 Yamazaki Mitsuyoshi. All rights reserved.
//

import UIKit

open class InfiniteScrollViewCell: UIView {}

public protocol InfiniteScrollViewDataSource: class {
    func numberOfRowsInInfiniteScrollView(_ infiniteScrollView: InfiniteScrollView) -> Int
    func infiniteScrollView(_ infiniteScrollView: InfiniteScrollView, cellForRowAt index: Int) -> InfiniteScrollViewCell
}

public protocol InfiniteScrollViewDelegate: class, UIScrollViewDelegate {
}

public extension InfiniteScrollViewDelegate {
}

open class InfiniteScrollView: UIScrollView {
    public weak var dataSource: InfiniteScrollViewDataSource?
    public weak var infiniteScrollViewDelegate: InfiniteScrollViewDelegate? {
        get {
            guard let delegate = self.delegate as? InfiniteScrollViewDelegate else {
                return nil
            }
            return delegate
        }
        set {
            delegate = newValue
        }
    }

    public var offset: CGFloat = 0.0

    private let contentView = UIView()

    private var previousContentOffsetY: CGFloat = 0.0
    private var contentOffsetObservation: NSKeyValueObservation?
    private var cellNibs: [String: UINib] = [:]
    private var queuingCells: Set<InfiniteScrollViewCell> = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func reloadData() {  // TODO: Automatically reload data when it's addedd to a window
        guard let numberOfRows = dataSource?.numberOfRowsInInfiniteScrollView(self), numberOfRows > 0, let dataSource = dataSource else {
            removeAllCells()
            return
        }

        // FixMe: Inherit previous offset
        offset = 0.0
        contentOffset = CGPoint(x: 0.0, y: frame.height)
        previousContentOffsetY = contentOffset.y

        var previousCell = dataSource.infiniteScrollView(self, cellForRowAt: 0)
        contentView.addSubview(previousCell)
        previousCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: frame.height).isActive = true
        previousCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        previousCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

        (1..<numberOfRows).forEach { index in
            let cell = dataSource.infiniteScrollView(self, cellForRowAt: index)
            contentView.addSubview(cell)
            cell.topAnchor.constraint(equalTo: previousCell.bottomAnchor).isActive = true
            cell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            cell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

            previousCell = cell
        }

        layoutIfNeeded()
    }

    public func register<Cell: InfiniteScrollViewCell>(nib: UINib, for cellType: Cell.Type) {
        cellNibs[NSStringFromClass(cellType)] = nib
    }

    public func dequeueReusableCell<Cell: InfiniteScrollViewCell>() -> Cell {
        let cell: Cell
        if let dequeuedCell = queuingCells.first(where: { $0 is Cell }) as? Cell {
            queuingCells.remove(dequeuedCell)
            cell = dequeuedCell
        } else if let nib = cellNibs[NSStringFromClass(Cell.self)] {
            guard let instantiatedFromNib = nib.instantiate(withOwner: nil, options: nil).first as? Cell else {
                fatalError("Cell instantiation failed: registered nib doesn't contain \(Cell.self)")
            }
            cell = instantiatedFromNib
        } else {
            cell = Cell()
        }
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.isHidden = false
        addSubview(cell)
        return cell
    }
}

private extension InfiniteScrollView {
    func setup() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false

        // contentView
        contentView.backgroundColor = UIColor.clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        // Horizontal constraints
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true

        // Vertical constraints
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 3.0).isActive = true

        let dummyView = UIView()
        dummyView.backgroundColor = UIColor.red
        contentView.addSubview(dummyView)
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        dummyView.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        dummyView.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        dummyView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        dummyView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        offset = 0.0
        contentOffset = CGPoint(x: 0.0, y: frame.height)
        previousContentOffsetY = contentOffset.y

        contentOffsetObservation = observe(\.contentOffset, options: .new) { [weak self] _, change in
            guard let self = self, let contentOffset = change.newValue else {
                return
            }
            print("\(contentOffset.y)")

            let y = contentOffset.y
            let height = self.frame.height

            self.offset += y - self.previousContentOffsetY
            self.previousContentOffsetY = y

            if y < (height * 0.5) {
                self.contentOffset = CGPoint(x: 0.0, y: y + height)
            } else if y > (height * 1.5) {
                self.contentOffset = CGPoint(x: 0.0, y: y - height)
            }
        }
    }

    func removeAllCells() {
        subviews.forEach { subview in
            guard let cell = subview as? InfiniteScrollViewCell else {
                return
            }
            self.enqueue(cell: cell)
        }
    }

    func enqueue(cell: InfiniteScrollViewCell) {
        cell.isHidden = true
        cell.removeFromSuperview()
        queuingCells.insert(cell)
    }
}
