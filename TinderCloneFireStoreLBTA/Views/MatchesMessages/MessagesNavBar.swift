//
//  MessagesNavBar.swift
//  TinderCloneFireStoreLBTA
//
//  Created by Alok Acharya on 6/18/20.
//  Copyright © 2020 Alok Acharya. All rights reserved.
//

import LBTATools

class MessagesNavBar: UIView {
    
    let userProfileImageView = CircularImageView(width: 44, image: #imageLiteral(resourceName: "jane1"))
    let nameLabel = UILabel(text: "USERNAME", font: .systemFont(ofSize: 16))
    
    let backButton = UIButton(image: #imageLiteral(resourceName: "back").withRenderingMode(.alwaysTemplate), tintColor: #colorLiteral(red: 0.805975318, green: 0.05860736221, blue: 0.2378381789, alpha: 1))
    let flagButton = UIButton(image: #imageLiteral(resourceName: "flag").withRenderingMode(.alwaysTemplate), tintColor: #colorLiteral(red: 0.805975318, green: 0.05860736221, blue: 0.2378381789, alpha: 1))
    
    fileprivate let match: Match
    
    init(match: Match){
        self.match = match
        super.init(frame: .zero)
        backgroundColor = .white
        
        setupShadow(opacity: 0.2, radius: 8, offset: .init(width: 0, height: 10), color: .init(white: 0, alpha: 0.3))
        
        nameLabel.text = match.name
        userProfileImageView.sd_setImage(with: URL(string: match.profileImageUrl))
        
        let middleStack = hstack(
            stack(
                userProfileImageView,
                nameLabel,
                spacing: 8,
                alignment: .center),
            alignment: .center
        )
        
        hstack(backButton,
               middleStack,
               flagButton
        ).withMargins(.init(top: 0, left: 16, bottom: 0, right: 16))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
