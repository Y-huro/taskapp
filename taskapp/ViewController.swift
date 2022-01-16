//
//  ViewController.swift
//  taskapp
//
//  Created by y i on 2022/01/07.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var uiSearchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // 検索フラグ
    var searchFlg = false
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    // 検索結果を管理するためのリスト
    var searchResults: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        uiSearchBar.delegate = self
        
    }
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        //print("データの数を返すメソッドを実行")
        if searchFlg {
            return searchResults.count
        } else {
            return taskArray.count
        }
        //return taskArray.count
    }
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("各セルの内容を返すメソッドを実行")
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if searchFlg {
            //print("セルの内容：検索")
            let task = searchResults[indexPath.row]
            cell.textLabel?.text = task.title
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString
        } else {
            //print("セルの内容：検索以外")
            // Cellに値を設定する
            let task = taskArray[indexPath.row]
            cell.textLabel?.text = task.title
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString
        }
        
        return cell
    }
    // 各セルを選択したときに実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle{
        return .delete
    }
    // Deleteボタンが押されたときに呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            searchFlg = false
            // 削除するタスクを取得
            let task = self.taskArray[indexPath.row]
            //print("削除するタスクを取得しました")
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            //print("ローカル通知をキャンセルしました")
            // データベースから削除する
            try! realm.write{
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
                //print("データベースから削除しました")
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/--------------")
                    print(request)
                    print("--------------/")
                }
            }
            //print("未通知のローカル通知一覧をログ出力しました")
            
        }
    }
    // 検索ボタン押下時の呼び出しメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        uiSearchBar.endEditing(true)
        searchFlg = true
        cellSearch()
        
        self.tableView.reloadData()
    }
    
    // 検索テキスト変更時の呼び出しメソッド
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
     
        searchFlg = true
        cellSearch()
        tableView.reloadData()
    }
    
    // 検索によるセル絞り込み処理
    func cellSearch() {
        
        searchResults.removeAll()
        searchResults.append(contentsOf: taskArray)
           
        if (uiSearchBar.text != ""){
            let newResult = searchResults.filter({$0.category.contains(uiSearchBar.text!)})
            searchResults = newResult
        }
    }
    
    // segueで画面遷移するときに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            if searchFlg {
                inputViewController.task = searchResults[indexPath!.row]
            } else {
                inputViewController.task = taskArray[indexPath!.row]
            }
            
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    // 入力画面から戻ってきたときにTableViewを更新させる
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        cellSearch()
        tableView.reloadData()
    }

}

