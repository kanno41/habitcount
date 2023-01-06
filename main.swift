import UIKit
import CloudKit

class ViewController: UIViewController {
  
  var counter = Counter()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Fetch the counter record from iCloud
    let container = CKContainer.default()
    let database = container.sharedCloudDatabase
    let query = CKQuery(recordType: "Counter", predicate: NSPredicate(value: true))
    database.perform(query, inZoneWith: nil) { [weak self] results, error in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      
      if let results = results, let record = results.first {
        // A counter record was found, so load the counter object and stored date from the record
        let decoder = JSONDecoder()
        if let counterData = record["counter"] as? Data,
           let loadedCounter = try? decoder.decode(Counter.self, from: counterData) {
          self?.counter = loadedCounter
        }
        
        if let storedDate = record["date"] as? Date {
          // Compare the stored date to the current date
          let currentDate = Date()
          if storedDate.day != currentDate.day || storedDate.month != currentDate.month || storedDate.year != currentDate.year {
            // A new day has started, so increment the count of the counter object
            self?.counter.incrementCount()
            
            // Update the stored date to the current date
            record["date"] = currentDate
            
            // Save the updated record to iCloud
            database.save(record) { _, error in
              if let error = error {
                print(error.localizedDescription)
                return
              }
            }
          }
        } else {
          // This is the first launch of the app, so increment the count of the counter object and set the stored date to the current date
          self?.counter.incrementCount()
          let currentDate = Date()
          record["date"] = currentDate
          
          // Save the updated record to iCloud
          database.save(record) { _, error in
            if let error = error {
              print(error.localizedDescription)
              return
            }
          }
        }
      } else {
        // No counter record was found, so create a new counter record with a count of 1 and the current date
        let encoder = JSONEncoder()
        let counterData = try? encoder.encode(self?.counter)
        let record = CKRecord(recordType: "Counter")
        record["counter"] = counterData
        record["date"] = Date()
        
        // Save the new record to iCloud
        database.save(record) { _, error in
          if let error = error {
            print(error.localizedDescription)
            return
          }
        }
      }
    }
  }
}
