# AHK Automation Tool

A lightweight and powerful automation tool written in **AutoHotkey v2**. This software allows you to record, edit, and replay keyboard and mouse macros through an intuitive graphical interface.

## 🚀 Features

*   **Easy Recording**: Capture your mouse movements and keystrokes in real-time.
*   **Flexible Playback**:
    *   **1x**: Run once.
    *   **N times**: Repeat a specific number of times.
    *   **Loop**: Infinite loop (stop with `Esc`).
*   **Turbo Mode**: Speed up your macros by intelligently reducing delays.
*   **Key Binding (Hotkeys)**: Bind any macro to a specific keyboard key (e.g., `F1`, `Ctrl+M`) for quick execution.
*   **Code Editor**: Manually edit your macros using the built-in JSON editor.
*   **Management**: Rename, delete, and organize your scripts directly from the interface.
*   **Customization**: Supports custom application icon (`icon.ico`).

## 📋 Prerequisites

*   **Operating System**: Windows 10/11.
*   **AutoHotkey v2**: This software **must** be installed to run the script.
    *   [Download AutoHotkey v2](https://www.autohotkey.com/)

## 🛠️ Installation

1.  Clone this repository or download the source files.
2.  Ensure you have AutoHotkey v2 installed.
3.  (Optional) Place an `.ico` image named `icon.ico` in the root folder to use your own logo.

## 🎮 Usage

### Launch
Double-click on **`Main.ahk`** to start the program.

### Recording a Macro
1.  Click **"Record New"**.
2.  Enter a name for your macro.
3.  The interface will hide, and recording will begin. Perform your actions.
4.  Press **`F8`** to stop recording.

### Playing a Macro
1.  Select a macro from the list.
2.  Choose the playback mode (1x, N times, or Loop).
3.  (Optional) Check **"Turbo Mode"** for faster execution.
4.  Click **"Play"**.
5.  Press **`Esc`** to interrupt playback at any time.

### Binding a Key
1.  Select a macro.
2.  Click **"Assign Key"**.
3.  Press the key you want to bind (e.g., `F5`, `Numpad1`).
4.  Confirm the binding.
5.  The key will now directly trigger the macro, even if the interface is minimized.

## ⌨️ Default Hotkeys

The application comes with predefined keys for integration with external devices (like a Stream Deck):

*   **`F13`**: Toggle Play/Stop for the selected macro.
*   **`F14`**: Start/Stop Recording.
*   **`F15`**: Show/Hide the main UI.

## 📂 Project Structure

*   `Main.ahk`: Entry point of the program.
*   `Lib/`: Contains logical libraries (UI, Player, Recorder, MacroManager).
*   `SavedMacros.json`: Storage file for your macros (generated automatically).
