//
//  ViewController.swift
//  MyTodoApp-Jolly-Assignment-1
//
//  Created by Jolly Bangue on 2023-07-21. Renamed by Jolly Bangue on 2023-09-02
// New name: TodoList

import UIKit
import FirebaseDatabase

class MainViewController: UIViewController {
    
    /// Creating reference to the realtime database
    private let databaseRef = Database.database().reference()
    
    /// Path of data to be saved in the database
    private let parentNode = "ToDoListOfJolly"
    
    private var myTodoItems: [(String, Any)] = []
    
    @IBOutlet weak var myTodoTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTodoTableView.dataSource = self
        myTodoTableView.delegate = self
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "My Todo List - Jolly"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        
        fetchItemsFromDatabase()
    }

    private func fetchItemsFromDatabase() {
        
        databaseRef.child(parentNode).observe(.value) { [weak self] snapshot in
            guard let items = snapshot.value as? [String: Any] else {
                return
            }
            /// Remove all items from myTodoItems to avoid duplicate items on MainViewController
            self?.myTodoItems.removeAll()
            
            let sortedItems = items.sorted {$0.0 < $1.0} // Sort items by order
            
            for (key, item) in sortedItems {
                self?.myTodoItems.append((key, item))
            }
            self?.myTodoTableView.reloadData()
        }
    }
        
    @objc func didTapAddButton() {
        let alert = UIAlertController(title: "Add item as todo list", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter to do item..."
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let inputText = textField.text,
                  !inputText.isEmpty else {
                return
            }
            /// Save entered item in the database
            self?.saveItemToDatabase(item: inputText)
        }))
        
        present(alert, animated: true)
    }
    
    private func saveItemToDatabase(item: String) {
        /// Save data in the database by automatically assigning an ID/Key
        databaseRef.child(parentNode).childByAutoId().setValue(item)
    }
}

extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myTodoItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myTodoCell", for: indexPath)
        guard let todoItem = myTodoItems[indexPath.row].1 as? String else {
            return cell
        }
        cell.textLabel?.text = todoItem
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteConfirmationAlert = UIAlertController(title: "Delete item", message: "Do you want to delete this item from your list?", preferredStyle: .alert)
        
        deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        deleteConfirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] _ in
            let keyToBeRemoved = myTodoItems[indexPath.row].0 /// Getting the key of the item/row to be deleted
            databaseRef.child(parentNode).child(keyToBeRemoved).removeValue() /// Removing the (key, value) from the database
            if myTodoItems.count <= 1 {
                myTodoItems.removeAll() /// Deleting the last element in myTodoItems, to enable the last item to be removed from the MainViewController
                myTodoTableView.reloadData()
            }
        }))
        
        let deleteItemAction = UIContextualAction(style: .destructive, title: "Delete") { [self] (action, view, completion) in
            present(deleteConfirmationAlert, animated: true)
            completion(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteItemAction])
        configuration.performsFirstActionWithFullSwipe = true /// A complete swipe action will be similar to clicking on the red "Delete" button
        
        return configuration
    }
}
