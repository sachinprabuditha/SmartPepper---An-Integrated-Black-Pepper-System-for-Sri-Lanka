# Flutter Development Commands

## 1. Open/Launch Android Emulator
```powershell
cd "F:\Year 4\My Research\ResearchProject"
flutter emulators --launch Pixel_5_API_35
```

Or to see all available emulators first:
```powershell
flutter emulators
```

## 2. Run the App on Emulator
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Frontend-Mobile"
flutter run -d emulator-5554
```

Or let Flutter auto-detect:
```powershell
flutter run
```

## 3. Hot Reload (while app is running)
Press `r` in the terminal where Flutter is running

Or use the command:
```powershell
# In the Flutter run terminal, just press 'r'
```

## 4. Hot Restart (while app is running)
Press `R` (capital R) in the terminal where Flutter is running

Or use the command:
```powershell
# In the Flutter run terminal, just press 'R'
```

## 5. Stop Debugging/Stop the App
Press `q` in the terminal where Flutter is running

Or use Ctrl+C in the terminal

## Additional Useful Commands

### Check Connected Devices
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Frontend-Mobile"
flutter devices
```

### Clean Build (if you have issues)
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Frontend-Mobile"
flutter clean
flutter pub get
flutter run
```

### Full Restart (stop and start again)
```powershell
# Stop: Press 'q' in Flutter terminal, then:
cd "F:\Year 4\My Research\ResearchProject\SKR-Frontend-Mobile"
flutter run -d emulator-5554
```

### Run in Release Mode
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Frontend-Mobile"
flutter run --release -d emulator-5554
```

## Quick Reference While App is Running

When Flutter is running, you'll see a prompt. Here are the available commands:

- `r` - Hot reload (fast, preserves state)
- `R` - Hot restart (full restart, resets state)
- `q` - Quit (stop debugging)
- `h` - List all available commands
- `c` - Clear the screen
- `v` - Open DevTools in browser

