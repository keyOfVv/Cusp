# Cusp

[![CI Status](http://img.shields.io/travis/Ke Yang/Cusp.svg?style=flat)](https://travis-ci.org/Ke Yang/Cusp)
[![Version](https://img.shields.io/cocoapods/v/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)
[![License](https://img.shields.io/cocoapods/l/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)
[![Platform](https://img.shields.io/cocoapods/p/Cusp.svg?style=flat)](http://cocoapods.org/pods/Cusp)

## Introduction

Cusp is a light-weight BLE framework build on CoreBluetooth, featured multi-thread-operation thanks to powerful GCD.

Same as bluetooth communication, there are two main roles in Cusp: Central and Peripheral. Central is in charge of scan, connect and disconnect ble devices, while the latter performs substantial communication tasks including service/characteristic discovering, read/write value, subscribe/unsubscribe value updates, etc. Upon all these operations, Cusp provides methods in a friendly call-back way. So, just focus on your UI/UE and data tranfer, leave the dirty ble work to Cusp.

Cusp is still an infant in cradle, your advices means its growth, and I am looking forward to any contributor, sincerely.

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
	}

	}, abruption: { (error) -> Void in

})
```

### Connect a BLE device
```swift
Cusp.central.connect(peripheral, success: { (response) -> Void in

	}, failure: { (error) -> Void in

	}, abruption: { (error) -> Void in

})
```

### Discover service or characteristic
```swift
peripheral.discover(serviceUUIDArray, success: { (response) -> Void in

	}, failure: { (error) -> Void in

})

peripheral.discover(characteristicUUIDArray, ofService: service, success: { (response) -> Void in

}, failure: { (error) -> Void in

})

```

### Read or Write
```swift
peripheral.write(data, forCharacteristic: characteristic, success: { (response) -> Void in

	}, failure: { (error) -> Void in

})
```

### Subscribe or Unsubscribe
```swift
peripheral.subscribe(characteristcNotify, success: { (response) -> Void in

	}, failure: { (error) -> Void in

	}, update: { (value) -> Void in

})
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

For now, it's recommended using Cusp in Swift. I have been recently testing Cusp in an Unity program, of which the bridge between C# and Swift is Objective-C and pure C, so I think it works well in OC either...(except those Swift-style enums).

## Installation

To install Cusp, one way is simply download sources from another Git repository: [Cusp-Pure](https://github.com/keyOfVv/Cusp-Pure.git), then add those sources into your project and DONE.

OR...

Cusp is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Cusp"
```

## Author

Ke Yang, ofveravi@gmail.com, [keyOfVv@Twitter](https://twitter.com/keyOfVv)

## License

Cusp is available under the MIT license. See the LICENSE file for more info.
