# algernon

What is flutter\_soloud?[](https://docs.page/alnitak/flutter_soloud_docs#what-is-flutter_soloud)What is flutter\_soloud?[](https://docs.page/alnitak/flutter_soloud_docs#what-is-flutter_soloud)



## Dev/build

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
