//
//  Copyright © 2020 Steve Dao. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LeakDetector

class RxViewController: UIViewController {
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent || isBeingDismissed {
            LeakDetector.instance.expectDeallocate(object: leakRelay)
        }
    }
    
}