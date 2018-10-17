//
//  SystemsSettingsTableViewController.swift
//  Provenance
//
//  Created by Joseph Mattiello on 10/7/18.
//  Copyright © 2018 Provenance. All rights reserved.
//

import UIKit
import RealmSwift
import PVLibrary

import QuickTableViewController

private struct SystemOverviewViewModel {
	let title : String
	let identifier : String
	let gameCount : Int
	let cores : [Core]
	let preferredCore : Core?
	let bioses : [BIOS]?
}

extension SystemOverviewViewModel {
	init(withSystem system : System) {
		title = system.name
		identifier = system.identifier
		gameCount = system.gameStructs.count
		cores = system.coreStructs
		bioses = system.BIOSes
		preferredCore = system.userPreferredCore
	}
}

public class SystemSettingsCell : UITableViewCell {
    public static let identifier : String = String(describing: self)

	public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		sytle()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		sytle()
	}

	func sytle() {
		let bg = UIView(frame: bounds)
		bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		bg.backgroundColor = Theme.currentTheme.settingsCellBackground
		self.backgroundView = bg

		self.textLabel?.textColor = Theme.currentTheme.settingsCellText
		self.detailTextLabel?.textColor = Theme.currentTheme.defaultTintColor
	}
}

public class SystemSettingsHeaderCell : SystemSettingsCell {
	override func sytle() {
		super.sytle()
		self.backgroundView?.backgroundColor = Theme.currentTheme.settingsHeaderBackground
		self.textLabel?.textColor = Theme.currentTheme.settingsHeaderText
		self.detailTextLabel?.textColor = Theme.currentTheme.settingsHeaderText
		self.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
	}
}

class SystemsSettingsTableViewController: QuickTableViewController {

    var systemsToken: NotificationToken?

    func generateViewModels() {
        let realm  = try! Realm()
        let systems = realm.objects(PVSystem.self).sorted(byKeyPath: "name")
        let systemsModels = systems.map { SystemOverviewViewModel(withSystem: System(with: $0)) }

		tableContents = systemsModels.map { systemModel in
			var rows = [Row & RowStyle]()
			rows.append(
				NavigationRow<SystemSettingsCell>(title: "Games", subtitle: .rightAligned("\(systemModel.gameCount)"))
			)

			// CORES
//			if systemModel.cores.count < 2 {
			if !systemModel.cores.isEmpty {
				let coreNames = systemModel.cores.map {$0.project.name}.joined(separator: ",")
				rows.append(
					NavigationRow<SystemSettingsCell>(title: "Cores", subtitle: .rightAligned(coreNames))
				)
			}
//			} else {
//				let preferredCore = systemModel.preferredCore
//				rows.append(
//					RadioSection(title: "Cores", options:
//						systemModel.cores.map { core in
//							let selected = preferredCore != nil && core == preferredCore!
//							return OptionRow(title: core.project.name, isSelected: selected, action: didSelectCore(systemIdentifier: core.identifier))
//						}
//					)
//			}

			// BIOSES
			if let bioses = systemModel.bioses, !bioses.isEmpty {
				rows.append(NavigationRow<SystemSettingsHeaderCell>(title: "BIOSES", subtitle: .none))
				bioses.forEach { bios in
					let subtitle = "\(bios.expectedMD5) : \(bios.expectedSize) bytes"
					let biosRow = NavigationRow<SystemSettingsCell>(title: bios.descriptionText,
												subtitle: .belowTitle(subtitle),
												icon: nil,
												customization:
						{ (cell, row) in
							var backgroundColor : UIColor? = Theme.currentTheme.settingsCellBackground
							let status = bios.status
							if status.available {

							} else {
								backgroundColor = status.required ? UIColor(hex: "#700") : UIColor(hex: "#77404C")
							}
							cell.backgroundView = UIView()
							cell.backgroundView?.backgroundColor = backgroundColor
					},
												action: nil)
					rows.append(biosRow)
				}
			}
			return Section(title: systemModel.title,
						   rows: rows,
						   footer: nil)
		}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

		self.tableView.backgroundColor = Theme.currentTheme.settingsHeaderBackground
		self.tableView.separatorStyle = .singleLine

        let realm  = try! Realm()
        systemsToken = realm.objects(PVSystem.self).observe { (systems) in
            self.generateViewModels()
            self.tableView.reloadData()
        }
    }
    
    deinit {
        systemsToken?.invalidate()
    }

//	private func didSelectCore(identifier: String) -> (Row) -> Void {
//		return { [weak self] row in
//			// ...
//		}
//	}

}