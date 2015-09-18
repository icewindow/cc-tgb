# Terminal Glasses Bridge API
## About
This is an API for ComputerCraft and OpenPeripherals which lets you enhance the capabilities of yout Terminal Glasses

## Requirements
This API is written for and tested to work with ComputerCraft 1.73 and OpenPeripherals 1.1.1. It may work with older versions as well, though I didn't test that.
Other than that, the only thing you need to use this API is a computer (regular or advanced) connected to a Terminal Glasses Bridge, either directly or using modems and network cables.

## Installation
To install TGB, simply run ```openp/github get icewindow cc-tgb master tgb apis/tgb```

The last part ```apis/tgb``` could be anything, I recommend leaving it like that though.

## Getting started
This API uses what I call *enhanced surfaces*.

First thing you want to do is to load the API into your CraftOS. Next wrap your Terminal Glasses Bridge. Finally, you can get an enhanced surface. There are several ways to do that, I'll show one here.
```lua
os.loadAPI("apis/tgb")
local bridge = peripheral.find( "openperipheral_bridge" )
local surface = tgb.getEnhancedSurfaceFromSurface( bridge )
--[[ Profit! ]]
```
That's it. Now you can add all sorts of cool things to your Terminal Glasses!
For more info, and to see which methods are available from the enhanced surface, visit the [wiki](https://github.com/icewindow/cc-tgb/wiki).

----------
**Please note:**
I do this in my spare time as a hobby. I will add new functionality over time as I get the chance to do so.
Also, I am just one guy and I can only test so much myself. If you encounter any bugs, I will be very happy if you reported them back to me.

####Planned features
- [ ] More aesthetically pleasing terminal
- [ ] Buttons/checkboxes
- [ ] Support more image file formats
- [ ] More diagram types (piecharts?)
- [ ] ...