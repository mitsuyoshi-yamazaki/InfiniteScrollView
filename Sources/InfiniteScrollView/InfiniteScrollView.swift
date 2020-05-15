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
    func infiniteScrollViewDidReload(_ infiniteScrollView: InfiniteScrollView)
}

public extension InfiniteScrollViewDelegate {
    func infiniteScrollViewDidReload(_ infiniteScrollView: InfiniteScrollView) {}
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

    var visibleCells: [InfiniteScrollViewCell] {
        return Array(cells.values)
    }
    var visibleTopCell: InfiniteScrollViewCell? {
        return visibleCells.sorted { $0.frame.origin.y < $1.frame.origin.y }.first
    }

    private let contentView = UIView()

    private var previousOffsetY: CGFloat = 0.0
    private var observations: [NSKeyValueObservation] = []
    private var cellNibs: [String: UINib] = [:]
    private var queuingCells: Set<InfiniteScrollViewCell> = []
    private var cells: [Int: InfiniteScrollViewCell] = [:]
    private var numberOfRows = 0
    private var cellAnchorConstraint: NSLayoutConstraint? {
        didSet {
            guard cellAnchorConstraint !== oldValue else {
                return
            }
            oldValue?.isActive = false
            cellAnchorConstraint?.isActive = true
        }
    }
    private var isReloading = false
    private var previousOrientation: UIInterfaceOrientation?
    private var topCellToTopEdge: CGFloat?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if let orientation = self.window?.windowScene?.interfaceOrientation, orientation != previousOrientation, let topCellToTopEdge = topCellToTopEdge {
            // Keep top cell position after rotation
            cellAnchorConstraint = visibleTopCell?.topAnchor.constraint(equalTo: contentView.topAnchor, constant: frame.height - topCellToTopEdge)
            contentOffset = CGPoint(x: 0.0, y: frame.height)
            setNeedsLayout()
            previousOrientation = orientation
            // FixMe: Rotate to landscape -> scroll down 1px -> rotate to portrait
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        previousOrientation = window?.windowScene?.interfaceOrientation
        reloadData()
    }
}

// MARK: - Public Methods
public extension InfiniteScrollView {
    func reloadData() {
        guard isReloading == false else {
            return
        }
        isReloading = true
        guard let numberOfRows = dataSource?.numberOfRowsInInfiniteScrollView(self), numberOfRows > 0, let dataSource = dataSource else {
            removeAllCells()
            infiniteScrollViewDelegate?.infiniteScrollViewDidReload(self)
            isReloading = false
            return
        }
        self.numberOfRows = numberOfRows

        // FixMe: Inherit previous offset
        contentOffset = CGPoint(x: 0.0, y: frame.height)
        previousOffsetY = contentOffset.y

        var previousCell = dataSource.infiniteScrollView(self, cellForRowAt: numberOfRows - 1)
        contentView.addSubview(previousCell)
        cellAnchorConstraint = previousCell.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: frame.height)
        previousCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        previousCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        cells[numberOfRows - 1] = previousCell

        var visibleHeight: CGFloat = 0.0

        for index in (0..<(numberOfRows - 1)) {
            guard visibleHeight < frame.height else {
                break
            }
            let cell = dataSource.infiniteScrollView(self, cellForRowAt: index)
            contentView.addSubview(cell)
            cell.topAnchor.constraint(equalTo: previousCell.bottomAnchor).isActive = true
            cell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            cell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

            cells[index] = cell
            previousCell = cell
            visibleHeight += cell.frame.height
            print("Cell \(index) frame: \(cell.frame), \(visibleHeight)")
        }
        setNeedsLayout()
        layoutIfNeeded()
        infiniteScrollViewDelegate?.infiniteScrollViewDidReload(self)
        isReloading = false
    }

    func register<Cell: InfiniteScrollViewCell>(nib: UINib, for cellType: Cell.Type) {
        cellNibs[NSStringFromClass(cellType)] = nib
    }

    func dequeueReusableCell<Cell: InfiniteScrollViewCell>() -> Cell {
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

// MARK: - Private Methods
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

        contentOffset = CGPoint(x: 0.0, y: frame.height)
        previousOffsetY = contentOffset.y

        let contentOffsetObservation = observe(\.contentOffset, options: .new) { [weak self] _, change in
            guard
                let self = self,
                let contentOffset = change.newValue,
                let orientation = self.window?.windowScene?.interfaceOrientation,
                orientation == self.previousOrientation
            else {
                return
            }
            self.topCellToTopEdge = self.visibleTopCell.map { contentOffset.y - $0.frame.origin.y }
            self.didScroll()
            print("offset: \(contentOffset.y), orientation: \(self.window?.windowScene?.interfaceOrientation.rawValue)")
        }
        observations.append(contentOffsetObservation)
    }

    func visibleCells(`for` rect: CGRect) -> [InfiniteScrollViewCell] {
        func isVisible(view: UIView) -> Bool {
            return view.frame.intersects(rect)
        }
        return contentView.subviews.compactMap { subview -> InfiniteScrollViewCell? in
            guard let cell = subview as? InfiniteScrollViewCell else {
                return nil
            }
            return isVisible(view: cell) ? cell : nil
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

    func didScroll() {
        defer {
            if isReloading {
            } else if y < (height * 0.5) {
                let newOffset = y + height
                DispatchQueue.main.async {
                    self.contentOffset = CGPoint(x: 0.0, y: newOffset)
                }
                previousOffsetY = newOffset
                cellAnchorConstraint?.constant += height
                setNeedsLayout()
            } else if y > (height * 1.5) {
                let newOffset = y - height
                DispatchQueue.main.async {
                    self.contentOffset = CGPoint(x: 0.0, y: newOffset)
                }
                previousOffsetY = newOffset
                cellAnchorConstraint?.constant -= height
                setNeedsLayout()
            } else {
                previousOffsetY = y
            }

            layoutIfNeeded()
        }

        let y = contentOffset.y
        let height = frame.height
        guard isReloading == false, y != previousOffsetY else {
            return
        }
        let visibleRect = CGRect(x: 0.0, y: y, width: frame.width, height: height)
        let visibleCells = self.visibleCells(for: visibleRect).sorted { $0.frame.origin.y < $1.frame.origin.y }
        let cellsToEnqueue = cells.filter { visibleCells.contains($0.value) == false }

        if y < previousOffsetY {
            // Scrolling down
            let bottomCell = visibleCells.last { cellsToEnqueue.values.contains($0) == false }!  // FixMe:
            if cellsToEnqueue.isEmpty == false {
                cellAnchorConstraint = bottomCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: bottomCell.frame.origin.y)
                cellsToEnqueue.forEach {
                    self.cells.removeValue(forKey: $0.key)
                    self.enqueue(cell: $0.value)
                }
                setNeedsLayout()
            }

            var previousCell: InfiniteScrollViewCell = visibleCells.first!   // FixMe:
            var contentTop = previousCell.frame.origin.y
            let visibleTop = y
            guard var index = cells.min(by: { lhs, rhs in lhs.value.frame.origin.y < rhs.value.frame.origin.y })?.key, let dataSource = dataSource else {
                return
            }

            while contentTop > visibleTop {   // FixMe: CAUSES INFINITE LOOP
                index = (index - 1 + numberOfRows) % numberOfRows

                let cell = dataSource.infiniteScrollView(self, cellForRowAt: index)
                contentView.addSubview(cell)
                cell.bottomAnchor.constraint(equalTo: previousCell.topAnchor).isActive = true
                cell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                cell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

                cells[index] = cell
                previousCell = cell
                contentTop -= cell.frame.height
                print("Update cell \(index) frame: \(cell.frame), \(contentTop)")
                setNeedsLayout()
            }

        } else {
            // Scrolling up
            let topCell = visibleCells.first { cellsToEnqueue.values.contains($0) == false }!  // FixMe:
            if cellsToEnqueue.isEmpty == false {
                cellAnchorConstraint = topCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topCell.frame.origin.y)
                cellsToEnqueue.forEach {
                    self.cells.removeValue(forKey: $0.key)
                    self.enqueue(cell: $0.value)
                }
                setNeedsLayout()
            }

            var previousCell: InfiniteScrollViewCell = visibleCells.last!   // FixMe:
            var contentBottom = previousCell.frame.origin.y + previousCell.frame.height
            let visibleBottom = y + frame.height
            guard var index = cells.max(by: { lhs, rhs in lhs.value.frame.origin.y < rhs.value.frame.origin.y })?.key, let dataSource = dataSource else {
                return
            }

            while contentBottom < visibleBottom {   // FixMe: CAUSES INFINITE LOOP
                index = (index + 1) % numberOfRows

                let cell = dataSource.infiniteScrollView(self, cellForRowAt: index)
                contentView.addSubview(cell)
                cell.topAnchor.constraint(equalTo: previousCell.bottomAnchor).isActive = true
                cell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                cell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

                cells[index] = cell
                previousCell = cell
                contentBottom += cell.frame.height
                print("Update cell \(index) frame: \(cell.frame), \(contentBottom)")
                setNeedsLayout()
            }
        }
    }
}
