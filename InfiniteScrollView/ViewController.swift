//
//  ViewController.swift
//  InfiniteScrollView
//
//  Created by Yamazaki Mitsuyoshi on 2020/05/13.
//  Copyright © 2020 Yamazaki Mitsuyoshi. All rights reserved.
//

import UIKit

final class Cell: InfiniteScrollViewCell {
    @IBOutlet private weak var textLabel: UILabel!

    func set(text: String) {
        textLabel.text = text
    }
}

final class ViewController: UIViewController {
    @IBOutlet private weak var infiniteScrollView: InfiniteScrollView! {
        didSet {
            let nib = UINib(nibName: "Cell", bundle: Bundle.main)
            infiniteScrollView.register(nib: nib, for: Cell.self)
            infiniteScrollView.dataSource = self
            infiniteScrollView.delegate = self
        }
    }

    private let data: [UIColor] = {
        let numberOfRows = 20
        let data = (0..<numberOfRows).map { index -> UIColor in
            let value = CGFloat(index + 1) / CGFloat(numberOfRows + 2)
            return UIColor(red: value, green: 0.0, blue: 1 - value, alpha: 1.0)
        }
        return data + data.reversed().dropFirst().dropLast()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ViewController: InfiniteScrollViewDataSource {
    func numberOfRowsInInfiniteScrollView(_ infiniteScrollView: InfiniteScrollView) -> Int {
        return data.count
    }

    func infiniteScrollView(_ infiniteScrollView: InfiniteScrollView, cellForRowAt index: Int) -> InfiniteScrollViewCell {
        let cell: Cell = infiniteScrollView.dequeueReusableCell()
        let color = data[index]
        cell.backgroundColor = color
        cell.set(text: "\(index)")
        return cell
    }
}

extension ViewController: InfiniteScrollViewDelegate {

}
