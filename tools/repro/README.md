# Health warning gameplay replay

`health_warning_replay.tscn` runs the actual `scenes/world.tscn`. It drives
ordinary `HeroInput`: walk toward the nearest naturally spawned gang, take
normal punches until knocked out, wait for automatic get-up and up to five seconds for another
normal hit, then toggle flight and ascend out of reach to recover. It never
sets health, damages the hero, changes physics/timers, or places enemies.
The camera stays in the normal third-person view; the stats overlay is hidden
for legibility. The seed makes gang placement more repeatable; loading and
ragdoll timing can still vary. The scene quits after recovery or a timeout.

Start the repository's preview server for its tile proxy, then rehearse:

```sh
LP_NUM_THREADS=2 godot --path . --audio-driver Dummy --resolution 1280x720 \
  --fixed-fps 30 res://tools/repro/health_warning_replay.tscn -- \
  --tiles_url=http://localhost:8060/tiles --quality=low --solo=1 \
  --name=HealthReview --peds=0 --traffic=0 --gangs=1 --mute=1 \
  --spawn=420,30,-220,-29 --replay_frames=/data/health-warning
```

`LP_NUM_THREADS` limits software rasterizer workers in CPU-only sandboxes;
it does not alter simulation speed. `--replay_frames=DIR` optionally saves a
viewport PNG every 150 rendered frames (create the directory first). This
option belongs to this replay, not the normal game. Add `--touch=1` to inspect
the landscape phone layout. The normal game needs no feature launch flag.

To record, add `--write-movie /data/health-warning/native.avi` before `--`.
Movie Maker renders every frame at 30 FPS, even if rendering is slower.
The log identifies FIRST_LOW_FRAME, KNOCKOUT_FRAME, GETUP_FRAME, and
FINISHED_FRAME in rendered frames. Extract a continuous 12–25 second window
from the low-health encounter with ffmpeg; retain 30 FPS and original timing,
without interpolation or speed changes. The recording is muted deliberately.
Keep full native output and logs outside git.

For a longer recovery demonstration, add `--replay_recovery=1`. This replay-only
option escapes as soon as natural punches take health to 30 or below, then
waits in normal flight while the unchanged four-second delay and regeneration
run. Record it separately and label cuts between runs when combining clips.
