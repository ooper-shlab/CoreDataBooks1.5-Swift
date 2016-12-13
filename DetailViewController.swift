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
        
        if type(of: self) === DetailViewController.self {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        }
        
        self.tableView.allowsSelectionDuringEditing = true
        
        // if the local changes behind our back, we need to be notified so we can update the date
        // format in the table view cells
        //
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.localeChanged(_:)), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Redisplay the data.
        self.updateInterface()
        self.updateRightBarButtonItemState()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
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
            do {
                try self.book!.managedObjectContext!.save()
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
    
    private func updateInterface() {
        
        self.authorLabel!.text = self.book!.author
        self.titleLabel!.text = self.book!.title
        let copyright: Date? = self.book!.copyright as Date
        self.copyrightLabel!.text = copyright != nil ? self.dateFormatter.string(from: copyright!) : nil
    }
    
    private func updateRightBarButtonItemState() {
        
        do {
            // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
            try self.book!.validateForUpdate()
            // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
            self.navigationItem.rightBarButtonItem!.isEnabled = true
        } catch _ {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        }
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        // Only allow selection if editing.
        if self.isEditing {
            return indexPath
        }
        return nil
    }
    
    /*
    Manage row selection: If a row is selected, create a new editing view controller to edit the property associated with the selected row.
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.isEditing {
            performSegue(withIdentifier: "EditSelectedItem", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
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
            
            let anUndoManager = UndoManager()
            anUndoManager.levelsOfUndo = 3
            self.book!.managedObjectContext?.undoManager = anUndoManager
        }
        
        // Register as an observer of the book's context's undo manager.
        let bookUndoManager = self.book!.managedObjectContext?.undoManager
        
        let dnc = NotificationCenter.default
        dnc.addObserver(self, selector: #selector(DetailViewController.undoManagerDidUndo(_:)), name: NSNotification.Name.NSUndoManagerDidUndoChange, object: bookUndoManager)
        dnc.addObserver(self, selector: #selector(DetailViewController.undoManagerDidRedo(_:)), name: NSNotification.Name.NSUndoManagerDidRedoChange, object: bookUndoManager)
    }
    
    func cleanUpUndoManager() {
        
        // Remove self as an observer.
        let bookUndoManager = self.book!.managedObjectContext?.undoManager
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSUndoManagerDidUndoChange, object: bookUndoManager)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSUndoManagerDidRedoChange, object: bookUndoManager)
        
        self.book!.managedObjectContext?.undoManager = nil
    }
    
    private var undoMnager: UndoManager? {
        
        return self.book?.managedObjectContext?.undoManager
    }
    
    func undoManagerDidUndo(_ notification: NSNotification) {
        
        // Redisplay the data.
        updateInterface()
        updateRightBarButtonItemState()
    }
    
    func undoManagerDidRedo(_ notification: NSNotification) {
        
        // Redisplay the data.
        updateInterface()
        updateRightBarButtonItemState()
    }
    
    /*
    The view controller must be first responder in order to be able to receive shake events for undo. It should resign first responder status when it disappears.
    */
    override var canBecomeFirstResponder: Bool {
        
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    
    //MARK: - Date Formatter
    
    var dateFormatter: DateFormatter {
        
        struct My {
            static let dateFormatter: DateFormatter = {
                var formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter
                }()
        }
        return My.dateFormatter
    }
    
    
    //MARK: - Segue management
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "EditSelectedItem" {
            
            let controller = segue.destination as! EditingViewController
            let indexPath = tableView.indexPathForSelectedRow!
            
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
    
    func localeChanged(_ notif: NSNotification) {
        // the user changed the locale (region format) in Settings, so we are notified here to
        // update the date format in the table view cells
        //
        updateInterface()
    }
    
}
