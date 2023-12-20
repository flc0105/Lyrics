# Lyrics App for macOS

This macOS application offers a real-time lyrics display panel synced with the currently playing track on your system. By integrating with macOS Now Playing information, it retrieves details about the artist, title, and playback time. The app then reads local LRC (Lyric) files associated with the playing track, providing synchronized lyrics in a dedicated window.

## Features

- **Real-time Lyrics Display:** Continuously updates and displays lyrics based on the current playback time of the system's Now Playing track.

- **LRC File Integration:** Synchronizes lyrics with the playing track using LRC files, enhancing the music listening experience.

- **Calibration Menu:** Allows users to adjust lyrics progress for accurate synchronization with music playback.

- **Player Integration:** Automatically registers and unregisters for Now Playing notifications when specified music players start or exit.

## How to Use

1. **Launch the Application:** Open the application on your macOS system.

2. **Automatic Player Integration:** The app automatically registers for Now Playing notifications upon opening the specified music player. It listens for events such as play, pause, resume, and track changes.

3. **Start Playback:** Open your music player and start playback. The app syncs with the Now Playing track.

4. **Lyrics Display:** The lyrics window shows real-time lyrics, scrolling according to the playback time of the playing track. Lyrics are matched with the playing track by naming LRC files as "artist - title.lrc" within the lyrics folder.

5. **Calibrate Lyrics Progress:** Due to the use of macOS's private APIs instead of direct player association, occasional delays may occur, especially during playback resumption. Adjust lyrics progress for the current track using the calibration menu if needed.

## Build and Run

To build and run the application:

1. Clone the repository to your local machine.

2. Open the Xcode project file.

3. Build and run the project using Xcode.

4. Enjoy synchronized lyrics display.

Feel free to contribute, report issues, or suggest enhancements to improve this lyrics display app!

## Screenshot

One-Line Lyrics:
![SCR-20231220-nvhg](https://github.com/flc0105/Lyrics/assets/101919965/7d40622f-2108-440d-a102-2a97d8010bb3)

Two-Line Lyrics (original and translation):
![SCR-20231220-nxtm](https://github.com/flc0105/Lyrics/assets/101919965/838dd015-0483-4626-9566-1aaf0ddf5eb7)
