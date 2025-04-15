# KlipperView Micro

> _A crazy harebrained idea to make a Ubiquiti-style screen for my 3D printer._

**KlipperView Micro** is a compact, Flutter-based UI designed to serve as a simplified [KlipperScreen](https://github.com/jordanruthe/KlipperScreen) for your Klipper-powered 3D printer. Inspired by the sleek aesthetics of Ubiquiti devices, this project aims to deliver a clean, snappy, and modern interface— running on something like a Raspberry Pi using [flutter-pi](https://github.com/ardera/flutter-pi).


# 🚀 Goals

- A beautiful minimal interface for Klipper printer status and basic controls.
- Touchscreen-optimized UI, designed for a smartwatch-style AMOLED screen (~2 inches), but there's no reason you cant run it on something larger.
- Lightweight, responsive, and gesture-friendly.
- Runs on bare metal via [`flutter-pi`](https://github.com/ardera/flutter-pi) (eventually...).


# 📦 Project Status

This project is **under early development**. Expect broken features, weird ideas, and strange detours.


### ✅ What's Working

- Connection to [Moonraker](https://github.com/Arksine/moonraker) via JSON-RPC
- Live CPU and RAM usage charts
- Temperature readings for tool head and bed
- File list display with "Start Print" functionality
- Basic print controls (Stop, Pause, Cancel)
- Live print progress and ETA with boarder animation as a progress indicator

### 🐞 Known Problems

- Not optimized in the slightest
- No persistent reconnect logic if connection drops
- Limited error handling for bad or unexpected API responses
- Gesture handling is still experimental and may be glitchy
- UI scaling may be inconsistent across screen sizes
- Progress indicator is janky and NOT smooth at all


### 🌱 Future Features / New Ideas

- Palm entire screen for emergency stop
- Print thumbnail showing on status screen
- Touch-friendly jog and move controls (sort of working but ui overflows the screen)
- Better reconnect and offline handling
- Deployable bundle for [`flutter-pi`](https://github.com/ardera/flutter-pi)
- Installer script or prebuilt image for Raspberry Pi/BTT CB2


## ❓ FAQ

### Does this actually work?
Technically, yes. It connects to the printer via the [moonraker](https://github.com/Arksine/moonraker) api and has some functionality. It’s a work in progress — check back soon-ish.

### What platform does it run on?
Ideally: a Raspberry Pi running [flutter-pi](https://github.com/ardera/flutter-pi).  
It also runs fine on desktop or mobile for development and testing, or even as an app interface on your phone.

### Do you have compiled versions for me to try?
Haha... no 🙃

### How do I run it?
You'll have to figure that out!  
Check out the [Flutter docs](https://docs.flutter.dev) for instructions on installing and building for different platforms.  
This whole thing has been a learning experience for me, and... I’m still learning.


# 📸 Screenshots
## Status Screen
![KlipperView Micro](/docs/screenshots/status.png)

## Menu
![KlipperView Micro](/docs/screenshots/menu.png)

## File List
![KlipperView Micro](/docs/screenshots/files.png)

## CPU and RAM Usage
![KlipperView Micro](/docs/screenshots/resources.png)

## Jog Controls
![KlipperView Micro](/docs/screenshots/movment.png)

# 🤝 Contributions

This is a solo side project right now, but feel free to fork it, open issues, or suggest ideas. Just be chill — I’m making this up as I go.


# 📜 License

This project is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).
