//
//  MatchesMessagesController.swift
//  TinderCloneFireStoreLBTA
//
//  Created by Alok Acharya on 6/6/20.
//  Copyright © 2020 Alok Acharya. All rights reserved.
//

import LBTATools
import Firebase

struct Match {
    let name, profileImageUrl: String
    
    init(dictionary: [String: Any]){
        self.name = dictionary["name"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
    }
}

class MatchCell: LBTAListCell<Match> {
    
    let profileImageView = UIImageView(image: #imageLiteral(resourceName: "jane3"), contentMode: .scaleAspectFill)
    let usernameLabel = UILabel(text: "Username here", font: .systemFont(ofSize: 14, weight: .semibold), textColor: .darkGray, textAlignment: .center, numberOfLines: 2)
    
    override var item: Match!{
        didSet{
            usernameLabel.text = item.name
            profileImageView.sd_setImage(with: URL(string: item.profileImageUrl))
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        profileImageView.clipsToBounds = true
        profileImageView.constrainWidth(80)
        profileImageView.constrainHeight(80)
        profileImageView.layer.cornerRadius = 80 / 2
        
        stack(stack(profileImageView, alignment: .center), usernameLabel)
    }
    
}



class MatchesMessagesController: LBTAListController<MatchCell, Match>, UICollectionViewDelegateFlowLayout{
    
    let customNavBar = MatchesNavBar()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 120, height: 140)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = items[indexPath.item]
        let chatLogController = ChatLogController(match: match)
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white

        fetchMatches()
        
        customNavBar.backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        view.addSubview(customNavBar)
        customNavBar.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: 0, height: 150))
        
        collectionView.contentInset.top = 150
    }
    
    fileprivate func fetchMatches(){
        guard let currentUseerId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("matches_messages").document(currentUseerId).collection("matches").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Failed to fetch matches, ",err)
                return
            }
            
            print("Here are my match documents")
            
            var matches = [Match]()
            
            querySnapshot?.documents.forEach({ (documentSnapshot) in
                let dictionary = documentSnapshot.data()
                matches.append(.init(dictionary: dictionary))
            })
            
            self.items = matches
            self.collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    @objc fileprivate func handleBack(){
        navigationController?.popToRootViewController(animated: true)
    }
    
}
