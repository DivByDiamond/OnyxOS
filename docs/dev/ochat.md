# ochat: chat and network tools for the OC2R radio network

`ochat` (command line) and `ochat-gui` (framebuffer + mouse) let a person at a
guest PC talk to other PCs and robots by their ORA address (`7K3F:02Q9`), list
the devices on the radio network and ping them. Both live in OnyxApps and are
built and packaged with the other apps (`scripts/build-apps.py`); they run in
ring 1, like `oc2ctl`, because they open the raw RPC bus `/dev/hvc0`.

## One process owns the bus

The OC2R RPC protocol has no request IDs and the kernel does not stop a second
opener of `/dev/hvc0`. Run only one of `oc2ctl`, `ochat`, `ochat-gui` at a time.
If another program holds the bus, or the machine has no power, the first call
times out and the tools print `no reply from the RPC bus: it may be owned by
another program ...`. After any timeout a running tool refuses further calls
(`RPC bus out of sync`); exit and start it again once the other program is gone.

## ochat

```text
ochat send <address|alias> <text>   send one message (text up to 1024 bytes, UTF-8)
ochat recv [--follow]               print waiting messages; --follow keeps polling
ochat shell                         interactive chat (see below)
ochat who                           list devices: address, online/offline, alias
ochat ping <address|alias> [-c N]   N = 1..100 (default 4); RTT per reply, 3 s timeout
ochat status [address|alias]        own address, endpoint, security, route estimate
```

`recv` consumes messages: the radio queue is emptied when polled, so a second
reader sees nothing. `ping` exits 0 when at least one reply arrived. Aliases are
resolved through the device list; ambiguous or unknown aliases are rejected.

`ochat shell` prompt commands: `/to <address|alias>` choose the peer, `/who`,
`/ping [dest]`, `/history` (last 20 of the 64 kept), `/quit` (or Ctrl-D on an
empty line, Ctrl-C). Any other line is sent to the current peer. Incoming
messages appear above the prompt; the first sender becomes the peer if none is set.

Incoming text is sanitised before it reaches the terminal: invalid UTF-8 becomes
`?`, control characters (including ESC) are dropped.

## ochat-gui

Runs on `/dev/fb0` with the mouse, using the otablet widget toolkit on a
240x112 logical screen scaled to the framebuffer. Left: device list (click to
select; `!` unread, `*` online, `-` offline, `>` selected), UP/DOWN scroll, PING
and REFR (refresh list). Right: history with the selected device (green = sent).
Bottom: input line, typed on the terminal keyboard; Enter or SEND sends. Top
right: ping indicator (`PING 12.3MS 0%` = last RTT and loss, dot colour = state).
Tab cycles contacts, `/to ADDRESS` opens a chat with an address not in the list,
`/ping` pings the selected contact. Right click or Ctrl-C exits. The GUI shows
ASCII only (other characters appear as `?`). Keyboard input is read from stdin, so
start it from the console that has the keyboard focus.

## Message format

Service `chat`, channel `msg`, payload = UTF-8 text of at most 1024 bytes, no
control characters (tab/newline/CR become spaces; the text is trimmed). Longer
or invalid text is rejected, never truncated.

## RPC contract with the mod (to be confirmed by the mod side)

All calls go to the `gps_tower` device. Methods used: `registerRadioService`,
`getRadioAddress`, `getRadioStatus`, `sendRadioMessage`, `pollRadioMessages`,
`pingRadio`, `pollRadioEvents`, `estimateRadioRoute`, plus the new
`listRadioDevices`. JSON shapes assumed for Gson output of the Java types:

- `getRadioAddress` -> `"XXXX:XXXX"` string.
- `getRadioStatus` -> object with `endpoint`, `enrolled`, `attached`,
  `security`, `applicationSecurity`, `ethernetSecurity`.
- `pollRadioMessages` -> array of `RadioMessage` objects. Used fields:
  `sourceAddress` (a `"XXXX:XXXX"` string or `{"network":n,"device":n}`),
  `service`, `channel`, optional `type` (only `MESSAGE` is shown), `payload`
  (array of byte values -128..255, or a string). Other services and malformed
  entries are skipped.
- `pollRadioEvents` -> array of `Event` objects with `requestId` (UUID string),
  `state` (`ACCEPTED`, `RUNNING`, `COMPLETED`, `FAILED`, `TIMED_OUT`,
  `DISCONNECTED`) and `roundTripNanos`. Ping is done at `COMPLETED`.
- `estimateRadioRoute` -> `{"hops":n,"nominalTicks":n}`; one tick is shown as 50 ms.
- `listRadioDevices` -> array of `{"address":"XXXX:XXXX","alias":string|null,"online":bool}`.
  The tools call it in exactly one place (`ochat_link_devices` in
  `OnyxApps/lib/ochat/link/link.c`) and tolerate its absence: `recv`, `shell` and
  `status` continue without aliases; `who` and alias lookup report the error.
- `pingRadio(address, requestId)` and `sendRadioMessage(...)` return nothing
  (`null`); failures arrive as RPC errors. `pollRadioEvents` is destructive and
  shared by every user of the same tower session.

## Build and test

```sh
make -C tests/native test        # host tests: includes test_ochat and test_ochat_gui
make ochat ochat-gui ONYXCC=../OnyxCompiller/onyxcc
```

The pure modules are in `OnyxApps/lib/ochat` (addresses, framing, history ring,
ping statistics, JSON/wire parsing, line editor, wrapping). Host tests cover them
and the GUI model with a fake radio. The transport (`lib/ochat/link`) and the
framebuffer loop need a live OnyxOS guest with the OC2R mod.
