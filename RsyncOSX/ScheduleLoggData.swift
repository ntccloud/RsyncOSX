//
//  ScheduleLoggData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  Object for sorting and holding logg data about all tasks.
//  Detailed logging must be set on if logging data.
//
// swiftlint:disable trailing_comma line_length

import Foundation

enum Sortandfilter {
    case offsitecatalog
    case localcatalog
    case profile
    case offsiteserver
    case task
    case backupid
    case numberofdays
    case executedate
    case none
}

struct Logrecordstest {
    var hiddenID: Int
    var localCatalog: String
    var remoteCatalog: String
    var offsiteServer: String
    var task: String
    var backupID: String
    var dateExecuted: String
    var resultExecuted: String
    var snapCellID: Int
    var parent: Int
    var sibling: Int
    var delete: Int
}

final class ScheduleLoggData: SetConfigurations, SetSchedules, Sorting {
    var loggdata: [NSMutableDictionary]?
    var loggdata2: [Logrecordstest]?

    func filter(search: String?, filterby: Sortandfilter?) {
        globalDefaultQueue.async { () -> Void in
            let valueforkey = self.filterbystring(filterby: filterby ?? Optional.none)
            self.loggdata = self.loggdata?.filter {
                ($0.value(forKey: valueforkey) as? String ?? "").contains(search ?? "")
            }
        }
    }

    private func readandsortallloggdata(hiddenID: Int?, sortascending: Bool) {
        var data = [NSMutableDictionary]()
        if let input: [ConfigurationSchedule] = self.schedules?.getSchedule() {
            for i in 0 ..< input.count {
                for j in 0 ..< (input[i].logrecords?.count ?? 0) {
                    if let hiddenID = self.schedules?.getSchedule()?[i].hiddenID {
                        var date: String?
                        if let stringdate = input[i].logrecords?[j].dateExecuted {
                            if stringdate.isEmpty == false {
                                date = stringdate.en_us_date_from_string().localized_string_from_date()
                            }
                        }
                        let logdetail: NSMutableDictionary = [
                            DictionaryStrings.localCatalog.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .localCatalog) ?? "",
                            DictionaryStrings.remoteCatalog.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .remoteCatalog) ?? "",
                            DictionaryStrings.offsiteServer.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .offsiteServer) ?? "",
                            DictionaryStrings.task.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .task) ?? "",
                            DictionaryStrings.backupID.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .backupid) ?? "",
                            DictionaryStrings.dateExecuted.rawValue: date ?? "",
                            DictionaryStrings.resultExecuted.rawValue: input[i].logrecords?[j].resultExecuted ?? "",
                            DictionaryStrings.deleteCellID.rawValue: self.loggdata?[j].value(forKey: DictionaryStrings.deleteCellID.rawValue) as? Int ?? 0,
                            DictionaryStrings.hiddenID.rawValue: hiddenID,
                            DictionaryStrings.snapCellID.rawValue: 0,
                            DictionaryStrings.parent.rawValue: i,
                            DictionaryStrings.sibling.rawValue: j,
                        ]
                        data.append(logdetail)
                    }
                }
            }
        }
        if hiddenID != nil {
            data = data.filter { ($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID }
        }
        self.loggdata = self.sortbydate(notsortedlist: data, sortdirection: sortascending)
    }

    let compare: (NSMutableDictionary?, NSMutableDictionary?) -> Bool = { number1, number2 in
        if number1?.value(forKey: DictionaryStrings.sibling.rawValue) as? Int == number2?.value(forKey: DictionaryStrings.sibling.rawValue) as? Int,
           number1?.value(forKey: DictionaryStrings.parent.rawValue) as? Int == number2?.value(forKey: DictionaryStrings.parent.rawValue) as? Int
        {
            return true
        } else {
            return false
        }
    }

    let compare2: (NSMutableDictionary?, NSMutableDictionary?) -> Bool = { number1, number2 in
        if number1?.value(forKey: DictionaryStrings.sibling.rawValue) as? Int == number2?.value(forKey: DictionaryStrings.sibling.rawValue) as? Int,
           number1?.value(forKey: DictionaryStrings.parent.rawValue) as? Int == number2?.value(forKey: DictionaryStrings.parent.rawValue) as? Int
        {
            return true
        } else {
            return false
        }
    }

    func align(snapshotlogsandcatalogs: Snapshotlogsandcatalogs?) {
        guard snapshotlogsandcatalogs?.snapshotslogs != nil else { return }
        guard self.loggdata != nil else { return }
        for i in 0 ..< (self.loggdata?.count ?? 0) {
            for j in 0 ..< (snapshotlogsandcatalogs?.snapshotslogs?.count ?? 0) where
                self.compare(snapshotlogsandcatalogs?.snapshotslogs?[j], self.loggdata?[i])
            {
                self.loggdata?[i].setValue(1, forKey: DictionaryStrings.snapCellID.rawValue)
            }
            if self.loggdata?[i].value(forKey: DictionaryStrings.snapCellID.rawValue) as? Int == 1 {
                self.loggdata?[i].setValue(0, forKey: DictionaryStrings.deleteCellID.rawValue)
            } else {
                self.loggdata?[i].setValue(1, forKey: DictionaryStrings.deleteCellID.rawValue)
            }
        }
    }

    init(sortascending: Bool) {
        if self.loggdata2 == nil {
            self.readandsortallloggdata2(hiddenID: nil, sortascending: sortascending)
        }
    }

    init(hiddenID: Int, sortascending: Bool) {
        if self.loggdata2 == nil {
            self.readandsortallloggdata2(hiddenID: hiddenID, sortascending: sortascending)
        }
    }
}


extension ScheduleLoggData {
    private func readandsortallloggdata2(hiddenID: Int?, sortascending _: Bool) {
        var data = [Logrecordstest]()
        if let input: [ConfigurationSchedule] = self.schedules?.getSchedule() {
            for i in 0 ..< input.count {
                for j in 0 ..< (input[i].logrecords?.count ?? 0) {
                    if let hiddenID = self.schedules?.getSchedule()?[i].hiddenID {
                        var date: String?
                        if let stringdate = input[i].logrecords?[j].dateExecuted {
                            if stringdate.isEmpty == false {
                                date = stringdate.en_us_date_from_string().localized_string_from_date()
                            }
                        }
                        let record =
                            Logrecordstest(hiddenID: hiddenID,
                                           localCatalog: self.configurations?.getResourceConfiguration(hiddenID, resource: .localCatalog) ?? "",
                                           remoteCatalog: self.configurations?.getResourceConfiguration(hiddenID, resource: .remoteCatalog) ?? "",
                                           offsiteServer: self.configurations?.getResourceConfiguration(hiddenID, resource: .offsiteServer) ?? "",
                                           task: self.configurations?.getResourceConfiguration(hiddenID, resource: .task) ?? "",
                                           backupID: self.configurations?.getResourceConfiguration(hiddenID, resource: .backupid) ?? "",
                                           dateExecuted: date ?? "",
                                           resultExecuted: input[i].logrecords?[j].resultExecuted ?? "",
                                           snapCellID: 0,
                                           parent: i,
                                           sibling: j,
                                           delete: 0)
                        data.append(record)
                    }
                }
            }
        }
        if hiddenID != nil {
            data = data.filter { $0.hiddenID == hiddenID }
        }
        self.loggdata2 = data
    }
}
