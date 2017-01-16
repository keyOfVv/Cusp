# Cusp


## Introduction

Cusp is a light-weight BLE framework build on CoreBluetooth, featured multi-thread-operation thanks to powerful GCD, designed to make BLE programming easier and happier.

If your app plays as central in BLE communication, use `CuspCentral` class.

## Usage

### Prepare

To get the true state of device's BLE module, CuspCentral shall be prepared BEFORE any operations.

```Swift
import Cusp

CuspCentral.defaultCentral.prepare { (available) in
	print("BLE is \(available ? "" : "NOT ")ready")
}
```

### Scan

```swift
import Cusp

/// scan for all peripherals
CuspCentral.defaultCentral.scanForUUIDString(nil, completion: { (advertisementInfoArray) -> Void in

	for advertisementInfo in advertisementInfoArray {
		print(advertisementInfo.peripheral.name)
		print(advertisementInfo.advertisingUUIDStrings)
		print(advertisementInfo.RSSI)
	}

	}, abruption: { (error) -> Void in

})
```

```swift
import Cusp

/// scan for peripheral of specific advertising UUID
CuspCentral.defaultCentral.scanForUUIDString(["1803"], completion: { (advertisementInfoArray) -> Void in
	
	// deal with advertisements ...
	
	}, abruption: { (error) -> Void in

})
```

### Connect

```swift
import Cusp
CuspCentral.defaultCentral.connect(peripheral, success: { (response) -> Void in

	// successfully connected ...
	
	}, failure: { (error) -> Void in
	
	// some issues occurred ...
	
	}, abruption: { (error) -> Void in

	// an established connection abrupted due to some reasons (e.g., out of distance, BLE device out of battery, etc.) ...
})
```

### Discovering service/characteristic?... NEVER

After successfully connected with peripheral, we can perform read/write/subscribe/unsubscribe operations directly without discovering related service(s)/characteristic(s) first, all these discovering work are undertook internally. 

### Read or Write
 
```swift
peripheral.write(data, toCharacteristic: "FE61", ofService: "FE60", success: { (response) -> Void in

	}, failure: { (error) -> Void in

})

```

```swift
peripheral.read(characteristic: "FE62", ofService: "FE60", success: { (response) -> Void in

	}, failure: { (error) -> Void in

})

```

### Subscribe or Unsubscribe

```swift
peripheral.subscribe(characteristic: "FE63", ofService: "FE60", success: { (response) -> Void in

	}, failure: { (error) -> Void in

	}, update: { (value) -> Void in
	// any value updated via characteristcNotify will call update block...
})
```
```swift
peripheral.unsubscribe(characteristic: "FE63", ofService: "FE60", success: { (response) -> Void in

	}, failure: { (error) -> Void in

})
```

## Requirements

* iOS 8.0+
* swift 3.0+
* Xcode 8.0+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.
You can install Carthage with [Homebrew](http://brew.sh) using the following command:

```sh
$ brew update
$ brew install carthage
```

To integrate Cusp into your Xcode project using Carthage, specify it in your Cartfile:

```sh
github "keyOfVv/Cusp"
```

Run `carthage update` to build the framework and drag the built Cusp.framework (in Carthage/Build/iOS folder) into your Xcode project (Linked Frameworks and Libraries in Targets), and DON'T forget to add Cusp.framework as an input file in Carthage's Run Script specified in `Targets`>`Build Phases`>`Run Script`.

## Author

Ke Yang, ofveravi@gmail.com, [keyOfVv@Twitter](https://twitter.com/keyOfVv), QQ:71028 (for my Chinese fellows).

## License

Cusp is available under the MIT license. See the LICENSE file for more info.
