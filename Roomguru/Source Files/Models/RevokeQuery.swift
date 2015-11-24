//
//  RevokeQuery.swift
//  Roomguru
//
//  Created by Radoslaw Szeja on 01/04/15.
//  Copyright (c) 2015 Netguru Sp. z o.o. All rights reserved.
//

import Foundation
import Alamofire

struct RevokeQuery: Query {
    
    let method: Method = .DELETE
    let path: String
    var parameters: Parameters? = Parameters(encoding: Parameters.Encoding.URL)
    let service: SecureNetworkService = GoogleCalendarService()
    
    init(eventID: String, userEmail: String) {
        path = "/calendars/" + userEmail + "/events/" + eventID
    }
}
