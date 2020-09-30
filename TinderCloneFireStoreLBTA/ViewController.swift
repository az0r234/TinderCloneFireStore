//
//  ViewController.swift
//  TinderCloneFireStoreLBTA
//
//  Created by Alok Acharya on 4/25/20.
//  Copyright © 2020 Alok Acharya. All rights reserved.
//

import UIKit

class HomeController: UIViewController {
    
    let topStackView = TopNavigationStackView()
    let cardsDeckView = UIView()
    let buttonsStackView = HomeBottomControlsStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        
        setupDummyCards()

    }
    
    
    fileprivate func setupDummyCards(){
        print("setup dummy cards")
        
        let cardView = CardView(frame: .zero)
        cardsDeckView.addSubview(cardView)
        cardView.fillSuperview()
    }
    
    
    //MARK: - : File Private
    
    fileprivate func setupLayout() {
        let overallStackView = UIStackView(arrangedSubviews: [topStackView,cardsDeckView, buttonsStackView])
        overallStackView.axis = .vertical
        view.addSubview(overallStackView)
        
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        overallStackView.isLayoutMarginsRelativeArrangement = true
        overallStackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        overallStackView.bringSubviewToFront(cardsDeckView)
    }


}

