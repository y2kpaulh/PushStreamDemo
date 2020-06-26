//
//  SocketIOManager.swift
//  ChatTest
//
//  Created by Inpyo Hong on 2020/06/12.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SocketIO

protocol ServerInfo {
  var serverUrl: String? { get }
  var chatRoom: String? { get }
  var chatMsgArray: [ChatMessage]? { get }
  var connectedUsers: [ChatUser]? { get }
}

class ChatServerInfo: ServerInfo {
  let serverUrl: String?
  let chatRoom: String?
  var chatMsgArray: [ChatMessage]?
  var connectedUsers: [ChatUser]?

  init(serverUrl: String?, chatRoom: String?, chatMsgArray: [ChatMessage], connectedUsers: [ChatUser]) {
    self.serverUrl = serverUrl
    self.chatRoom = chatRoom
    self.chatMsgArray = chatMsgArray
    self.connectedUsers = connectedUsers
  }
}

class ChatSocketIOManager {
  var socket: SocketIOClient!
  var manager: SocketManager!
  let chatServerInfo: ChatServerInfo

  //    private var onNewMessageCode: ((ChatMessage) -> Void)?
  //    private var onTypingStatusCode: (() -> Void)?
  private var connectedUsers: [ChatUser] = []

  let disposeBag = DisposeBag()

  init(serverInfo: ChatServerInfo) {
    chatServerInfo = serverInfo
    manager = SocketManager(socketURL: URL(string: chatServerInfo.serverUrl!)!, config: [.log(true), .compress])
    socket = manager.socket(forNamespace: "/\(serverInfo.chatRoom!)")

    print(serverInfo.chatRoom!)
  }

  func establishConnection() {
    socket.connect()
  }

  func closeConnection() {
    socket.disconnect()
  }

  func sendMessage(chatMsg: ChatMessage) {
    switch chatMsg.kind {
    case .text(let data):
      let textMessage: String = data
      let date = chatMsg.sentDate as NSDate
      //            socket.emitWithAck(chatServerInfo.chatRoom!, ["msgId": chatMsg.messageId, "userId": chatMsg.user.senderId, "userName": chatMsg.user.displayName, "sentDate": date.toLocalTimeString(), "msg": textMessage, "msgType": "text"]).timingOut(after: 0.2) { data in
      //                self.socket.emit(self.chatServerInfo.chatRoom!, data)
      //            }
      socket.emit(chatServerInfo.chatRoom!, ["msgId": chatMsg.messageId, "userId": chatMsg.user.senderId, "userName": chatMsg.user.displayName, "sentDate": date.toLocalTimeString(), "msg": textMessage, "msgType": "text"])

    default:
      break
    }
  }
}
