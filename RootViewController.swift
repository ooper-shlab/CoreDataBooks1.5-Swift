//
//  RootViewController.swift
//  CoreDataBooks
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/09/07.
//
//
/*
     File: RootViewController.h
     File: RootViewController.m
 Abstract:  Abstract: The table view controller responsible for displaying the list of books, supporting additional functionality:

 * Drill-down to display more information about a selected book using an instance of DetailViewController;
 * Addition of new books using an instance of AddViewController;
 * Deletion of existing books using UITableView's tableView:commitEditingStyle:forRowAtIndexPath: method.

 The root view controller creates and configures an instance of NSFetchedResultsController to manage the collection of books.  The view controller's managed object context is supplied by the application's delegate. When the user adds a new book, the root view controller creates a new managed object context to pass to the add view controller; this ensures that any changes made in the add controller do not affect the main managed object context, and they can be committed or discarded as a whole.

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

@objc(RootViewController)
class RootViewController:  UITableViewController, NSFetchedResultsControllerDelegate, AddViewControllerDelegate {
    
    var managedObjectContext: NSManagedObjectContext?
    
    private var _fetchedResultsController: NSFetchedResultsController?
    private var fetchedResultsController: NSFetchedResultsController {
        get {
            return getFetchedResultsController()
        }
        set {
            _fetchedResultsController = newValue
        }
    }
    private var rightBarButtonItem: UIBarButtonItem?
    
    
    //MARK: -
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set up the edit and add buttons.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch let error as NSError {
            /*
            Replace this implementation with code to handle the error appropriately.
            
            abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            */
            NSLog("Unresolved error %@, %@", error, error.userInfo)
            abort()
        }
    }
    
    
    //MARK: - Table view data source methods
    
    // The data source methods are handled primarily by the fetch results controller
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.fetchedResultsController.sections!.count
    }
    
    // Customize the number of rows in the table view.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    // Customize the appearance of table view cells.
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        // Configure the cell to show the book's title
        let book = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Book
        cell.textLabel?.text = book.title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let CellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell?
        
        // Configure the cell.
        configureCell(cell!, atIndexPath: indexPath)
        return cell!
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // Display the authors' names as section headings.
        return self.fetchedResultsController.sections![section].name
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            // Delete the managed object.
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            do {
                try context.save()
            } catch let error as NSError {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                */
                NSLog("Unresolved error %@, %@", error, error.userInfo)
                abort()
            }
        }
    }
    
    
    //MARK: - Table view editing
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        // The table view should not be re-orderable.
        return false
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if editing {
            self.rightBarButtonItem = self.navigationItem.rightBarButtonItem
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.navigationItem.rightBarButtonItem = self.rightBarButtonItem
            self.rightBarButtonItem = nil
        }
    }
    
    
    //MARK: - Fetched results controller
    /*
    Returns the fetched results controller. Creates and configures the controller if necessary.
    */
    private func getFetchedResultsController() -> NSFetchedResultsController {
        
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // Create and configure a fetch request with the Book entity.
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Book", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Create the sort descriptors array.
        let authorDescriptor = NSSortDescriptor(key: "author", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        let sortDescriptors = [authorDescriptor, titleDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        // Create and initialize the fetch results controller.
        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: "author", cacheName: "Root")
        _fetchedResultsController!.delegate = self
        
        return _fetchedResultsController!
    }
    
    /*
    NSFetchedResultsController delegate methods to respond to additions, removals and so on.
    */
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        self.tableView!.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let tableView = self.tableView
        
        switch type {
            
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
            
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        self.tableView.endUpdates()
    }
    
    
    //MARK: - Segue management
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "AddBook" {
            
            /*
            The destination view controller for this segue is an AddViewController to manage addition of the book.
            This block creates a new managed object context as a child of the root view controller's context. It then creates a new book using the child context. This means that changes made to the book remain discrete from the application's managed object context until the book's context is saved.
            The root view controller sets itself as the delegate of the add controller so that it can be informed when the user has completed the add operation -- either saving or canceling (see addViewController:didFinishWithSave:).
            IMPORTANT: It's not necessary to use a second context for this. You could just use the existing context, which would simplify some of the code -- you wouldn't need to perform two saves, for example. This implementation, though, illustrates a pattern that may sometimes be useful (where you want to maintain a separate set of edits).
            */
            
            let navController = segue.destinationViewController as! UINavigationController
            let addViewController = navController.topViewController as! AddViewController
            addViewController.delegate = self
            
            // Create a new managed object context for the new book; set its parent to the fetched results controller's context.
            let addingContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            addingContext.parentContext = self.fetchedResultsController.managedObjectContext
            
            let newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: addingContext) as! Book
            addViewController.book = newBook
            addViewController.managedObjectContext = addingContext
            
        } else if segue.identifier == "ShowSelectedBook" {
            
            let indexPath = self.tableView.indexPathForSelectedRow
            let selectedBook = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! Book
            
            // Pass the selected book to the new view controller.
            let detailViewController = segue.destinationViewController as! DetailViewController
            detailViewController.book = selectedBook
        }
    }
    
    
    //MARK: - Add controller delegate
    
    /*
    Add controller's delegate method; informs the delegate that the add operation has completed, and indicates whether the user saved the new book.
    */
    func addViewController(controller: AddViewController, didFinishWithSave save: Bool) {
        
        if save {
            /*
            The new book is associated with the add controller's managed object context.
            This means that any edits that are made don't affect the application's main managed object context -- it's a way of keeping disjoint edits in a separate scratchpad. Saving changes to that context, though, only push changes to the fetched results controller's context. To save the changes to the persistent store, you have to save the fetch results controller's context as well.
            */
            let addingManagedObjectContext = controller.managedObjectContext
            do {
                try addingManagedObjectContext!.save()
            } catch let error as NSError {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                */
                NSLog("Unresolved error %@, %@", error, error.userInfo)
                abort()
            }
            
            do {
                try self.fetchedResultsController.managedObjectContext.save()
            } catch let error as NSError {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                */
                NSLog("Unresolved error %@, %@", error, error.userInfo)
                abort()
            }
        }
        
        // Dismiss the modal view to return to the main list
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}