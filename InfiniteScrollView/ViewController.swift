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

    private let data: [Int] = Array(0..<20)

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        infiniteScrollView.reloadData()
    }
}

extension ViewController: InfiniteScrollViewDataSource {
    func numberOfRowsInInfiniteScrollView(_ infiniteScrollView: InfiniteScrollView) -> Int {
        return data.count
    }

    func infiniteScrollView(_ infiniteScrollView: InfiniteScrollView, cellForRowAt index: Int) -> InfiniteScrollViewCell {
        let cell: Cell = infiniteScrollView.dequeueReusableCell()
        cell.set(text: "\(index)")
        return cell
    }
}

extension ViewController: InfiniteScrollViewDelegate {

}
