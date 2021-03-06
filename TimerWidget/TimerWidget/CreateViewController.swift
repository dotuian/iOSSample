//
//  CreateViewController.swift
//  TimerWidget
//
//  Created by 鐘紀偉 on 15/3/25.
//  Copyright (c) 2015年 鐘紀偉. All rights reserved.
//

import Foundation
import UIKit

let dataManager = TWDataManager()

class CreateViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    // 默认为创建新的记录
    var flag = ControllerType.Create

    // 当前编辑的记录对象
    var record : Record = Record()

    var tableView : UITableView!

    var datePickerTitleIndexPath : NSIndexPath!

    // 数据收集的UI
    var titleTextField : UITextField!
    var dayUnitSwitch : UISwitch!
    var datepicker : UIDatePicker!
    var displaySwitch : UISwitch!

    var dateCell : UITableViewCell!
    var formatCell : UITableViewCell!
    var colorCell : UITableViewCell!


    // 当前显示的DatePickerCell的NSIndexPath
    var indexPathOfVisibleDatePicker : NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化页面控件
        self.initSubViews()
        // DatePickerCell
        datePickerTitleIndexPath = NSIndexPath(forRow: 1, inSection: 1)

        // 通过通知中心获取设定的值
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "handleColorChanged:", name: TWConstants.NS_UPDATE_COLOR, object: nil)
        center.addObserver(self, selector: "hanldeFormatChanged:", name: TWConstants.NS_UPDATE_FORMAT, object: nil)
    }

    func initSubViews(){
        self.view.backgroundColor = UIColor.whiteColor()

        // 导航栏按钮
        let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "hanlderCancelItem")
        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "hanlderDoneItem")
        self.navigationItem.rightBarButtonItem = doneItem
        self.navigationItem.leftBarButtonItem = cancelItem

        //
        tableView = UITableView(frame: self.view.bounds, style : UITableViewStyle.Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)

        // 隐藏工具栏
        self.navigationController?.toolbarHidden = true
    }

    // ============================
    // 通知中心
    // ============================
    func handleColorChanged(notication : NSNotification) {
        // 颜色选择
        if let cell = self.colorCell {
            let dict = notication.userInfo as [String : UIColor]
            for (key, value) in dict {
                cell.detailTextLabel?.text = key
                cell.detailTextLabel?.textColor = value
            }
        }
    }

    func hanldeFormatChanged(notication : NSNotification) {
        // 格式选择
        if let cell = self.formatCell {
            let dict = notication.userInfo as [String : Int]
            self.formatCell?.detailTextLabel!.text = TWConstants.DISPLAY_FORMAT[dict["format"]!]
        }
    }

    // ========================================================
    // 导航栏按钮事件
    // ========================================================
    // 新建/编辑取消
    func hanlderCancelItem(){
        // 返回到主页面
        if self.flag == .Create {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    // 新建/编辑保存
    func hanlderDoneItem(){
        // 隐藏键盘
        if titleTextField.isFirstResponder() {
            titleTextField.resignFirstResponder()
        }

        // 标题
        self.record.title = titleTextField.text
        // 只显示日期
        self.record.dayUnit = self.dayUnitSwitch.on
        // 日期
        let dateFormat = self.dayUnitSwitch.on ? DateUtils.DATE_FOMART.DATE_ONLY : DateUtils.DATE_FOMART.DATE_AND_TIME
        var strDate = self.dateCell.detailTextLabel?.text
        self.record.date = DateUtils.toDate(strDate!, dateFormat: dateFormat)!
        // 在通知中心显示
        self.record.display = self.displaySwitch.on
        // 表示格式
        let value = self.formatCell.detailTextLabel?.text!
        self.record.format = TWConstants.DISPLAY_FORMAT.getIndexByValue(value!)
        // 颜色
        self.record.color = (self.colorCell.detailTextLabel?.text)!

        println("create or update record is : \(self.record)")

        if self.flag == .Create {
            // 添加新纪录
            if !record.title.isEmpty {
                dataManager.insert(self.record)
            }

            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            // 保存修改的数据
            if !record.title.isEmpty {
                dataManager.updateForRecord(self.record)
            }

            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    // ========================================================
    // TableView
    // ========================================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    // 组中行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }

        var number = 5
        if self.datePickerTitleIndexPath.section == section && self.indexPathOfVisibleDatePicker != nil {
           number++
        }

        return number
    }

    // 行高
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        let datePickerCellIndexPath = self.datePickerTitleIndexPath.next

        // UIDatePicker所在TableViewCell的行高
        if self.indexPathOfVisibleDatePicker != nil && datePickerCellIndexPath.isEqual(indexPath){
            return 216
        }

        return self.tableView.rowHeight
    }

    // 绘制UITableViewCell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let isDatePickerCell = self.indexPathOfVisibleDatePicker?.isEqual(indexPath) {

            let identifer = "DatePickerCell"

            var cell = tableView.dequeueReusableCellWithIdentifier(identifer) as? TWDatePickerCell
            if cell == nil {
                cell = TWDatePickerCell(style: UITableViewCellStyle.Default, reuseIdentifier: identifer)

                self.datepicker = cell?.datepicker
                self.datepicker.date = self.record.date
                self.datepicker.datePickerMode = record.dayUnit ? UIDatePickerMode.Date : UIDatePickerMode.DateAndTime

                self.datepicker.addTarget(self, action: "datePickerValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            }

            return cell!

        } else {

            let identifer = "CreateTableViewCell"

            var cell = tableView.dequeueReusableCellWithIdentifier(identifer) as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: identifer)
            }

            // 标题
            if indexPath.section == 0 && indexPath.row == 0 {
                // 标题
                titleTextField = UITextField(frame: cell!.frame)
                titleTextField.placeholder = NSLocalizedString("V_CREATE_TITLE", comment: "title")

                let paddingView = UIView(frame: CGRectMake(0, 0, 10, 20))
                titleTextField.leftView = paddingView; // 左视图,提供padding的功能
                titleTextField.leftViewMode = UITextFieldViewMode.Always;
                titleTextField.textColor = UIColor.redColor() // 文本颜色
                titleTextField.textAlignment = NSTextAlignment.Left // 文本对齐方式
                titleTextField.autocapitalizationType = UITextAutocapitalizationType.None // 自动大写类型
                titleTextField.keyboardType = UIKeyboardType.ASCIICapable  // 键盘类型
                titleTextField.returnKeyType = UIReturnKeyType.Done
                titleTextField.enabled = true
                // 设置标题的值
                titleTextField.text = record.title
                // 编辑完成之后隐藏键盘
                titleTextField.addTarget(self, action: "hiddenKeyBoard:", forControlEvents: UIControlEvents.EditingDidEndOnExit)

                // 新建记录的情况下,自己弹出键盘
                if self.flag == .Create {
                    titleTextField.becomeFirstResponder()
                }

                cell?.contentView.addSubview(titleTextField)

            }

            // 事件详细设定
            if indexPath.section == 1 {
                switch(indexPath.row) {

                case 0: // 是否只显示日期
                    cell?.textLabel!.text = NSLocalizedString("V_CREATE_IS_DATE_ONLY", comment : "date only")
                    cell?.selectionStyle = UITableViewCellSelectionStyle.None

                    dayUnitSwitch = UISwitch()
                    dayUnitSwitch.on = self.record.dayUnit
                    dayUnitSwitch.addTarget(self, action: "dayUnitSwitchValuedChange:", forControlEvents: UIControlEvents.ValueChanged)

                    cell?.accessoryView = dayUnitSwitch

                case 1: // 日期
                    cell?.textLabel!.text = NSLocalizedString("V_CREATE_DATE", comment : "date")
                    // 日期格式
                    let dateFormat = self.record.dayUnit ? DateUtils.DATE_FOMART.DATE_ONLY : DateUtils.DATE_FOMART.DATE_AND_TIME
                    // 设置日期
                    cell?.detailTextLabel!.text = DateUtils.toString(self.record.date, dateFormat: dateFormat)

                    self.dateCell = cell!
                case 2: // 是否显示在通知中心
                    cell?.textLabel!.text = NSLocalizedString("V_CREATE_EXTENSION_SHOW", comment : "date")
                    cell?.selectionStyle = UITableViewCellSelectionStyle.None

                    displaySwitch = UISwitch()
                    displaySwitch.addTarget(self, action: "displaySwitchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                    displaySwitch.setOn(record.display, animated: true)

                    cell?.accessoryView = displaySwitch

                case 3: // 表示的格式
                    cell?.textLabel!.text = NSLocalizedString("V_CREATE_FORMAT", comment : "format")
                    cell?.detailTextLabel?.text = TWConstants.DISPLAY_FORMAT[record.format]
                    cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

                    self.formatCell = cell

                case 4: // 显示的颜色
                    cell?.textLabel!.text = NSLocalizedString("V_CREATE_COLOR", comment : "color")
                    cell?.detailTextLabel!.text = record.color
                    cell?.detailTextLabel!.textColor = UIColor.getColorWithName(record.color)
                    cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

                    self.colorCell = cell
                default:
                    println()
                }
            }

            return cell!
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 取消Cell的选择
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        // 显示/隐藏日期选择器
        if self.datePickerTitleIndexPath.isEqual(indexPath){
            self.toggleDatePickerForRowAtIndexPath(indexPath)
        }

        // 收起键盘
        if(indexPath.section == 1) {
            self.titleTextField.resignFirstResponder()
        }

        // 选择表示格式
        if(indexPath.section == 1 && indexPath.row == 3) {
            let formatViewController = FormatViewController()
            formatViewController.currentFormat = record.format
            self.navigationController?.pushViewController(formatViewController, animated: true)
        }

        // 选择表示颜色
        if(indexPath.section == 1 && indexPath.row == 4) {
            let colorViewController = ColorViewController()
            colorViewController.currentColor = record.color
            self.navigationController?.pushViewController(colorViewController, animated: true)
        }
    }

    func toggleDatePickerForRowAtIndexPath(indexPath : NSIndexPath){

        let tableView = self.tableView

        tableView.beginUpdates()

        let datePickerIndexPath = indexPath.next

        if self.indexPathOfVisibleDatePicker == nil {
            // 创建   
            self.indexPathOfVisibleDatePicker = datePickerIndexPath

            tableView.insertRowsAtIndexPaths([datePickerIndexPath], withRowAnimation: UITableViewRowAnimation.Middle)

            let cell = tableView.cellForRowAtIndexPath(indexPath)
            if cell != nil {
                cell!.detailTextLabel?.textColor = UIColor.blueColor()
            }

        } else if ((self.indexPathOfVisibleDatePicker?.isEqual(datePickerIndexPath)) != nil) {
            self.indexPathOfVisibleDatePicker = nil

            tableView.deleteRowsAtIndexPaths([datePickerIndexPath], withRowAnimation: UITableViewRowAnimation.Middle)
        }

        tableView.endUpdates()
    }

    //=======================================
    //
    //=======================================
    func datePickerValueChanged(datepicker : UIDatePicker){
        let indexPath = NSIndexPath(forRow: self.indexPathOfVisibleDatePicker!.row - 1, inSection: self.indexPathOfVisibleDatePicker!.section)

        println("datepicker = \(datepicker.date)")

        if let cell : UITableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) {
            record.date = datepicker.date
            cell.detailTextLabel!.text = self.record.strDate
        }
    }

    func displaySwitchValueChanged(displaySwitch : UISwitch) {
        self.record.display = displaySwitch.on
    }

    func dayUnitSwitchValuedChange(daySwitch : UISwitch) {
        self.record.dayUnit = daySwitch.on

        // 更新DatePicker的日期模式
        if self.datepicker != nil {
            self.datepicker.datePickerMode = daySwitch.on ? UIDatePickerMode.Date : UIDatePickerMode.DateAndTime
        }

        // 更新日期的内容
        let indexPath = NSIndexPath(forRow: 1, inSection: 1)
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            cell.detailTextLabel!.text = self.record.strDate
        }
    }

    func hiddenKeyBoard(textField : UITextField) {
        // 取消第一响应者,隐藏键盘
        textField.resignFirstResponder()
    }
}