//
//  ChatRoomViewModel.swift
//  ChatTest
//
//  Created by Inpyo Hong on 2020/06/22.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Swinject
import SocketIO

class ChatRoomViewModel {
  var chatServerManager: ChatSocketIOManager!
  let disposeBag = DisposeBag()

  var messageList = [ChatMessage]()
  var chatMsgData: PublishRelay<ChatMessage> = PublishRelay.init()

  let loadData: PublishSubject<[ChatMessage]> = PublishSubject.init()
  let loadMoreData: PublishSubject<[ChatMessage]> = PublishSubject.init()

  func configChatServer(chatServerUrl: String, chatRoom: String, chatMsgArray: [ChatMessage], chatUsers: [ChatUser]) {
    let container = Container()
    container.register(ChatServerInfo.self) { _ in ChatServerInfo(serverUrl: chatServerUrl, chatRoom: chatRoom, chatMsgArray: chatMsgArray, connectedUsers: chatUsers) }
    container.register(ChatSocketIOManager.self) { r in
      ChatSocketIOManager(serverInfo: r.resolve(ChatServerInfo.self)!)
    }

    chatServerManager = container.resolve(ChatSocketIOManager.self)

    self.loadData.asObservable().subscribe(onNext: { [weak self] newChatMsg in
      self?.messageList = newChatMsg
    }).disposed(by: disposeBag)

    self.loadMoreData.asObservable().subscribe(onNext: { [weak self] newChatMsg in
      self?.messageList.append(contentsOf: newChatMsg)
    }).disposed(by: disposeBag)

    self.loadData.on(.next(chatMsgArray))

    bindChatRoomMsg(chatRoom)
  }

  func bindChatRoomMsg(_ chatRoom: String) {
    chatServerManager.socket.on(chatRoom) { (dataArray, socketAck) in
      print("rcv data", dataArray, "socketAck", socketAck)
      print(type(of: dataArray))

      guard let rcvData = dataArray[0] as? NSDictionary, let data = rcvData["message"] as? NSDictionary, let date = data["sentDate"] as? String, let sentDate = date.toDate() as Date?, let userId = data["userId"] as? String, let userName = data["userName"] as? String, let msg = data["msg"] as? String, let msgId = data["msgId"] as? String else { return }

      let userInfo = ChatUser(senderId: userId, displayName: userName)
      let chatMsg = ChatMessage(text: msg, user: userInfo, messageId: msgId, date: sentDate)

      self.chatMsgData.accept(chatMsg)
    }
  }
}
