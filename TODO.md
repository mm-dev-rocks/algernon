more friendly names for shader sliders

onset detection

mic input

kb shortcuts don't work on fftsmoothing slider

bin range adjustment

playback bar
file chooser
    1 or multiple
    multiple creates playlist
    read/write .m3u

---

# BUGS


volume = 0 / black screen

null checks on soundhandle in AlgernonPlayer

Not experienced this yet but worth implementing workarounds
https://github.com/alnitak/flutter_soloud/issues/126

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
