//
//  EditingViewController.swift
//  CoreDataBooks
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/09/06.
//
//
/*
     File: EditingViewController.h
     File: EditingViewController.m
 Abstract: The table view controller responsible for editing a field of data -- either text or a date.
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

@objc(EditingViewController)
class EditingViewController : UIViewController {
    
    var editedObject: NSManagedObject!
    var editedFieldKey: String! {
        didSet {
            didSetEditedFieldKey(oldValue)
        }
    }
    var editedFieldName: String!
    
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var datePicker: UIDatePicker!
    
    private var editingDate: Bool {
        return isEditingDate()
    }
    
    
    //MARK: -
    
    private var _hasDeterminedWhetherEditingDate: Bool = false
    private var _editingDate: Bool = false
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        // Set the title to the user-visible name of the field.
        self.title = self.editedFieldName
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure the user interface according to state.
        if self.editingDate {
            
            self.textField.hidden = true
            self.datePicker.hidden = false
            var date = self.editedObject?.valueForKey(self.editedFieldKey!) as! NSDate?
            if date == nil {
                date = NSDate()
            }
            self.datePicker.date = date!
            
        } else {
            
            self.textField.hidden = false
            self.datePicker.hidden = true
            self.textField.text = self.editedObject?.valueForKey(self.editedFieldKey!) as! String?
            self.textField.placeholder = self.title
            self.textField.becomeFirstResponder()
        }
    }
    
    
    //MARK: - Save and cancel operations
    
    @IBAction func save(sender: AnyObject) {
        // Set the action name for the undo operation.
        let undoManager = self.editedObject?.managedObjectContext?.undoManager
        undoManager?.setActionName(self.editedFieldName!)
        
        // Pass current value to the edited object, then pop.
        if self.editingDate {
            self.editedObject?.setValue(self.datePicker.date, forKey: self.editedFieldKey!)
        } else {
            self.editedObject?.setValue(self.textField.text, forKey: self.editedFieldKey!)
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func cancel(sender: AnyObject) {
        // Don't pass current value to the edited object, just pop.
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    //MARK: - Manage whether editing a date
    
    private func didSetEditedFieldKey(oldValue: String?) {
        if oldValue != editedFieldKey {
            _hasDeterminedWhetherEditingDate = false
        }
    }
    
    
    private func isEditingDate() -> Bool {
        if _hasDeterminedWhetherEditingDate {
            return _editingDate
        }
        
        let entity = self.editedObject?.entity
        let attribute = entity?.attributesByName[self.editedFieldKey!] as! NSAttributeDescription?
        let attributeClassName = attribute?.attributeValueClassName
        
        if attributeClassName == "NSDate" {
            _editingDate = true
        } else {
            _editingDate = false
        }
        
        _hasDeterminedWhetherEditingDate = true
        return _editingDate
    }
    
    
}