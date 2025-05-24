import UIKit
import CoreData

class ToDoAppViewController: UITableViewController {

    var items = [Item]()
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        // Hücre identifier'ını Storyboard'da "ToDoltemCell" olarak ayarladığından emin olun.
        // Eğer hücreyi kod ile kaydetmek isterseniz burada register() yapabilirsiniz.
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    // MARK: - TableView DataSource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoltemCell", for: indexPath)

        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none

        return cell
    }

    // MARK: - TableView Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].done.toggle()
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Add New Item

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()

        let alert = UIAlertController(title: "Add New ToDo Item", message: nil, preferredStyle: .alert)

        let action = UIAlertAction(title: "Add Item", style: .default) { _ in
            guard let newTitle = textField.text, !newTitle.isEmpty, let currentCategory = self.selectedCategory else { return }
            
            let newItem = Item(context: self.context)
            newItem.title = newTitle
            newItem.done = false
            newItem.parentCategory = currentCategory

            self.items.append(newItem)
            self.saveItems()
        }

        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }

        alert.addAction(action)
        present(alert, animated: true)
    }

    // MARK: - Data Manipulation Methods

    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
        tableView.reloadData()
    }

    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        guard let currentCategory = selectedCategory else { return }
        
        let categoryPredicate = NSPredicate(format: "parentCategory == %@", currentCategory)

        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }

        do {
            items = try context.fetch(request)
        } catch {
            print("Error fetching items: \(error)")
        }
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate

extension ToDoAppViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()

        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text ?? "")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        loadItems(with: request, predicate: predicate)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
