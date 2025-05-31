import UIKit
import CoreData
import UserNotifications

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
        
        // Bildirim izni iste
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Bildirim izni verildi")
            } else {
                print("Bildirim izni reddedildi")
            }
        }
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    // MARK: - TableView DataSource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoltemCell", for: indexPath)
        let item = items[indexPath.row]
        
        // Ana metin ve saat bilgisini birleştir
        var text = item.title ?? ""
        if let startTime = item.startTime {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            text += " - \(dateFormatter.string(from: startTime))"
        }
        
        // Metin özelliklerini ayarla
        let attributedString = NSAttributedString(
            string: text,
            attributes: item.done ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue] : [:]
        )
        cell.textLabel?.attributedText = attributedString
        
        return cell
    }

    // MARK: - TableView Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // İşin tamamlanma durumunu değiştir
        items[indexPath.row].done = !items[indexPath.row].done
        
        // Eğer görev tamamlandıysa bildirimi sil
        if items[indexPath.row].done {
            removeNotification(for: items[indexPath.row])
        } else {
            // Görev tekrar aktif edildiyse ve zamanı gelmediyse bildirimi yeniden oluştur
            scheduleNotification(for: items[indexPath.row])
        }
        
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Swipe Actions
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Silme aksiyonu
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            // Bildirimi sil
            self.removeNotification(for: self.items[indexPath.row])
            
            self.context.delete(self.items[indexPath.row])
            self.items.remove(at: indexPath.row)
            self.saveItems()
            
            completion(true)
        }
        
        // Düzenleme aksiyonu
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            var textField = UITextField()
            let datePicker = UIDatePicker()
            let alert = UIAlertController(title: "Edit Item", message: "\n\n\n\n\n\n", preferredStyle: .alert)
            
            // Date Picker'ı yapılandır
            datePicker.datePickerMode = .time
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.frame = CGRect(x: 0, y: 50, width: 270, height: 100)
            if let startTime = self.items[indexPath.row].startTime {
                datePicker.date = startTime
            }
            alert.view.addSubview(datePicker)
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self = self,
                      let newTitle = textField.text, !newTitle.isEmpty else { return }
                
                // Eski bildirimi sil
                self.removeNotification(for: self.items[indexPath.row])
                
                self.items[indexPath.row].title = newTitle
                self.items[indexPath.row].startTime = datePicker.date
                self.saveItems()
                
                // Yeni bildirim oluştur
                self.scheduleNotification(for: self.items[indexPath.row])
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addTextField { alertTextField in
                alertTextField.text = self.items[indexPath.row].title
                textField = alertTextField
            }
            
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true)
            completion(true)
        }
        
        editAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }

    // MARK: - Add New Item

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let datePicker = UIDatePicker()
        
        let alert = UIAlertController(title: "Add New ToDo Item", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        // Date Picker'ı yapılandır
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.frame = CGRect(x: 0, y: 50, width: 270, height: 100)
        alert.view.addSubview(datePicker)

        let action = UIAlertAction(title: "Add Item", style: .default) { [weak self] _ in
            guard let self = self,
                  let newTitle = textField.text, !newTitle.isEmpty,
                  let currentCategory = self.selectedCategory else { return }
            
            let newItem = Item(context: self.context)
            newItem.title = newTitle
            newItem.startTime = datePicker.date
            newItem.parentCategory = currentCategory
            newItem.done = false

            self.items.append(newItem)
            self.saveItems()
            
            // Yeni görev için bildirim oluştur
            self.scheduleNotification(for: newItem)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }

        alert.addAction(action)
        alert.addAction(cancelAction)
        
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

    // Bildirim oluşturma fonksiyonu
    func scheduleNotification(for item: Item) {
        // Eğer startTime nil ise bildirim oluşturma
        guard let startTime = item.startTime,
              let title = item.title else { return }
        
        // Eğer seçilen zaman geçmişte kaldıysa bildirim oluşturma
        if startTime < Date() {
            return
        }
        
        // Bildirim içeriğini oluştur
        let content = UNMutableNotificationContent()
        content.title = "Görev Başlama Zamanı"
        content.body = "\(title) için başlama zamanı geldi!"
        content.sound = .default
        
        // Bildirim zamanını ayarla
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Benzersiz bir identifier oluştur
        let identifier = "TaskNotification_\(item.objectID.uriRepresentation().lastPathComponent)"
        
        // Varolan bildirimi sil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Yeni bildirimi oluştur
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi planla
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim oluşturma hatası: \(error)")
            }
        }
    }
    
    // Bildirimi silme fonksiyonu
    func removeNotification(for item: Item) {
        let identifier = "TaskNotification_\(item.objectID.uriRepresentation().lastPathComponent)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
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
