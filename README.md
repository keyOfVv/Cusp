# Cusp


## Introduction

Cusp is a light-weight BLE framework build on CoreBluetooth, featured multi-thread-operation thanks to powerful GCD.

Same as bluetooth communication, there are two main roles in Cusp: Central and Peripheral. Central is in charge of scan, connect and disconnect ble devices, while the latter performs substantial communication tasks including service/characteristic discovering, read/write value, subscribe/unsubscribe value updates, etc. Upon all these operations, Cusp provides methods in a friendly call-back way. So, just focus on your UI/UE and data tranfer, leave the dirty ble work to Cusp.

Cusp is still an infant in cradle, your advices means its growth, and I am looking forward to any contributor, sincerely.

## Usage

### Preparation

```swift
import Cusp

Cusp.prepare { (available) in
			print(available ? "BLE IS AVAILABLE" : "BLE IS NOT AVAILABLE")
			if available {
				Cusp.central.registerPeripheralClass(C2.self, forNamePattern: "MN581N_[A-Z0-9]{5}")
			}
		}
```

### Custom Peripheral Class

Sometimes, i think it's more convenient to have a custom class (subclassing `Peripheral` is REQUIRED) of Ble device instance for my project. I can define its own properties like "advertisingUUID", "writeDataUUID", "notifyUUID", etc. Then, i can use those properties in my code without typing literally.

```swift
// my custome Peripheral class
public class C2: Peripheral {

	/**
	UUIDs

	- Advertise: ad
	- Pipe:      UUID of service that contains below characteristics
	- Notify:    UUID of characteristic for data update notification
	- Write:     UUID of characteristic for writing data
	*/
	public enum UUID: String {
        case Advertise = "1803"
        case Pipe      = "FFF0"
        case Notify    = "FFF1"
        case Write     = "FFF2"
	}

	/**
	custom communication orders

	- GetPM:      get PM2.5 value
	- GetVer:     get device version No.
	- GetBattery: get device battery life
	- Sleep:      make device sleep
	- WakeUp:     wake device up
	- OT:         ??
	- Beats:      ??
	*/
	enum Order: String {
        case GetPM      = "tp=1"
        case GetVer     = "tp=3"
        case GetBattery = "tp=4"
        case Sleep      = "tp=5"
        case WakeUp     = "tp=6"
        case OT         = "tp=7"
        case Beats      = "tp=8"
	}

	// MARK: Computed Properties

	var service: String {
		return UUID.Pipe.rawValue
	}
	
	var charNotify: String {
		return UUID.Notify.rawValue
	}
	
	var charWrite: String {
		return UUID.Write.rawValue
	}
}
```

After define my own custom peripheral, i can register it to Cusp with class name and regex of name pattern:

```swift
Cusp.central.registerPeripheralClass(C2.self, forNamePattern: "MN581N_[A-Z0-9]{5}")
```

If not, just use `Peripheral`. It's adequate.

### Scan
```swift
/// scan for all peripherals
Cusp.central.scanForUUIDString(nil, completion: { (advertisementInfoArray) -> Void in

	for advertisementInfo in advertisementInfoArray {
		print(advertisementInfo.peripheral.name)
		print(advertisementInfo.advertisingUUIDStrings)
		print(advertisementInfo.RSSI)
	}

	}, abruption: { (error) -> Void in

})
```

```swift
/// scan for peripheral of specific advertising UUID
Cusp.central.scanForUUIDString(["1803"], completion: { (advertisementInfoArray) -> Void in
	
	// deal with advertisements ...
	
	}, abruption: { (error) -> Void in

})
```

### Connect
```swift
Cusp.central.connect(peripheral, success: { (response) -> Void in

	// successfully connected ...
	
	}, failure: { (error) -> Void in
	
	// some issues occurred ...
	
	}, abruption: { (error) -> Void in

	// an established connection abrupted due to some reasons (e.g., out of distance, BLE device out of battery, etc.) ...
})
```

### Discover (service / characteristic)
```swift
/// discover service(s)
peripheral.discover(["FF60"], success: { (response) -> Void in
	
	}, failure: { (error) -> Void in

})
/// discover characteristic(s)
peripheral.discover(["FF61", "FF62"], ofService: peripheral["FF60"], success: { (response) -> Void in

}, failure: { (error) -> Void in

})

```

After discovering operations complete, you can get `Service` & `Characteristic` objects using subscription (Swift only):

```swift
let service = peripheral["FF60"]
let charA = service["FF61"]
let charB = service["FF62"]
...
```

For Objective-C, using:

```OC
Service *service = [peripheral serviceWith: @"FF60"];
Characteristic *charA = [peripheral characteristicWith: @"FF61"];
Characteristic *charB = [peripheral characteristicWith: @"FF62"];
...
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
	// any value updated via characteristcNotify will call update block...
})
```

## Requirements

* iOS 8.0+
* swift 3.0
* Xcode 8.0

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

Ke Yang, ofveravi@gmail.com, [keyOfVv@Twitter](https://twitter.com/keyOfVv)

## License

Cusp is available under the MIT license. See the LICENSE file for more info.
