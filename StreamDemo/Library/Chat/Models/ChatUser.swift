//
//  ChatUser.swift
//  ChatTest
//
//  Created by Inpyo Hong on 2020/06/22.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import Foundation
import MessageKit

struct ChatUser: SenderType, Equatable {
  var profileImgUrl: String?
  var senderId: String
  var displayName: String
}
