# Waypoint Movie Maker capture

`waypoint_movie.tscn` instantiates the actual `scenes/world.tscn`. It waits
for streamed collision, uses the real options/address/Mark flow, holds the
normal forward input for eight seconds, turns the ordinary camera, and
clears through the options menu. It does not alter movement, physics, time
scale, city data or rendering logic. The menu pauses solo gameplay as usual.
Coordinates select a point along Sixth Avenue; this is straight-line ground
guidance, not an entrance or street route. Pedestrians and moving traffic use zero population launch flags to keep
software rendering practical; the low preset still retains one gang.
The driver uses a separate settings file and removes it on exit.

Run the preview proxy first, then rehearse without `--write-movie`:

```sh
LP_NUM_THREADS=2 godot --path . --audio-driver Dummy --resolution 1280x720 \
  --write-movie /data/waypoint/native.avi --fixed-fps 30 \
  res://tools/recording/waypoint_movie.tscn -- \
  --solo=1 --quality=low --peds=0 --traffic=0 --gangs=0 --mute=1 \
  --spawn=420,30,-220,-29 --tiles_url=http://localhost:8060/tiles
```

The script logs the first gameplay render frame. Trim only the loading
prefix at that frame, retain 30 fps and all subsequent frames, and encode
H.264/yuv420p MP4. Do not speed up or interpolate. The clip is about 18 s.
Inspect a contact sheet and use ffprobe to confirm 1280x720 at 30 fps.
