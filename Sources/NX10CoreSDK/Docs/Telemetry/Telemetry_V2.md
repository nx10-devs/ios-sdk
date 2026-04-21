Telemetry V2 API
NOTE: This API requires a valid session token - all calls to this API must include an Authorization header like this:
Authorization: Bearer <token>
NOTE: there are two touch events - touch-kb is for the keyboard whereas touch is for the games / general use.
This API accepts a single JSON object representing a telemetry capture window (a short period of time during which events were recorded). The payload is designed to be small on the wire, so event data is encoded as tuples (arrays with a fixed order) instead of objects with repeated field names.
If you haven’t worked with tuples before: think of them as “arrays where each position has a specific meaning”. The server validates that:
the array has the correct length
each value is in the correct position
each value has the correct type



Top-level payload shape
{
  bts: string,        // Base timestamp (ISO 8601 UTC time)
  ets: number,        // End timestamp offset (ms) from bts
  d: TelemetryEvent[] // Array of event tuples (see below)
}
bts — Base Timestamp (ISO string)
ISO-8601 timestamp that marks the start of the capture window.
Example: "2026-02-12T10:41:02.762Z"
This should be a UTC timestamp (typically ends with Z).
ets — End Timestamp offset (milliseconds)
A number representing how many milliseconds after bts the capture window ended.
Example: ets: 2500 means the capture window ended 2.5 seconds after bts.



d — Data (array of event tuples)
An array containing any mix of supported telemetry event tuples.
Each entry in d is a tuple that begins with an event type string (e.g. "touch", "gyro").



Timestamp strategy (how timing works)
Only the payload base time (bts) is a full ISO timestamp.
Events in d do not include full timestamps. Instead they include offsets from bts, in milliseconds.
So if:
bts = "2026-02-12T10:41:02.762Z"
an event has offset 120
That event happened at:
bts + 120ms → "2026-02-12T10:41:02.882Z"
This keeps payloads smaller and removes timezone ambiguity as long as bts is UTC.

Event tuple formats
All event tuples begin with a type tag in position 0 ("touch", "gyro", etc). After that, the positions are fixed.
1) Keyboard-touch events ("touch-kb")
Used for touch input associated with the on-screen keyboard.
Tuple format:
[
  "touch-kb",
  timestampOffsetMs,
  touchType,
  x,
  y,
  pressure,
  size,
  velocityX,
  velocityY
]
Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
touchType (string): "down" | "move" | "up"
x, y (number): touch coordinates (units depend on sender; be consistent)
pressure (number): pressure reading (often 0–1, but depends on platform)
size (number): touch size/radius value (platform-dependent)
velocityX, velocityY (number): velocity components


Example:
["touch-kb", 120, "down", 234.67, 151.67, 1, 1, 0, 0]


2) Touch events ("touch")
General touch input events. See Unity docs, iOS docs and Android docs.
Tuple format:
[
  "touch",
  “2”, // event version
  timestampOffsetMs,
  touchId,
  touchType,
  touchObject,
  xMm,
  yMm,
  touchRadiusMm,
]

Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
touchId (string): a unique ID for the gesture, constant across measurements for the same gesture (i.e. touching down, moving and then releasing)
touchType (string): "down" | "move" | "up" | “stationary” | “cancelled”
“down” when finger first touches screen
“move” when finger moved on the screen
“up” when finger lifted from screen
“stationary” when finger touching but hasn’t moved
“cancelled” when the system cancelled tracking for a touch before an “up” event
touchObject (string): null| “submit” | “backspace” | “space” | “upper” | “lower” | “numeric” | “non-alphanumeric” |  “emoji” | “utility”
null when the touch is not on a keyboard key or other labelled object
“submit” when sending a message or pressing go
“backspace” hitting backspace key
“upper” for uppercase alpha characters
“lower” for lowercase alpha characters
“numeric” for numbers
“non-alphanumeric” for other symbols/characters
“emoji” when inserting an emoji
“utility” when using non-character keys/buttons on the keyboard, like the emoji selector or gif search
xMm, yMm (number): touch coordinates in millimetres, where 0,0 is the bottom left corner
touchRadiusMm (number):  radius of touch contact in millimetres
Example:
["touch", “2”, 125, ”some-uuid”, “down”, 2, “upper”, 140, 286, 104]


3) Gyroscope events ("gyro")
Gyroscope sensor readings.
Tuple format:
[
  "gyro",
  timestampOffsetMs,
  x,
  y,
  z
]
Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
x, y, z (number): acceleration in m/s2
Example:
["gyro", 200, 0.01, 0.02, 0.98]




4) Accelerometer events ("acc")
Accelerometer sensor readings.
Tuple format:
[
  "acc",
  timestampOffsetMs,
  x,
  y,
  z
]
Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
x, y, z (number): angular velocities in rad/s
Example:
["acc", 210, 0.12, 9.78, 0.03]


5) Keyboard state event (“kb-state”)
Activation and deactivation of keyboard.

Tuple format:
[
  "kb-state",
  “1”, // event version indicator
  timestampOffsetMs,
  keyboardState,
]
Example:
["kb-state", “1”, 210, “up”]

Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
keyboardState (string): “up” | “down”

6) Text deletion event (“text-del”)
Text deletion using the backspace keyboard key.
Tuple format:
[
  "text-del",
  “1”, // event version indicator
  timestampOffsetMs,
  erasedTextLength,
]
Example:
["text-del", “1”, 210, 1]

Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
erasedTextLength (number): number of erased characters from a single backspace touch
7) Text correction event (“text-cor”)
Text correction events.

Tuple format:
[
  "text-cor",
  “1”, // event version indicator
  timestampOffsetMs,
  textCorrection,
]
Example:
["text-cor", “1”, 210, “autocorrect”]

Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
textCorrection (string): “autocorrect” | “suggest” | “undo”
“autocorrect” when a word is corrected automatically, without the use accepting the correction
“suggest” when a word is corrected from an optional suggestion by the user actively accepting it
“undo” when the user reverses a correction event



8) Screen event (“screen”)
Device screen locking and unlocking.

Tuple format:
[
  "screen",
  “1”, // event version indicator
  timestampOffsetMs,
  screenEvent,
]
Example:
["screen", “1”, 210, “unlock”]

Field meanings:
timestampOffsetMs (number): milliseconds offset from bts
screenEvent (string):  “lock” | “unlock”



9) Keyboard summary events ("kb")
A summary of keyboard typing statistics for the capture window (or a segment of it).
Tuple format:
[
  "kb",
  totalKeyPresses,
  erasedTextLength,
  averageHoldTimeMs,
  typingSpeedWpm,
  backspaceCount,
  flightTimesMs
]
Field meanings:
totalKeyPresses (number)
erasedTextLength (number)
averageHoldTimeMs (number)
typingSpeedWpm (number): words in window / seconds in window * 60?
backspaceCount (number): number of times backspace key hit within window?
flightTimesMs (number[]): array of flight-time durations in milliseconds (any length)


Example:
["kb", 62, 0, 138, 100, 9, [51,149,147,203,246,319,295,139,149,84]]

Note: Unlike the other events, the "kb" tuple currently does not include a timestamp offset in your schema. Treat it as a summary that applies to the overall capture window, rather than a single instant.

Full example payload
{
  "bts": "2026-02-12T10:41:02.762Z",
  "ets": 2500,
  "d": [
    ["touch-kb", 120, "down", 234.67, 151.67, 1, 1, 0, 0],
    ["touch-kb", 180, "move", 286.0, 102.0, 1, 1, -46.85, 145.75],
    ["touch-kb", 181, "up", 286.0, 104.0, 1, 1, -46.65, 176.22],

    ["gyro", 200, 0.01, 0.02, 0.98],
    ["acc", 210, 0.12, 9.78, 0.03],

    ["kb", 62, 0, 138, 100, 9, [51,149,147,203,246,319,295,139,149,84]]
  ]
}


Validation rules summary
bts must be an ISO timestamp string accepted by zJsISOString().
ets must be a number (milliseconds from bts to the end of the capture window).
d must be an array.
Each entry in d must match exactly one of the supported event tuple formats:
correct first element (the event tag)
correct length
correct types in each position
The envelope object is strict (z.strictObject) so unknown top-level keys will be rejected.

Practical sender guidance
Use UTC for bts (recommended: new Date().toISOString()).
Compute event times as: offsetMs = eventTimeMs - baseTimeMs.
Keep offsets within the [0, ets] range where possible (recommended).
Don’t send null or undefined in tuples—omit the event instead.

One implementation tip (client-side)
If you’re generating offsets:
const base = Date.now();                  // ms
const bts = new Date(base).toISOString(); // ISO UTC

function offset() {
  return Date.now() - base;
}

Then each event tuple uses offset() as the second element (where applicable).