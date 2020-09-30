//
//  MatchView.swift
//  TinderCloneFireStoreLBTA
//
//  Created by Alok Acharya on 6/4/20.
//  Copyright © 2020 Alok Acharya. All rights reserved.
//

import UIKit
import Firebase

class MatchView: UIView {
    
    var currentUser: User! {
        didSet{
        }
    }
    
    //you're almost always guaranteed to have this variable set up
    var cardUID: String! {
        didSet{
            //either fetch current user inside here or pass in our current user if we have it
            
            
            //fetch cardUID info
            let query = Firestore.firestore().collection("users")
            query.document(cardUID).getDocument { (snapshot, err) in
                if let err = err {
                    print("Failed to fetch card user:", err)
                    return
                }
                
                guard let dictionary = snapshot?.data() else { return }
                let user = User(dictionary: dictionary)
                guard let url = URL(string: user.imageUrl1 ?? "") else { return }
                self.cardUserImageView.sd_setImage(with: url)
                
                guard let currentUserImageURL = URL(string: self.currentUser.imageUrl1 ?? "") else { return }
                
                self.currentUserImage.sd_setImage(with: currentUserImageURL) { (_, _, _, _) in
                    self.setupanimations()
                }
                
                self.descriptionLabel.text = "You and \(String(user.name!)) have liked\neach other!"
            }
        }
    }
    
    fileprivate let itsAMatchImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "itsamatch"))
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    fileprivate let descriptionLabel: UILabel = {
       let label = UILabel()
        label.text = "You and X have liked\neach other"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        return label
    }()
    
    fileprivate let currentUserImage: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "kelly1"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()
    
    fileprivate let cardUserImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "jane3"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.alpha = 0
        return imageView
    }()
    
    fileprivate let sendMessageBtn: UIButton = {
        let button = SendMessageBtn(type: .system)
        button.setTitle("Send Message", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    fileprivate let keepSwipingBtn: UIButton = {
        let button = KeepSwipingBtn(type: .system)
        button.setTitle("Keep Swiping", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupBlurView()
        setupLayout()
        
        keepSwipingBtn.addTarget(self, action: #selector(handleTapDismiss), for: .touchUpInside)
    }
    
    fileprivate func setupanimations(){
        
        views.forEach({$0.alpha = 1})
        
        // starting positions
        let angle = 30 * CGFloat.pi / 180
        
        currentUserImage.transform = CGAffineTransform(rotationAngle: -angle).concatenating(CGAffineTransform(translationX: 200, y: 0))
        cardUserImageView.transform = CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: -200, y: 0))
        
        //buttons
        sendMessageBtn.transform = CGAffineTransform(translationX: -500, y: 0)
        keepSwipingBtn.transform = CGAffineTransform(translationX: 500, y: 0)
        
        //keyframe animations for segmented animations
        UIView.animateKeyframes(withDuration: 1.3, delay: 0, options: .calculationModeCubic, animations: {
            
            //animation 1 - translation
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.45) {
                self.currentUserImage.transform = CGAffineTransform(rotationAngle: -angle)
                self.cardUserImageView.transform = CGAffineTransform(rotationAngle: angle)
            }
            
            //animation 2 - rotation
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.currentUserImage.transform = .identity
                self.cardUserImageView.transform = .identity
                
                
            }
            
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                self.sendMessageBtn.transform = .identity
                self.keepSwipingBtn.transform = .identity
            })
        }
    }
    
    lazy var views = [
        itsAMatchImageView,
        descriptionLabel,
        currentUserImage,
        cardUserImageView,
        sendMessageBtn,
        self.keepSwipingBtn
    ]
    
    fileprivate func setupLayout(){
        
        views.forEach { (v) in
            addSubview(v)
            v.alpha = 0
        }
        
        let imageWidth: CGFloat = 140
        
        
        itsAMatchImageView.anchor(top: nil, leading: nil, bottom: descriptionLabel.topAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 16, right: 0), size: .init(width: 300, height: 80))
        itsAMatchImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        descriptionLabel.anchor(top: nil, leading: self.leadingAnchor, bottom: currentUserImage.topAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 32, right: 0), size: .init(width: 0, height: 50))
        
        currentUserImage.anchor(top: nil, leading: nil, bottom: nil, trailing: centerXAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16), size: .init(width: imageWidth, height: imageWidth))
        currentUserImage.layer.cornerRadius = imageWidth / 2
        currentUserImage.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        cardUserImageView.anchor(top: nil, leading: centerXAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0), size: .init(width: imageWidth, height: imageWidth))
        cardUserImageView.layer.cornerRadius = imageWidth / 2
        cardUserImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        sendMessageBtn.anchor(top: currentUserImage.bottomAnchor, leading: self.leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 32, left: 48, bottom: 0, right: 48), size: .init(width: 0, height: 60))
        
        keepSwipingBtn.anchor(top: sendMessageBtn.bottomAnchor, leading: sendMessageBtn.leadingAnchor, bottom: nil, trailing: sendMessageBtn.trailingAnchor, padding: .init(top: 16, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 60))
    }
    
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    fileprivate func setupBlurView(){
        visualEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
        
        addSubview(visualEffectView)
        visualEffectView.fillSuperview()
        visualEffectView.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.visualEffectView.alpha = 1
        }) { (_) in
            
        }
    }
    
    @objc fileprivate func handleTapDismiss(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            self.alpha = 0
        }) { (_) in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
