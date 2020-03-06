//
//  DebugViewController.swift
//  StreamDemo
//
//  Created by Inpyo Hong on 2020/03/05.
//  Copyright © 2020 Inpyo Hong. All rights reserved.
//

import UIKit

class DebugViewController: UIViewController {
  @IBOutlet weak var logMsgView: UITextView!
  var storageController: StorageController = StorageController()
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    guard let log = storageController.fetchLog() else { return }
    logMsgView.text = log.msg

  }
  @IBAction func tapDeleteBtn(_ sender: Any) {
    let alert =  UIAlertController(title: nil, message: "Are you sure want to delete message?", preferredStyle: .alert)

    let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
      self.storageController.deleteAll()
      self.dismiss(animated: true, completion: nil)
    })
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

    alert.addAction(ok)
    alert.addAction(cancel)

    self.present(alert, animated: true, completion: nil)
  }
}
