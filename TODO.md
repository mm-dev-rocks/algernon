more friendly names for shader sliders

better auto icon
better speaker icon
better info icon

fix fuzzy show/hide controls
- must stay visible while dragging sliders
- must stay visible while dragging memory slot
- must stay visible while hovering dropdown buttons and items

dropdowns need to be scrollable

another big slider like volume, to scale overall shader effect
can just use scaling variable from volume compensation

Use icons for sliders instead of labels
    - must change all internal names
    - must make sure each tweak is different enough to have its own icon/concept

file playback
    curently selection replaces playlist, should add to it
    need a way to delete tracks from playlist, single or all
    need to rebuild to refresh visible dropdown playlist
    should play next file in playlist by default (add standard shuffle loop single loop all)

file chooser should indicate current track

look into Soloud.instance.setGlobalVolume

why is spectral sphere grey bg?


mic input

kb shortcuts don't work on fftsmoothing slider

file chooser
    1 or multiple
    multiple creates playlist
    read/write .m3u

when track stops, time-based uniform should stop (or even slow to a stop)

handle missing/renamed files
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: SoLoudFileNotFoundException: The file was not found (on the C++ side).

[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: SoLoudFileNotFoundException: The file was not found (on the C++ side).


---

# BUGS

jumping to new track does not stop old track!

sometimes stored value for uniform is outside min/max due to dev/experiments. Should fix this on init

volume = 0 / black screen

switching memory slots does not update sliders/UI

fftSmoothing is not getting saved for the slot, acts globally

null checks on soundhandle in AlgernonPlayer

Not experienced this yet but worth implementing workarounds
https://github.com/alnitak/flutter_soloud/issues/126

Permissions for all OSes
Keep eye on
https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup#--android

Black screen on Tab S4

mac/ios builds
https://docs.page/alnitak/flutter_soloud_docs/get_started/setup#ios-and-macos-configuration

---

# DONE
look at enum, something wrong with relationship between ids and types
is shaderfilterquality doing anything?
look into performance problems with current shader recreation/shaderbuilder
com.example in app name
tidy up constants file

slider styles
    white text
    thinner track
occasional single:
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: 'dart:ui/painting.dart': Failed assertion: line 2028 pos 12: '<optimized out>': is not true.
#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:67:4)
#1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:49:5)
#2      Image.dispose (dart:ui/painting.dart:2028:12)
#3      _AlgernonPlayerState._onTick.<anonymous closure> (package:algernon/algernon_player.dart:229:23)
<asynchronous suspension>
```
dark theme (eg for start screen)
dropdown styles
sliders stack vertically
play button toggle
fftSmoothing is not a normal tweak, stop trying to treat it as one
tweaktype should it be handling above, and uniform?
**more likely** only uniforms
volume slider
show slider descriptions somehow
controls appear on tap, disappear after n seconds or on tap outside
remember previous tune on startup
memory slots for all slider tweaks for a shader + FFT smoothing
changing memory slot must update fft smoothing
play button gets clipped on narrow screen
changing shader something doesn't update correctly, need to log all values
fft slider looks correct by saved value but doesn't actually take effect until clicking to confirm
slider for 'binSmoothing' from player?
wire up charge to another couple of shaders
physics based shaders
tidy up main.js
tidy up screen.js
onset detection
playback bar
bin range adjustment
sometimes shader are messed up when changing shaders eg polar_warp
copy/paste memory slots
    drag+drop
    if same slot give message
