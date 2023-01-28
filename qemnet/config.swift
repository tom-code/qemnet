//
//  config.swift
//  qemnet
//
//  Created by tom on 05.04.2022.
//

import Foundation


struct NetLink: Decodable {
    enum Typex: String, Decodable {
        case host, shared, bridged
    }
    let id: String
    let local_port: Int
    let remote_port: Int
    let type: Typex?
    let parent: String?
    let device: String?
    let netid: String?
    let hwaddr: String?
}

struct VMConfig: Decodable {
    let links: [NetLink]
    let verbose: Bool?
    let image: String?
    let ram: Int
    let cores: Int?
    let kernel: String?
    let architecture: String?
    let machine: String?
    let accel: String?
    let args: String?
    let args2: [String]?
}

func config_decode(filename: String) -> VMConfig? {
    do {
        let d = try Data.init(contentsOf: URL.init(fileURLWithPath: filename))
        let config = try JSONDecoder().decode(VMConfig.self, from: d)
        print(config)
        return config
    } catch let error as NSError {
        print("can't read config \(error)")
    }
    return nil
}
