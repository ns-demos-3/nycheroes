# Street sprint

Launch `?sprint=1` (desktop: `-- --sprint=1`). This optional solo activity
starts behind a marked 100 m stretch of Sixth Avenue, at world x=420,
z=-220, facing along the avenue. It defaults to solo without altering a
normal session. Do not combine it with host/join or demo options.

Stop behind the green START line, then use the normal movement controls:
W / left stick; Shift / the sprint control is allowed. Cross the gold
FINISH line while staying within 6 m of the course center. The timer starts
at the start-line crossing and ends at the finish-line crossing, with
crossings interpolated between physics samples. The panel shows elapsed
time, distance, result and best time for this session. Click/tap **Retry
street sprint** to return to staging, wait for streamed collision and try
again. Normal play remains available after a result; reload without the
flag to remove the activity.

Jumping, flight, webs, swimming, leaving the corridor, free camera, travel,
co-op, missing collision or more than 60 seconds void a run. Brief ground
contact gaps of less than 0.18 s accommodate curbs. Unexpected displacement
above normal sprint speed also voids it. World-space samples and markers
survive floating-origin shifts. Scores are local and session-only; there
is no leaderboard or multiplayer race. This is a modest local challenge,
not an anti-cheat system. Ambient people and traffic use normal settings;
parked cars and street furniture remain real obstacles. No tiles or assets
need rebuilding.

## Focused checks

`godot --headless --path . res://tests/sprint_test.tscn` checks the timer,
retry, invalid powers, skipped staging, teleports, corridor, timeout and
floating-origin continuity using synthetic samples. `hero_moves_test.tscn`
checks the unchanged movement implementation.

## Native gameplay recording

`tools/recording/street_sprint_movie.gd` loads **scenes/world.tscn** and
feeds ordinary actions through the actual PlayerInput and Hero. It submits
the first-launch Play form, waits for the city and ground, stands for
1.5 s, holds forward for a normal 9 m/s run, releases on completion, presses
the real Retry button at 15 s, and toggles flight at 17 s to demonstrate a
void run. It quits at 21 s. It never sets the hero's position except through
the activity's normal Retry operation, and never changes movement speed,
physics FPS or time scale. It hides the optional stats overlay using its
normal saved setting and restores that setting on normal exit.

Rehearse without the three movie flags first. With the preview server
running (it proxies existing public city tiles):

```sh
godot --path . --resolution 1280x720 --position 0,0 \
  --audio-driver Dummy \
  --write-movie /data/sprint/native.avi --fixed-fps 30 --disable-vsync \
  --script tools/recording/street_sprint_movie.gd -- \
  --sprint=1 --solo=1 --quality=low --time=12:00 \
  --peds=0 --traffic=0 --gangs=0 --tiles_url=http://localhost:8060/tiles
```

The Movie Maker renders every frame even when rendering slower than real
time. It logs `[sprint capture] gameplay begins frame=N`. Trim only the
loading prefix, starting at frame N / 30 seconds, then encode 21 seconds
with ffmpeg using H.264 and AAC, preserving 30 FPS and audio timing. Inspect
representative frames and ffprobe the MP4. The low preset renders the 3-D
view at 640x360 inside a native 1280x720 movie; UI is full resolution. There
are no synthetic visuals or accelerated frames. `--gangs=0` is passed, but
the existing quality preset currently overrides it to one ambient gang;
the recording does not conceal or patch that behavior.
