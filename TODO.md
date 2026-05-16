read/write .m3u

mac/ipad look into best file types to support

need to keep screen awake optionally?

mic input
+mic session setup https://pub.dev/packages/audio_session

choose great defaults for all shaders

all/many shaders: make bins distribute evenly across eg arms, discs, whatever items

kb shortcuts don't work on fftsmoothing slider

audio_service: https://pub.dev/packages/audio_service
Note: As of Android 12, an app must have permission to restart a foreground service in the background, otherwise a
ForegroundServiceStartNotAllowedException will be thrown. To avoid such an exception, you can either set
androidStopForegroundOnPause to false in your AudioServiceConfig which keeps the service in the foreground during a
pause so that restarting the foreground service is unnecessary, or you can keep the default androidStopForegroundOnPause
setting of true (in line with best practices) and request the user to turn of battery optimisation for your app via the
optimize_battery package. For more information, read this page.
If you use any custom icons in notification, create the file android/app/src/main/res/raw/keep.xml to prevent them from being stripped during the build process:
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
  tools:keep="@drawable/*" />
By default plugin's default icons are not stripped by R8. If you don't use them, you may selectively strip them. For example, the rules below will keep all your icons and discard all the plugin's:


---

# BUGS

cant long press mem slot on android

mouse not working on android?

chromeos slow no playback bar until rebuild

chooser silently fails when trying to add new tracks (happened after trying to open broken opus??)

when adding new tracks, selector still shows old track

Not experienced this yet but worth implementing workarounds
https://github.com/alnitak/flutter_soloud/issues/126


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
better auto icon
better speaker icon
better info icon
look into Soloud.instance.setGlobalVolume
why is spectral sphere grey bg?
file chooser should indicate current track
fix fuzzy show/hide controls
- must stay visible while dragging sliders
- must stay visible while dragging memory slot
- must stay visible while hovering dropdown buttons and items
    need to rebuild to refresh visible dropdown playlist
more friendly names for shader sliders
Use icons for sliders instead of labels
    - must change all internal names
    - must make sure each tweak is different enough to have its own icon/concept
jumping to new track does not stop old track!
chooser does not auto update on trac advance
switching memory slots does not update sliders/UI
sometimes stored value for uniform is outside min/max due to dev/experiments. Should fix this on init
fftSmoothing is not getting saved for the slot, acts globally
another big slider like volume, to scale overall shader effect
can just use scaling variable from volume compensation
    - Ensure is saved to prefs
    - 
null checks on soundhandle in AlgernonPlayer
list of shaders needs to be scrollable
    need a way to delete tracks from playlist, single or all
pixel doubling should decrease based on achieved frame rate
add new tracks, if nothing playing the first track should start
next/previous buttons
spectral sphere add distance/expand slider for charge multiplier (distance of dots)
interference_waves add some sliders, make good or remove
safe area put UI inside but painter can go outside
better visible names for shaders
roots tune for better reaction to fft
extra lib dir?
file playback
    should play next file in playlist by default (add standard shuffle loop single loop all)
    1 or multiple
    multiple creates playlist
first run steer towards 'add some tracks'
hairy or grassy shaders
fullscreen with leanflutter/window_manager package
F11 plus toggle/icon
delete unused shaders
ros tunnel smooth start/end?
volume = 0 / black screen
Permissions for all OSes
Keep eye on
https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup#--android
mac/ios builds
https://docs.page/alnitak/flutter_soloud_docs/get_started/setup#ios-and-macos-configuration
curently selection replaces playlist, should add to it
media keys?
when track stops, time-based uniform should stop (or even slow to a stop)
handle missing/renamed files
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: SoLoudFileNotFoundException: The file was not found (on the C++ side).

[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: SoLoudFileNotFoundException: The file was not found (on the C++ side).

[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: SoLoudFileLoadFailedException: File found, but could not be loaded! Could be a permission error or the file is corrupted. (on the C++ side).

AlgernonPlayer::loadFile error: Problem loading file
SoLoudFileLoadFailedException: File found, but could not be loaded! Could be a permission error or the file is corrupted. (on the C++ side).

══╡ EXCEPTION CAUGHT BY SCHEDULER LIBRARY ╞═════════════════════════════════════════════════════════
The following StateError was thrown during a scheduler callback:
Bad state: No element

When the exception was thrown, this was the stack:
#0      ListBase.reduce (dart:collection/list.dart:187:22)
#1      AudioAnalysis.suggestedBoundaryThreshold (package:algernon/audio_analysis.dart:295:21)
#2      ShaderModel.calibrateAudioEnergy (package:algernon/shader_model.dart:51:42)
#3      PainterConfigModel.currentShader= (package:algernon/painter_config_model.dart:45:20)
#4      ShaderChooser.build.<anonymous closure> (package:algernon/shader_chooser.dart:22:40)
#5      _DropdownMenuState._buildButtons.<anonymous closure> (package:flutter/src/material/dropdown_menu.dart:1020:40)
#6      _MenuItemButtonState._handleSelect.<anonymous closure> (package:flutter/src/material/menu_anchor.dart:1006:25)
#7      SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1430:15)
#8      SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1357:11)
#9      SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1198:5)
#10     _invoke (dart:ui/hooks.dart:356:13)
#11     PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
#12     _drawFrame (dart:ui/hooks.dart:328:31)

lissajous make hue less jumpy, add saturation slider
lag between gapless tracks... try reading next file before end? and/or read fewer samples. time with stopwatch
dots to indicate scale/res
BLACK SCREEN ON TAB S4
add hue range / adjustment to voronoi
tendrils
- better name
- make blades appear at back//front depending on freq/bin number
cracky background playback on android (audio service?)
pause button shows wrong state
