//
// Copyright © 2020 An Tran. All rights reserved.
//

import LeakDetector
import RxCocoa
import RxSwift
import UIKit

class RxSwiftViewController1: ChildViewController {
    
    let disposeBag = DisposeBag()
    let leakRelay = PublishRelay<Bool>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leakRelay.asSignal()
            .emit(onNext: { _ in
                self.view.tag = 111
            })
            .disposed(by: disposeBag)

//        // Capture `self` as weak to avoid retain cycle
//        leakRelay.asSignal()
//            .emit(onNext: { [weak self] _ in
//                self?.view.tag = 111
//            })
//            .disposed(by: disposeBag)
    }
}

class RxSwiftViewController2: ChildViewController {
    
    private let disposeBag = DisposeBag()
    private lazy var button = {
        UIButton()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        button.rx.tap.subscribe {
            self.view.tag = 111
        }
        .disposed(by: disposeBag)
    }
}

class NoLeakRxSwiftViewController1: ChildViewController {
    
    let disposeBag = DisposeBag()
    let leakRelay = PublishRelay<Bool>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        leakRelay.asSignal()
//            .emit(onNext: { _ in
//                self.view.tag = 111
//            })
//            .disposed(by: disposeBag)

        // Capture `self` as weak to avoid retain cycle
        leakRelay.asSignal()
            .emit(onNext: { [weak self] _ in
                self?.view.tag = 111
            })
            .disposed(by: disposeBag)
    }
    
}

class NoLeakRxSwiftViewController2: ChildViewController {
    
    private let disposeBag = DisposeBag()
    private lazy var button = {
        UIButton()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        button.rx.tap.subscribe { [weak self] in
            self?.view.tag = 111
        }
        .disposed(by: disposeBag)
    }
}
