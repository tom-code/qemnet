//
//  qmp.swift
//  qemnet
//
//  Created by tom on 15.04.2022.
//

import Foundation

class Err : Error {

}

func getJsonPar(json: Any, path: String) -> Any? {
    let pathspl = path.split(separator: "/")
    var cur = json
    var idx = 0
    for segment in pathspl {
        let current = cur as? [String: Any]
        if current == nil {
            return nil
        } else {
            let curtmp = current![String(segment)]
            if curtmp == nil {
                return nil
            }
            cur = curtmp!
        }
        idx = idx + 1
    }
    return cur
}

func getJsonParString(json: Any, path: String) -> String? {
    let out = getJsonPar(json: json, path: path)
    return out as? String
}


/*func dectest() {
    do {
        let d = try JSONSerialization.jsonObject(with: "{\"aaa\": true, \"bb\": {\"cc\": \"ooo\"}}".data(using: .utf8)!)
        print(d)
        //throw Err()
        let t = d as? [String: Any]
        print(t!)
        print(t!["aaa"]!)
        print(getJsonPar(json: d, path: "aaa"))
        print(getJsonPar(json: d, path: "bb/cc/a"))
        let z = getJsonPar(json: d, path: "bb/cc/a")
        print(z as? String == "<none>")
    } catch {
        print(error)
    }
}
*/
