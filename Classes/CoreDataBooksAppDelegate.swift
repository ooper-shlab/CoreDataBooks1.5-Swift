//
//  CoreDataBooksAppDelegate.swift
//  CoreDataBooks
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/09/09.
//
//
/*
     File: CoreDataBooksAppDelegate.h
     File: CoreDataBooksAppDelegate.m
 Abstract: Application delegate to set up the Core Data stack and configure the first view and navigation controllers.
  Version: 1.5

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2014 Apple Inc. All Rights Reserved.

 */
import UIKit
import CoreData

@UIApplicationMain
@objc(CoreDataBooksAppDelegate)
class CoreDataBooksAppDelegate:  NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private var managedObjectModel: NSManagedObjectModel {
        return getManagedObjectModel()
    }
    private var managedObjectContext: NSManagedObjectContext{
        return getManagedObjectContext()
    }
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator! {
        return getPersistentStoreCoordinator()
    }
    
    
    //MARK: -
    //MARK: - Application lifecycle
    
    func applicationDidFinishLaunching(application: UIApplication) {
        let navigationController = self.window!.rootViewController as! UINavigationController
        let rootViewController = navigationController.viewControllers[0] as! RootViewController
        rootViewController.managedObjectContext = self.managedObjectContext
    }
    
    func applicationWillTerminalte(application: UIApplication) {
        self.saveContext()
    }
    
    func applicationWillResignActive(application: UIApplication) {
        self.saveContext()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        self.saveContext()
    }
    
    private func saveContext() {
        if _managedObjectContext != nil && _managedObjectContext!.hasChanges {
            do {
                try _managedObjectContext!.save()
            } catch let error as NSError {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                */
                NSLog("Unresolved error %@, %@", error, error.userInfo)
                abort()
            } catch _ {
                fatalError()
            }
        }
    }
    
    
    //MARK: - Core Data stack
    
    /*
    Returns the managed object context for the application.
    If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    */
    private var _managedObjectContext: NSManagedObjectContext? = nil
    private func getManagedObjectContext() -> NSManagedObjectContext {
        if _managedObjectContext != nil {
            return _managedObjectContext!
        }
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator != nil {
            _managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            _managedObjectContext!.persistentStoreCoordinator = coordinator
        }
        return _managedObjectContext!
    }
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    private var _managedObjectModel: NSManagedObjectModel? = nil
    private func getManagedObjectModel() -> NSManagedObjectModel {
        if _managedObjectModel != nil {
            return _managedObjectModel!
        }
        let modelURL = NSBundle.mainBundle().URLForResource("CoreDataBooks", withExtension: "momd")!
        _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        return _managedObjectModel!
    }
    
    /*
    Returns the persistent store coordinator for the application.
    If the coordinator doesn't already exist, it is created and the application's store added to it.
    */
    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
    private func getPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator != nil {
            return _persistentStoreCoordinator!
        }
        
        let storeURL = applicationDocumentsDirectory().URLByAppendingPathComponent("CoreDataBooks.CDBStore")
        
        /*
        Set up the store.
        For the sake of illustration, provide a pre-populated default store.
        */
        let fileManager = NSFileManager.defaultManager()
        // If the expected store doesn't exist, copy the default store.
        if !fileManager.fileExistsAtPath(storeURL.path!) {
            let defaultStoreURL = NSBundle.mainBundle().URLForResource("CoreDataBooks", withExtension: "CDBStore")
            if defaultStoreURL != nil {
                do {
                    try fileManager.copyItemAtURL(defaultStoreURL!, toURL: storeURL)
                } catch _ {
                }
            }
        }
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        do {
            try _persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        } catch let error as NSError {
            /*
            Replace this implementation with code to handle the error appropriately.
            
            abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            
            Typical reasons for an error here include:
            * The persistent store is not accessible;
            * The schema for the persistent store is incompatible with current managed object model.
            Check the error message to determine what the actual problem was.
            
            
            If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
            
            If you encounter schema incompatibility errors during development, you can reduce their frequency by:
            * Simply deleting the existing store:
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
            
            * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
            @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
            
            Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
            
            */
            NSLog("Unresolved error %@, %@", error, error.userInfo)
            abort()
        }
        
        return _persistentStoreCoordinator!
    }
    
    
    //MARK: - Application's documents directory
    
    // Returns the URL to the application's Documents directory.
    private func applicationDocumentsDirectory() -> NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
    }
    
}