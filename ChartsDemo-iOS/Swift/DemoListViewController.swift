//
//  DemoListViewController.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import UIKit

private struct ItemDef {
    let title: String
    let subtitle: String
    let `class`: AnyClass
}

class DemoListViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    private var itemDefs = [
                    ItemDef(title: "Pie Chart",
                            subtitle: "A simple demonstration of the pie chart.",
                            class: PieChartViewController.self),
                    ItemDef(title: "Pie Chart with value lines",
                            subtitle: "A simple demonstration of the pie chart with polyline notes.",
                            class: PiePolylineChartViewController.self),
                    ItemDef(title: "Half Pie Chart",
                            subtitle: "This demonstrates how to create a 180 degree PieChart.",
                            class: HalfPieChartViewController.self)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Charts Demonstration"
        self.tableView.rowHeight = 70
        //FIXME: Add TimeLineChart
        
    }
}

extension DemoListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemDefs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let def = self.itemDefs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = def.title
        cell.detailTextLabel?.text = def.subtitle
        cell.detailTextLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let def = self.itemDefs[indexPath.row]
        
        let vcClass = def.class as! UIViewController.Type
        let vc = vcClass.init()
        
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
