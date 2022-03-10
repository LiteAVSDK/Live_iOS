//
//  MainMenuItemModel.swift
//  TRTCScene
//
//  Created by adams on 2021/5/11.
//
import UIKit

struct MainMenuItemModel {
    let imageName: String
    let title: String
    let content: String
    let selectHandle: () -> Void
    let type: RoomType
    
    var iconImage: UIImage? {
        UIImage.init(named: imageName)
    }
    
    init(imageName: String, title: String, content: String, type: RoomType = .other, selectHandle: @escaping () -> Void) {
        self.imageName = imageName
        self.title = title
        self.content = content
        self.selectHandle = selectHandle
        self.type = type
    }
}
