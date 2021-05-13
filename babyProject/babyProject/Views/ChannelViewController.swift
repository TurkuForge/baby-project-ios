//
//  ChannelViewController.swift
//  babyProject
//
//  Created by Otto Linden on 24.4.2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Combine
import StompClientLib

class ChannelViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    private var cancellable: AnyCancellable?

    let currentUser = Sender(senderId: "1", displayName: "iOS-User-\(UUID().uuidString)")
    let otherUser = Sender(senderId: "2", displayName: "Greeter")
    var _messages = [Message]()
    var messages: [Message] {
        get {
            return _messages
        } set {
            _messages = newValue
            messagesCollectionView.reloadData()
        }
    }
    var channel: bpChannel?

    var socketClient = StompClientLib()
    lazy var url = NSURL(string: "https://api.turkuforge.fi/connect/websocket")!

    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url as URL) , delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }

    func currentSender() -> SenderType {
        return currentUser
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        print("here is message count \(messages.count) and messages \(messages)")
        return messages.count
    }

    func send(message: String) {
        if let url = channel?.links.linkSelf?.href {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let data = [
                "content": message,
                "sender": currentSender().displayName
            ]
            let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
            URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            }.resume()
        }
    }

    func received(message: RecivedMessage) {
        let message = Message(sender: Sender(senderId: message.from == currentUser.displayName ? "1" : "2", displayName: message.from), messageId: "2", sentDate: message.date, kind: .text(message.message))
        messages.append(message)
    }
}

extension ChannelViewController: StompClientLibDelegate {
    func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, akaStringBody stringBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
        let dict = jsonBody as? [String:Any] ?? [:]
        let message = RecivedMessage(dict)
        received(message: message)
        print("Stomp did receive message \(jsonBody)")
    }

    func stompClientDidDisconnect(client: StompClientLib!) {
        print("Stomp did disconnect")
    }

    func stompClientDidConnect(client: StompClientLib!) {
        socketClient.subscribe(destination: "\(channel!.subscription)")
        print("Stomp did connect")
    }

    func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
        print("Stomp did send receipt")
    }

    func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
        print("Stomp did send error \(description) and \(message)")
    }

    func serverDidSendPing() {
        print("Stomp did send ping")
    }
}

extension ChannelViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        send(message: text)
        inputBar.inputTextView.text = ""
    }
}
