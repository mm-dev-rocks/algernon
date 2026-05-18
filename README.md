# Algernon Audio Visualiser

An audio player with shaders animating in time to the music. Named after Algernon the mouse from the sci-fi short story
'[Flowers for Algernon](https://www.sdfo.org/gj/stories/flowersforalgernon.pdf)' by Daniel Keyes.

![Logo: Algernon the mouse](assets/icon/algernon-icon.png)


---

# How to Use

## Controls
- Tap the screen to show/hide controls
- Add some audio files (access the playlist via the bottom dropdown)
- Select animations from the top dropdown

## Sliders
- Ajust sliders to change how the current animation reacts to the music (your settings will be remembered)
- **The top slider is often the most important** as it adjusts stability (smooth animation) vs responsiveness (matching the music)

## Memory Slots
- The numbers [1] to [5] above the sliders are memory slots
- Each animation has 5 memory slots to save your favourite settings
- Memory slots can be copied: long press a slot until it turns pink, then drag it over another slot


---

## Special build instructions for ARM64 Linux

**flutter\_soloud on Linux ARM64**

1.  Install system audio libraries:

bash

```
sudo apt install libasound2-dev libflac-dev libopus-dev libogg-dev libvorbis-dev
```

2.  Run with system libraries flag:

The bundled libraries in flutter\_soloud are x86\_64 only. `TRY_SYSTEM_LIBS_FIRST=1` tells it to use system libraries instead.

```bash
TRY_SYSTEM_LIBS_FIRST=1 flutter run -d linux
```

OR FOR PROJECT-PERMANENT FIX

```
# linux/CMakeLists.txt
# Add at top of file
set(ENV{TRY_SYSTEM_LIBS_FIRST} 1)
```

That way it's in the project itself, works on any machine, and `flutter run` just works.


`linux/CMakeLists.txt` is part of your project and lives in your repo. Flutter generates it once when you first create the project and never touches it again.
