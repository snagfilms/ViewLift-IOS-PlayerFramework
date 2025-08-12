//
//  PlayerSettingView_tvOS.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

protocol PlayerSettingViewDelegate_tvOS: AnyObject{
    func dismissSettingView()
    func closedCaptionsSelected(name: String, index: Int)
    func audioLanguageSelected(name: String)
    func fontStylesSelected(name: String)
    func audioQualitySelected(name: String)
}

class PlayerSettingView_tvOS: UIView{
   
    enum PlayerOptionView{
        case menu
        case subMenu
    }
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var playerMenuModel: PlayerMenuModel
    var currentPlayerOptionView: PlayerOptionView = .menu
    var currentMenuType: MenuType = .setting
    var currentMenuSelectedIndex: Int?
    var currentSubMenuSelectedIndex: Int?
    weak var delegate: PlayerSettingViewDelegate_tvOS?
    var menuPressRecognizer: UITapGestureRecognizer?
     init(frame: CGRect, playerMenuModel: PlayerMenuModel){
        self.playerMenuModel = playerMenuModel
        super.init(frame: frame)
        loadView()
        setupAppearance()
        setupTableView()
         addMenuPressGesture()
    }
    func addMenuPressGesture(){
        menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMenuPress(gesture:)))
        menuPressRecognizer?.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        menuPressRecognizer?.cancelsTouchesInView = false
        addGestureRecognizer(menuPressRecognizer!)
    }

    @objc func handleMenuPress(gesture: UITapGestureRecognizer) {
        switch currentPlayerOptionView {
        case .menu:
            removeMenuPressGesture()
            delegate?.dismissSettingView()
        case .subMenu:
            currentPlayerOptionView = .menu
            tableView.reloadData()
        }
    }
    func removeMenuPressGesture(){
        guard let gesture = menuPressRecognizer else {return}
        removeGestureRecognizer(gesture)
        menuPressRecognizer = nil
    }
    func didSelectTableView(indexPath: IndexPath){
        switch currentPlayerOptionView {
        case .subMenu:
            guard let currentMenuSelectedIndex else{return}
            let selectedOption = playerMenuModel.menuModel[currentMenuSelectedIndex].options[indexPath.row]
            playerMenuModel.menuModel[currentMenuSelectedIndex].selectedOption = selectedOption.name
            currentSubMenuSelectedIndex = indexPath.row
            tableView.reloadData()
            let data = playerMenuModel.menuModel[currentMenuSelectedIndex]
            saveToUserdefaults(data: data, index: indexPath.row)
        case .menu:
            currentMenuSelectedIndex = indexPath.row
            currentSubMenuSelectedIndex = nil
            currentPlayerOptionView = .subMenu
            tableView.reloadData()
        }
    }
    func saveToUserdefaults(data: MenuModel, index: Int){
        let key = data.name.rawValue
        let value = data.selectedOption
        switch data.name {
        case .closedCaptions:
            UserDefaults.standard.set(value, forKey: "closedcaption")
            if index == 0{
                UserDefaults.standard.set(false, forKey: "isCCEnabled")
            }else{
                UserDefaults.standard.set(true, forKey: "isCCEnabled")
            }
        case .audioLanguage:
            UserDefaults.standard.set(value, forKey: key)

        case .fontStyles:
            if let size = FontStyleValues.from(size: value)?.rawValue{
                UserDefaults.standard.set(size, forKey: key)
            }

        case .videoQuality:
            UserDefaults.standard.set(value, forKey: key)
        }
        
        UserDefaults.standard.synchronize()
        
        switch data.name {
        case .closedCaptions:
            delegate?.closedCaptionsSelected(name: value, index: index)
        case .audioLanguage:
            delegate?.audioLanguageSelected(name: value)
        case .fontStyles:
            delegate?.fontStylesSelected(name: value)
        case .videoQuality:
            delegate?.audioQualitySelected(name: value)
        }
    }
    func setupTableView(){
        tableView.register(UINib(nibName: "OptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "OptionsTableViewCell")
        tableView.register(UINib(nibName: "OptionsTableHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "OptionsTableHeaderFooterView")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
        tableView.delegate = self
        tableView.dataSource = self
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
    private func loadView() {
        
        Bundle.main.loadNibNamed("PlayerSettingView_tvOS", owner: self, options: nil)
        addSubview(self.contentView)
    }
   
    private func setupAppearance(){
        backgroundColor = UIColor.black.withAlphaComponent(0.5)


    }
}

extension PlayerSettingView_tvOS: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       didSelectTableView(indexPath: indexPath)
    }
}

extension PlayerSettingView_tvOS: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentPlayerOptionView {
        case .menu:
            return playerMenuModel.menuModel.count
        case .subMenu:
            guard let currentMenuSelectedIndex else{return 0}
            return playerMenuModel.menuModel[currentMenuSelectedIndex].options.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionsTableViewCell", for: indexPath) as! OptionsTableViewCell
        switch currentPlayerOptionView{
        case .subMenu:
            let model = playerMenuModel.menuModel[currentMenuSelectedIndex ?? 0]
            let option = model.options[indexPath.row]
            cell.optionLabel.text = option.name
            if model.selectedOption == option.name{
                cell.imageViewArrow.image = UIImage(named: "tick_white")
                cell.imageViewArrow.isHidden = false
            }else{
                cell.imageViewArrow.image = nil
                cell.imageViewArrow.isHidden = true
            }
        case .menu:
            let menu = playerMenuModel.menuModel[indexPath.row]
            if menu.name == .closedCaptions {
                cell.optionLabel.text = "Closed Captions"
            }
            else if menu.name == .audioLanguage {
                cell.optionLabel.text = menu.name.rawValue
            }
            else if menu.name == .fontStyles {
                cell.optionLabel.text = "Manage Font"
            }
            else if menu.name == .videoQuality {
                cell.optionLabel.text = "Playback Quality"
            }
            cell.imageViewArrow.isHidden = false
            cell.imageViewArrow.image = UIImage(named: "rightArrow")
        }
        cell.optionLabel.textColor = .white
        cell.contentView.round(corners: .allCorners, radius: 10)
        cell.contentView.backgroundColor = UIColor.fromHex("525760")
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OptionsTableHeaderFooterView") as! OptionsTableHeaderFooterView
        //view.setupView(model: model[currentMenuSelectedIndex ?? 0], type: currentPlayerOptionView)
        switch currentPlayerOptionView{
        case .menu:
            if playerMenuModel.type == .subtitle{
                view.headerLabel.text = "Close Captions"
            }
            else {
                view.headerLabel.text = "Settings"
            }
        case .subMenu:
            let name = playerMenuModel.menuModel[currentMenuSelectedIndex ?? 0].name
            if name == .closedCaptions {
                view.headerLabel.text = "Close Captions"
            }
            else if name == .audioLanguage {
                view.headerLabel.text = name.rawValue
            }
            else if name == .fontStyles {
                view.headerLabel.text = "Manage Fonts"
            }
            else if name == .videoQuality {
                view.headerLabel.text = "Playback Quality"
            }
//            view.headerLabel.text = name.rawValue
        }
        view.headerLabel.textColor = .gray
        
        return view
    }
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        switch currentPlayerOptionView{
        case .menu:
            return IndexPath(row: currentMenuSelectedIndex ?? 0, section: 0)
        case .subMenu:
            return IndexPath(row: currentSubMenuSelectedIndex ?? 0, section: 0)
        }
    }
}

