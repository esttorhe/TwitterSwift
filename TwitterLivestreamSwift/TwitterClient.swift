//
//  TwitterClient.swift
//  TwitterLivestreamSwift
//
//  Created by Benjamin Encz on 1/25/15.
//  Copyright (c) 2015 Benjamin Encz. All rights reserved.
//

import PromiseKit
import Foundation
import Accounts
import SwifteriOS
import Alamofire

func fetchTweets(amount:Int = 50) -> Promise<[Tweet]> {
  return login().then(body: {swifter in
    return loadTweets(swifter, amount)
  })
}

func fetchImage(urlString:String) -> Promise<UIImage> {
  return Promise { (fulfill, reject) in
      Alamofire.download(.GET, urlString, { (temporaryURL, response) in
        if let directoryURL = NSFileManager.defaultManager()
          .URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask)[0]
          as? NSURL {
            let pathComponent = response.suggestedFilename
            let url = directoryURL.URLByAppendingPathComponent(pathComponent!)
            let imageData = NSData(contentsOfURL: url)
            if let imageData = imageData {
              let image = UIImage(data: imageData)
              if let image = image {
                fulfill(image)
              } else {
                reject(NSError(domain: "", code: 0, userInfo: nil))
              }
            } else {
              reject(NSError(domain: "", code: 0, userInfo: nil))
            }
            
            return url
        }
        
        let imageData = NSData(contentsOfURL: temporaryURL)!
        let image = UIImage(data: imageData)!
        fulfill(image)
        
        return temporaryURL
      })
      return
  }
}

private func login() -> Promise<Swifter> {
  let accountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
  let accountStore = ACAccountStore()
  
  return Promise { (fulfiller, _) in
    accountStore.requestAccessToAccountsWithType(accountType, options: nil) { (t:Bool, e:NSError!) -> Void in
      // TODO: check if account actually exists
      let accounts = accountStore.accountsWithAccountType(accountType) as [ACAccount]
      let swifter = Swifter(account: accounts[0])
      fulfiller(swifter)
    }
  }
}

private func loadTweets(swifter:Swifter, amount:Int) -> Promise<[Tweet]> {
  return Promise { (fulfiller, _) in

    swifter.getStatusesHomeTimelineWithCount(amount, sinceID: nil, maxID: nil, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: { (statuses) -> Void in
        fulfiller(parseTweets(statuses!))
      }, failure: { (error) -> Void in
    })
  }
}

private func parseTweets(tweets: [JSONValue]) -> [Tweet] {
  return tweets.map({ tweet in
    let user = User (
      profileImageURL:tweet["user"]["profile_image_url"].string!,
      identifier: tweet["user"]["id_str"].string!,
      name: tweet["user"]["name"].string!
    )
    
    return Tweet(
      content: tweet["text"].string!,
      retweetCount: tweet["retweet_count"].integer!,
      identifier: tweet["id_str"].string!,
      user: user
    )
  })
}