fftSmoothing is not a normal tweak, stop trying to treat it as one

tweaktype should it be handling above, and uniform?
**more likely** only uniforms

volume slider

playback bar

more friendly names for sliders

show slider descriptions somehow

remember previous tune on startup

onset detection

play button toggle

controls appear on tap, disappear after n seconds or on tap outside

mic input

kb shortcuts don't work on fftsmoothing slider

tidy up main.js

bin range adjustment

physics based shaders

file chooser
    1 or multiple
    multiple creates playlist
    read/write .m3u

---

# BUGS

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
