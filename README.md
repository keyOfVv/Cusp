# Cusp

[![CI Status](http://img.shields.io/travis/Ke Yang/Cusp.svg?style=flat)](https://travis-ci.org/Ke Yang/Cusp)
[![Version](https://img.shields.io/cocoapods/v/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)
[![License](https://img.shields.io/cocoapods/l/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)
[![Platform](https://img.shields.io/cocoapods/p/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)

## Usage

### Preparation

```swift
import Cusp

Cusp.central.prepare()
```

### Scan for BLE device
```swift
Cusp.central.scanForUUIDString(nil, completion: { (advertisementInfoArray) -> Void in
	for advertisementInfo in advertisementInfoArray {
		print(advertisementInfo.peripheral.name)
		print(advertisementInfo.advertisingUUIDStrings)
		print(advertisementInfo.RSSI)
	}, abruption: { (error) -> Void in

})
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Cusp is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Cusp"
```

## Author

Ke Yang, ofveravi@gmail.com

## License

Cusp is available under the MIT license. See the LICENSE file for more info.
