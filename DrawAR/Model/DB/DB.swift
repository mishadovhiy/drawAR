//
//  DataBase.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import Foundation

struct DB {
    static var holder: DataBase?
    static var db:DataBase {
        get {
            return holder ?? .init(dict: (UserDefaults.standard.value(forKey: "DataBase") as? [String:Any] ?? [:]))
        }
        set {
            holder = newValue
            if Thread.isMainThread {
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    UserDefaults.standard.setValue(newValue.dict, forKey: "DataBase")
                }
            } else {
                UserDefaults.standard.setValue(newValue.dict, forKey: "DataBase")
            }
        }
    }
}

extension DB {
    struct DataBase {
        var dict:[String:Any]
        init(dict: [String : Any]) {
            self.dict = dict
        }
        
    }
}
