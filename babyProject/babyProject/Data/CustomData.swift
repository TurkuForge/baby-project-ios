//
//  CustomData.swift
//  babyProject
//
//  Created by Otto Linden on 24.4.2021.
//

import Foundation
import MessageKit

struct bpRootResponse: Codable {
    let embedded: bpEmbedded
    let links: bpLinks

    enum CodingKeys: String, CodingKey {
        case embedded = "_embedded"
        case links = "_links"
    }
}

struct bpEmbedded: Codable {
    let channelList: [bpChannel]

    enum CodingKeysOld: String, CodingKey {
        case channelList = "bp:channelList"
    }

    enum CodingKeysNew: String, CodingKey {
        case channelList = "bp:channel"
    }

    init(from decoder: Decoder) throws {
        let containerOld = try decoder.container(keyedBy: CodingKeysOld.self)
        let containerNew = try decoder.container(keyedBy: CodingKeysNew.self)

        if let decodedChannelList = try containerOld.decodeIfPresent([bpChannel].self, forKey: CodingKeysOld.channelList) {
            channelList = decodedChannelList
        } else if let decodedChannelList = try containerNew.decodeIfPresent([bpChannel].self, forKey: CodingKeysNew.channelList) {
            channelList = decodedChannelList
        } else {
            throw DecodingError()
        }
    }
}

struct bpChannelList: Codable {
    let channels: [bpChannel]
}

struct bpChannel: Codable {
    let name: String
    let subscription: String
    let links: bpLinks

    enum CodingKeys: String, CodingKey {
        case name, subscription
        case links = "_links"
    }
}

struct bpLinks: Codable {
    let sockJsEndpoint: bpSelf?
    let linkSelf: bpSelf?
    let curies: [bpCuries]?

    enum CodingKeys: String, CodingKey {
        case sockJsEndpoint = "bp:sockjs-endpoint"
        case linkSelf = "self"
        case curies
    }
}

struct bpSelf: Codable {
    let href: URL
}

struct bpSockjsEndpoint: Codable {
    let href: String
}

struct bpCuries: Codable {
    let href: String
    let name: String
    let templated: Bool
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct RecivedMessage: Codable {
    var date: Date
    var from: String
    var message: String

    init(_ dict: [String:Any]) {
        var dateAsDouble = dict["date"] as? Double ?? NSTimeIntervalSince1970
        date = NSDate(timeIntervalSince1970: dateAsDouble) as Date
        from = dict["from"] as? String ?? ""
        message = dict["message"] as? String ?? ""
    }
}

struct DecodingError: Error {}
