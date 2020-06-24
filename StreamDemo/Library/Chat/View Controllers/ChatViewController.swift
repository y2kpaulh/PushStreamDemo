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
import InputBarAccessoryView
import RxSwift
import RxCocoa

/// A base class for the example controllers
class ChatViewController: MessagesViewController, MessagesDataSource {

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
  }()

  let chatServerUrl = "http://192.168.1.140:3000"
  let chatRoom = "test"

  var viewModel: ChatRoomViewModel!
  var userInfo: ChatUser = ChatUser(senderId: "000000", displayName: "Steve Jobs")

  let refreshControl = UIRefreshControl()

  override func viewDidLoad() {
    super.viewDidLoad()

    configureMessageCollectionView()
    configureMessageInputBar()

    //        userInfo = ChatUser(senderId: "000000", displayName: "Inpyo Hong")

    viewModel = ChatRoomViewModel()
    viewModel.configChatServer(chatServerUrl: self.chatServerUrl, chatRoom: self.chatRoom, chatMsgArray: [], chatUsers: [userInfo, SampleData.shared.nathan])
    viewModel.chatMsgData.asObservable().subscribe(onNext: { [weak self] chatMsg in
      guard let self = self else { return }
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.insertMessage(chatMsg)
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }).disposed(by: viewModel.disposeBag)

    // loadFirstMessages()

    title = chatRoom
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    viewModel.chatServerManager.establishConnection()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    viewModel.chatServerManager.closeConnection()
  }

  func loadFirstMessages() {
    DispatchQueue.global(qos: .userInitiated).async {
      //            SampleData.shared.getMessages(count: count) { messages in
      //                DispatchQueue.main.async {
      //                    //self.viewModel.messageList = messages
      //                    self.viewModel.loadData.on(.next(messages))
      //                    self.messagesCollectionView.reloadData()
      //                    self.messagesCollectionView.scrollToBottom()
      //                }
      //            }
    }
  }

  @objc
  func loadMoreMessages() {
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
      SampleData.shared.getMessages(count: 20) { messages in
        DispatchQueue.main.async {
          //self.viewModel.messageList.insert(contentsOf: messages, at: 0)
          self.viewModel.loadMoreData.on(.next(messages))
          self.messagesCollectionView.reloadDataAndKeepOffset()
          self.refreshControl.endRefreshing()
        }
      }
    }
  }

  func configureMessageCollectionView() {
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messageCellDelegate = self

    scrollsToBottomOnKeyboardBeginsEditing = true // default false
    maintainPositionOnKeyboardFrameChanged = true // default false

    messagesCollectionView.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
  }

  func configureMessageInputBar() {
    messageInputBar.delegate = self
    messageInputBar.inputTextView.tintColor = .primaryColor
    messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
    messageInputBar.sendButton.setTitleColor(
      UIColor.primaryColor.withAlphaComponent(0.3),
      for: .highlighted
    )
  }

  // MARK: - Helpers

  func insertMessage(_ message: ChatMessage) {
    viewModel.loadMoreData.on(.next([message]))
    // Reload last section to update header/footer labels and insert a new one
    messagesCollectionView.performBatchUpdates({
      messagesCollectionView.insertSections([viewModel.messageList.count - 1])
      if viewModel.messageList.count >= 2 {
        messagesCollectionView.reloadSections([viewModel.messageList.count - 2])
      }
    }, completion: { [weak self] _ in
      if self?.isLastSectionVisible() == true {
        self?.messagesCollectionView.scrollToBottom(animated: true)
      }
    })
  }

  func isLastSectionVisible() -> Bool {
    guard !viewModel.messageList.isEmpty else { return false }
    let lastIndexPath = IndexPath(item: 0, section: viewModel.messageList.count - 1)
    return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
  }

  // MARK: - MessagesDataSource

  func currentSender() -> SenderType {
    return userInfo
  }

  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return viewModel.messageList.count
  }

  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return viewModel.messageList[indexPath.section]
  }

  func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    if indexPath.section % 3 == 0 {
      return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    return nil
  }

  func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

    return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
  }

  func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    let name = message.sender.displayName
    return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
  }

  func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

    let dateString = formatter.string(from: message.sentDate)
    return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
  }

}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {

  func didTapAvatar(in cell: MessageCollectionViewCell) {
    print("Avatar tapped")
  }

  func didTapMessage(in cell: MessageCollectionViewCell) {
    print("Message tapped")
  }

  func didTapImage(in cell: MessageCollectionViewCell) {
    print("Image tapped")
  }

  func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
    print("Top cell label tapped")
  }

  func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
    print("Bottom cell label tapped")
  }

  func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
    print("Top message label tapped")
  }

  func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
    print("Bottom label tapped")
  }

  func didStartAudio(in cell: AudioMessageCell) {
    print("Did start playing audio sound")
  }

  func didPauseAudio(in cell: AudioMessageCell) {
    print("Did pause audio sound")
  }

  func didStopAudio(in cell: AudioMessageCell) {
    print("Did stop audio sound")
  }

  func didTapAccessoryView(in cell: MessageCollectionViewCell) {
    print("Accessory view tapped")
  }

}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {

  func didSelectAddress(_ addressComponents: [String: String]) {
    print("Address Selected: \(addressComponents)")
  }

  func didSelectDate(_ date: Date) {
    print("Date Selected: \(date)")
  }

  func didSelectPhoneNumber(_ phoneNumber: String) {
    print("Phone Number Selected: \(phoneNumber)")
  }

  func didSelectURL(_ url: URL) {
    print("URL Selected: \(url)")
  }

  func didSelectTransitInformation(_ transitInformation: [String: String]) {
    print("TransitInformation Selected: \(transitInformation)")
  }

  func didSelectHashtag(_ hashtag: String) {
    print("Hashtag selected: \(hashtag)")
  }

  func didSelectMention(_ mention: String) {
    print("Mention selected: \(mention)")
  }

  func didSelectCustom(_ pattern: String, match: String?) {
    print("Custom data detector patter selected: \(pattern)")
  }

}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

  func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

    // Here we can parse for which substrings were autocompleted
    let attributedText = messageInputBar.inputTextView.attributedText!
    let range = NSRange(location: 0, length: attributedText.length)
    attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
      let substring = attributedText.attributedSubstring(from: range)
      let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
      print("Autocompleted: `", substring, "` with context: ", context ?? [])
    }

    let components = inputBar.inputTextView.components
    messageInputBar.inputTextView.text = String()
    messageInputBar.invalidatePlugins()

    // Send button activity animation
    messageInputBar.sendButton.startAnimating()
    messageInputBar.inputTextView.placeholder = "Sending..."
    DispatchQueue.global(qos: .default).async {
      // fake send request task
      sleep(1)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.messageInputBar.sendButton.stopAnimating()
        self.messageInputBar.inputTextView.placeholder = "Aa"
        self.insertMessages(components)
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }

  private func insertMessages(_ data: [Any]) {
    for component in data {
      //   let user = self.currentSender
      if let str = component as? String {
        let message = ChatMessage(text: str, user: userInfo, messageId: UUID().uuidString, date: Date())
        viewModel.chatServerManager.sendMessage(chatMsg: message)
      } else if let img = component as? UIImage {
        let message = ChatMessage(image: img, user: userInfo, messageId: UUID().uuidString, date: Date())
        insertMessage(message)
      }
    }
  }
}
