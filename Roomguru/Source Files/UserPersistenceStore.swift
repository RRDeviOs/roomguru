//
//  UserPersistenceStore.swift
//  Roomguru
//
//  Created by Patryk Kaczmarek on 13/04/15.
//  Copyright (c) 2015 Netguru Sp. z o.o. All rights reserved.
//

import Foundation
import SwiftyUserDefaults
import CryptoSwift

private protocol Persistence {
    
    func save()
    func clear() -> Bool
    func load() -> User?
}

class UserPersistenceStore {
    
    class var sharedStore: UserPersistenceStore {
        struct Static {
            static let instance: UserPersistenceStore = UserPersistenceStore()
        }
        return Static.instance
    }
    
    private let size: Int = 150
    private let downloader = UserImageDownloader()
    private let diskManager = UserDiskManager()
    
    private(set) var user: User? = nil

    init() {
        self.user = load()
    }
    
    func registerUserWithEmail(email: String) {

        //do nothing if already exist
        if user?.email == email {
            return
        }
        
        clear()
        self.user = User(email: email)
        self.save()
        
        if !shouldDownloadImage() {
            return
        }
        
        storeImageWithCompletionBlock { (success: Bool, url: String) in
            if success {
                self.downloadImageFromURL(fromURL: url)
            }
        }
    }
    
    func userImage() -> UIImage? {
        if let id = hash() {
            if let data = diskManager.loadProfileImageWithIdentifier(id), image = UIImage(data: data) {
                return image
            }
        }
        return UIImage(named: "placeholder")
    }
}

// MARK: Private

private extension UserPersistenceStore {
    
    func shouldDownloadImage() -> Bool {
        if let id = hash() {
            return !self.diskManager.existFileWithIdentifier(id)
        }
        return true
    }
    
    func storeImageWithCompletionBlock(completion: (success: Bool, url: String) -> Void) {
        
        let query = GTLQueryPlus.queryForPeopleGetWithUserId("me") as! GTLQueryPlus
        let plusService = GTLServicePlus()
        plusService.retryEnabled = true
        plusService.authorizer = GPPSignIn.sharedInstance().authentication
        
        plusService.executeQuery(query) { (_, person, _) in
            
            if let _person = person as? GTLPlusPerson {
                completion(success: true, url: _person.image.url)
            } else {
                completion(success: false, url: "")
            }
        }
    }
    
    func downloadImageFromURL(var fromURL url: String) {
        
        if let range = url.rangeOfString("sz=") {
            
            url = url.substringWithRange(Range<String.Index>(start: url.startIndex , end: range.startIndex)) + "sz=" + String(size)
            self.downloader.downloadFileFromUrl(url) { (locationURL) -> Void in
                
                if let _locationURL = locationURL, id = self.hash() {
                    self.diskManager.saveProfileImage(_locationURL, forIdentifier: id)
                }
            }
        }
    }
    
    func hash() -> String? {
        return user?.email.lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).md5()
    }
    
}

// MARK: Persistance

extension UserPersistenceStore: Persistence {
    
    func save() {
        if let _user = user {
            Defaults[User.key] = NSKeyedArchiver.archivedDataWithRootObject(_user)
            Defaults.synchronize()
        }        
    }
    
    func clear() -> Bool {
        if Defaults.hasKey(User.key) {
            Defaults.remove(User.key)
            Defaults.synchronize()
            user = nil
            return true
        }
        return false
    }
    
    func load() -> User? {
        if let data = Defaults[User.key].data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? User
        }
        return nil
    }
}
