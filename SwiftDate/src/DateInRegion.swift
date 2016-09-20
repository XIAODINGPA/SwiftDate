//
//  SwiftDate.swift
//  SwiftDate
//
//  Created by Daniele Margutti on 09/09/16.
//  Copyright © 2016 Daniele Margutti. All rights reserved.
//

import Foundation


/*	`DateInRegion` represent a Date in a specified world region: along with absolute date it essentially encapsulate
	all informations about the time zone (`TimeZone`), calendar (`Calendar`) and locale (`Locale`).
	These info are contained inside the `.region` property.

	Using `DateInRegion` you can:
		* Represent an absolute Date in a specific timezone/calendar/locale
		* Easy access to all date components (day,month,hour,minute etc.) of the date in specified region
		* Easily create a new date from string, date components or swift operators
		* Compare date using Swift operators like `==, !=, <, >, <=, >=` and several
			additional methods like `isInWeekend,isYesterday`...
		* Change date by adding or subtracting elements with Swift operators
			(e.g. `date + 2.days + 15.minutes`)
*/

public class DateInRegion: CustomStringConvertible {
	private(set) var region: Region
	private(set) var absoluteDate: Date
	
	
	/// Initialize a new `DateInRegion` object from an absolute date and a destination region.
	/// The new instance express given date into specified region.
	///
	/// - parameter absoluteDate: absolute `Date` object
	/// - parameter region:       `Region` in which you would express given date (absolute time will be converted into passed region)
	///
	/// - returns: a new instance of the `DateInRegion` object
	public init(absoluteDate: Date, in region: Region? = nil) {
		let srcRegion = region ?? Region.Local()
		self.absoluteDate = absoluteDate
		self.region = srcRegion
	}
	
	
	/// Initialize a new DateInRegion set to the current date in local's device region (`Region.Local()`).
	///
	/// - returns: a new DateInRegion object
	public init() {
		self.absoluteDate = Date()
		self.region = Region.Local()
	}
	
	
	/// Initialize a new `DateInRegion` object from a `DateComponents` object.
	/// Both `TimeZone`, `Locale` and `Calendar` must be specified in `DateComponents` instance in order to get a valid result; if omitted a `MissingCalTzOrLoc` exception will thrown.
	/// If from given components a valid Date cannot be created a `FailedToParse`
	/// exception will thrown.
	///
	/// - parameter components: `DateComponents` with valid components used to generate a new date
	///
	/// - throws: throw an exception when `DateComponents` does not include required components used to generate a valid date (it must also include information about timezone, calendar and locale)
	///
	/// - returns: a new `DateInRegion` from given components
	public init(components: DateComponents) throws {
		guard let srcRegion = Region(components: components) else {
			throw DateError.MissingCalTzOrLoc
		}
		guard let absDate = srcRegion.calendar.date(from: components) else {
			throw DateError.FailedToParse
		}
		self.absoluteDate = absDate
		self.region = srcRegion
	}
	
	
	
	/// Initialize a new `DateInRegion` where components are specified in an dictionary
	/// where the key is `Calendar.Component` and the value is an int; region informations
	/// (timezone, locale and calendars) are specified separately by the region parameter.
	///
	/// - parameter components: calendar components keys and values to assign
	/// - parameter region:     region in which the date is expressed. If `nil` local region will used instead (`Region.Local()`)
	///
	/// - throws: throw a `FailedToParse` exception if date cannot be generated with given set of values
	///
	/// - returns: a new `DateInRegion` instance expressed in passed region
	public init(components: [Calendar.Component : Int], fromRegion region: Region? = nil) throws {
		let srcRegion = region ?? Region.Local()
		let cmp = DateInRegion.componentsFrom(values: components, setRegion: srcRegion)
		guard let absDate = srcRegion.calendar.date(from: cmp) else {
			throw DateError.FailedToParse
		}
		self.absoluteDate = absDate
		self.region = srcRegion
	}
	
	
	/// Initialize a new `DateInRegion` created from passed format rexpressed in specified region.
	///
	/// - parameter string: string with date to parse
	/// - parameter format: format in which the date is expressed (see `DateFormat`)
	/// - parameter region: region in which the date should be expressed (if nil `Region.Local()` will be used instead)
	///
	/// - throws: throw an `FailedToParse` exception if date cannot be parsed
	///
	/// - returns: a new DateInRegion from given string
	public init(string: String, format: DateFormat, fromRegion region: Region? = nil) throws {
		let srcRegion = region ?? Region.Local()
		switch format {
		case .custom(let format):
			guard let date = srcRegion.formatter(format: format).date(from: string) else {
				throw DateError.FailedToParse
			}
			self.absoluteDate = date
		case .iso8601(let options):
			guard let date = srcRegion.iso8601Formatter(options: options).date(from: string) else {
				throw DateError.FailedToParse
			}
			self.absoluteDate = date
		case .extended:
			let format = "eee dd-MMM-yyyy GG HH:mm:ss.SSS zzz"
			guard let date = srcRegion.formatter(format: format).date(from: string) else {
				throw DateError.FailedToParse
			}
			self.absoluteDate = date
		case .rss(let isAltRSS):
			let format = (isAltRSS ? "d MMM yyyy HH:mm:ss ZZZ" : "EEE, d MMM yyyy HH:mm:ss ZZZ")
			guard let date = srcRegion.formatter(format: format).date(from: string) else {
				throw DateError.FailedToParse
			}
			self.absoluteDate = date
		case .dotNET:
			guard let secsSince1970 = string.dotNETParseSeconds() else {
				throw DateError.FailedToParse
			}
			self.absoluteDate = Date(timeIntervalSince1970: secsSince1970)
		}
		self.region = srcRegion
	}
	
	
	/// Convert a `DateInRegion` instance to a new specified `Region`
	///
	/// - parameter newRegion: destination region in which returned `DateInRegion` instance will be expressed in
	///
	/// - returns: a new `DateInRegion` expressed in passed destination region
	public func toRegion(_ newRegion: Region) -> DateInRegion {
		return DateInRegion(absoluteDate: self.absoluteDate, in: newRegion)
	}
	
	
	/// Modify absolute date value of the `DateInRegion` instance by adding a fixed value of seconds
	///
	/// - parameter interval: seconds to add
	public func add(interval: TimeInterval) {
		self.absoluteDate.addTimeInterval(interval)
	}
	
	
	/// Return a description of the `DateInRegion`
	public var description: String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .long
		formatter.locale = self.region.locale
		formatter.calendar = self.region.calendar
		formatter.timeZone = self.region.timeZone
		return formatter.string(from: self.absoluteDate)
	}
	
}
