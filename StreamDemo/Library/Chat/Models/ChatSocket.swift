/*
 MIT License

 Copyright (c) 2017-2019 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import MessageKit

final class ChatSocket {
  static var shared = ChatSocket()

  private var queuedMessage: ChatMessage?

  private var onNewMessageCode: ((ChatMessage) -> Void)?

  private var onTypingStatusCode: (() -> Void)?

  private var connectedUsers: [ChatUser] = []

  private init() {}

  @discardableResult
  func connect(with senders: [ChatUser]) -> Self {
    disconnect()
    connectedUsers = senders
    return self
  }

  @discardableResult
  func disconnect() -> Self {
    onTypingStatusCode = nil
    onNewMessageCode = nil
    return self
  }

  @discardableResult
  func onNewMessage(code: @escaping (ChatMessage) -> Void) -> Self {
    onNewMessageCode = code
    return self
  }

  @discardableResult
  func onTypingStatus(code: @escaping () -> Void) -> Self {
    onTypingStatusCode = code
    return self
  }

}
