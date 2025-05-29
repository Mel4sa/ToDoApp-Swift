import UIKit
import CoreData

class CategoryViewController: UITableViewController {

    var categories = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
    }

    // MARK: - TableView Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Storyboard'da cell identifier "CategoryCell" olmalı
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel?.text = category.name ?? "No Name"
        return cell
    }

    // MARK: - TableView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToItems" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationVC = segue.destination as! ToDoAppViewController
                destinationVC.selectedCategory = categories[indexPath.row]
            }
        }
    }

    // MARK: - Swipe Actions

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Silme aksiyonu
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            // CoreData'dan silme
            self.context.delete(self.categories[indexPath.row])
            // Array'den silme
            self.categories.remove(at: indexPath.row)
            // Değişiklikleri kaydetme
            self.saveCategories()
            
            completion(true)
        }
        
        // Düzenleme aksiyonu
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            var textField = UITextField()
            let alert = UIAlertController(title: "Edit Category", message: nil, preferredStyle: .alert)
            
            textField.text = self.categories[indexPath.row].name
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                guard let newName = textField.text, !newName.isEmpty else { return }
                
                self.categories[indexPath.row].name = newName
                self.saveCategories()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addTextField { alertTextField in
                alertTextField.placeholder = "Edit category name"
                textField = alertTextField
            }
            
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
            
            completion(true)
        }
        
        // Düzenleme butonunun rengini mavi yap
        editAction.backgroundColor = .systemBlue
        
        // Aksiyonları yapılandır
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }

    // MARK: - Add New Category

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: nil, preferredStyle: .alert)

        let action = UIAlertAction(title: "Add", style: .default) { _ in
            guard let text = textField.text, !text.isEmpty else { return }
            let newCategory = Category(context: self.context)
            newCategory.name = text
            self.categories.append(newCategory)
            self.saveCategories()
        }

        alert.addTextField { field in
            field.placeholder = "Enter category name"
            textField = field
        }

        alert.addAction(action)
        present(alert, animated: true)
    }

    // MARK: - Core Data Methods

    func saveCategories() {
        do {
            try context.save()
        } catch {
            print("Error saving categories: \(error)")
        }
        tableView.reloadData()
    }

    func loadCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error loading categories: \(error)")
        }
        tableView.reloadData()
    }
}
