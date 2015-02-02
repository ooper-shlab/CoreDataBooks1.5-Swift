//
//  DetailViewController.swift
//  CoreDataBooks
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/09/07.
//
//
/*
     File: DetailViewController.h
 Abstract: The table view controller responsible for displaying detailed information about a single book.  It also allows the user to edit information about a book, and supports undo for editing operations.

 When editing begins, the controller creates and set an undo manager to track edits. It then registers as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded. When editing ends, the controller de-registers from the notification center and removes the undo manager.
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

@objc(DetailViewController)
class DetailViewController : UITableViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var copyrightLabel: UILabel!
    
    
    //MARK: -
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if self.dynamicType === DetailViewController.self {
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
        }
        
        self.tableView.allowsSelectionDuringEditing = true
        
        // if the local changes behind our back, we need to be notified so we can update the date
        // format in the table view cells
        //
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "localeChanged:", name: NSCurrentLocaleDidChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSCurrentLocaleDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Redisplay the data.
        self.updateInterface()
        self.updateRightBarButtonItemState()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        // Hide the back button when editing starts, and show it again when editing finishes.
        self.navigationItem.setHidesBackButton(editing, animated: animated)
        
        /*
        When editing starts, create and set an undo manager to track edits. Then register as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded.
        When editing ends, de-register from the notification center and remove the undo manager, and save the changes.
        */
        if editing {
            self.setUpUndoManager()
        } else {
            cleanUpUndoManager()
            // Save the changes.
            var error: NSError?
            if !self.book!.managedObjectContext!.save(&error) {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                */
                NSLog("Unresolved error %@, %@", error!, error!.userInfo!)
                abort()
            }
        }
    }
    
    private func updateInterface() {
        
        self.authorLabel!.text = self.book!.author
        self.titleLabel!.text = self.book!.title
        let copyright: NSDate? = self.book!.copyright
        self.copyrightLabel!.text = copyright != nil ? self.dateFormatter.stringFromDate(copyright!) : nil
    }
    
    private func updateRightBarButtonItemState() {
        
        // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
        self.navigationItem.rightBarButtonItem!.enabled = self.book!.validateForUpdate(nil)
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        // Only allow selection if editing.
        if self.editing {
            return indexPath
        }
        return nil
    }
    
    /*
    Manage row selection: If a row is selected, create a new editing view controller to edit the property associated with the selected row.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.editing {
            performSegueWithIdentifier("EditSelectedItem", sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return .None
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return false
    }
    
    
    //MARK: - Undo support
    // These methods are used by the AddViewController, so are declared here, but they are private to these classes.
    
    func setUpUndoManager() {
        
        /*
        If the book's managed object context doesn't already have an undo manager, then create one and set it for the context and self.
        The view controller needs to keep a reference to the undo manager it creates so that it can determine whether to remove the undo manager when editing finishes.
        */
        if self.book!.managedObjectContext?.undoManager == nil {
            
            let anUndoManager = NSUndoManager()
            anUndoManager.levelsOfUndo = 3
            self.book!.managedObjectContext?.undoManager = anUndoManager
        }
        
        // Register as an observer of the book's context's undo manager.
        var bookUndoManager = self.book!.managedObjectContext?.undoManager
        
        let dnc = NSNotificationCenter.defaultCenter()
        dnc.addObserver(self, selector: "undoManagerDidUndo:", name: NSUndoManagerDidUndoChangeNotification, object: bookUndoManager)
        dnc.addObserver(self, selector: "undoManagerDidRedo:", name: NSUndoManagerDidRedoChangeNotification, object: bookUndoManager)
    }
    
    func cleanUpUndoManager() {
        
        // Remove self as an observer.
        let bookUndoManager = self.book!.managedObjectContext?.undoManager
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUndoManagerDidUndoChangeNotification, object: bookUndoManager)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUndoManagerDidRedoChangeNotification, object: bookUndoManager)
        
        self.book!.managedObjectContext?.undoManager = nil
    }
    
    private var undoMnager: NSUndoManager? {
        
        return self.book?.managedObjectContext?.undoManager
    }
    
    func undoManagerDidUndo(notification: NSNotification) {
        
        // Redisplay the data.
        updateInterface()
        updateRightBarButtonItemState()
    }
    
    func undoManagerDidRedo(notification: NSNotification) {
        
        // Redisplay the data.
        updateInterface()
        updateRightBarButtonItemState()
    }
    
    /*
    The view controller must be first responder in order to be able to receive shake events for undo. It should resign first responder status when it disappears.
    */
    override func canBecomeFirstResponder() -> Bool {
        
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    
    //MARK: - Date Formatter
    
    var dateFormatter: NSDateFormatter {
        
        struct My {
            static let dateFormatter: NSDateFormatter = {
                var formatter = NSDateFormatter()
                formatter.dateStyle = .MediumStyle
                formatter.timeStyle = .NoStyle
                return formatter
                }()
        }
        return My.dateFormatter
    }
    
    
    //MARK: - Segue management
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "EditSelectedItem" {
            
            let controller = segue.destinationViewController as EditingViewController
            let indexPath = tableView.indexPathForSelectedRow()!
            
            controller.editedObject = self.book
            switch indexPath.row {
            case 0:
                controller.editedFieldKey = "title"
                controller.editedFieldName = NSLocalizedString("title", comment: "display name for title")
            case 1:
                controller.editedFieldKey = "author"
                controller.editedFieldName = NSLocalizedString("author", comment: "display name for author")
            case 2:
                controller.editedFieldKey = "copyright"
                controller.editedFieldName = NSLocalizedString("copyright", comment: "display name for copyright")
            default:
                break
            }
        }
    }
    
    
    //MARK: - Locale changes
    
    func localeChanged(notif: NSNotification) {
        // the user changed the locale (region format) in Settings, so we are notified here to
        // update the date format in the table view cells
        //
        updateInterface()
    }
    
}