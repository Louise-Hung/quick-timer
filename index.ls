start = null
is-blink = false
is-light = true
is-run = false
is-show = true
is-warned = false
handler = null
latency = 0
stop-by = null
delay = 60000
audio-remind = null
audio-end = null
wave-path = null
wave-level = 0
wave-raf = null

new-audio = (file) ->
  node = new Audio!
    ..src = file
    ..loop = false
    ..load!
  document.body.appendChild node
  return node

sound-toggle = (des, state) ->
  if state => des.play!
  else des
    ..currentTime = 0
    ..pause!

format-time = (ms) ->
  remain = Math.max 0, Math.floor ms
  hours = Math.floor(remain / 3600000)
  minutes = Math.floor(remain / 60000) % 60
  seconds = Math.floor(remain / 1000) % 60
  milliseconds = remain % 1000
  pad2 = (v) -> if v < 10 => "0#{v}" else "#{v}"
  pad3 = (v) ->
    if v < 10 => "00#{v}"
    else if v < 100 => "0#{v}"
    else "#{v}"
  "#{pad2 hours}:#{pad2 minutes}:#{pad2 seconds}.#{pad3 milliseconds}"

draw-wave = ->
  return unless wave-path
  width = window.innerWidth
  height = window.innerHeight
  base = Math.max 0, Math.min(height, height * wave-level)
  amplitude = Math.max 12, Math.min(height * 0.08, 80)
  wavelength = Math.max 120, width / 6
  offset = Date.now! / 600
  step = wavelength / 2
  start-x = -wavelength
  prev-x = start-x
  prev-y = base - Math.sin(prev-x / wavelength * Math.PI * 2 + offset) * amplitude
  path = "M0 #{height} L#{start-x} #{height} L#{prev-x} #{prev-y}"
  for x from start-x + step to width + wavelength by step
    wave-y = base - Math.sin(x / wavelength * Math.PI * 2 + offset) * amplitude
    ctrl-x = prev-x + step / 2
    path += " C#{ctrl-x} #{prev-y}, #{ctrl-x} #{wave-y}, #{x} #{wave-y}"
    prev-x = x
    prev-y = wave-y
  path += " L#{width + wavelength} #{height} L0 #{height} Z"
  wave-path.setAttribute \d, path
  wave-raf := requestAnimationFrame draw-wave

update-wave = (ms) ->
  return unless wave-path
  remain = if delay <= 0 => 0 else Math.max(0, Math.min(ms, delay)) / delay
  wave-level := 1 - remain
  unless wave-raf => wave-raf := requestAnimationFrame draw-wave

update-display = (ms) ->
  $ \#timer .text format-time ms
  update-wave ms
  resize!

show = ->
  is-show := !is-show
  $ \.fbtn .css \opacity, if is-show => \1.0 else \0.1

adjust = (it,v) ->
  if is-blink => return
  delay := delay + it * 1000
  if it==0 => delay := v * 1000
  if delay <= 0 => delay := 0
  current = if start? => start.getTime! - (new Date!)getTime! + delay + latency else delay
  update-display current

toggle = ->
  is-run := !is-run
  $ \#toggle .text if is-run => "STOP" else "RUN"
  if !is-run and handler => 
    stop-by := new Date!
    clearInterval handler
    handler := null
    sound-toggle audio-end, false
    sound-toggle audio-remind, false
  if stop-by =>
    latency := latency + (new Date!)getTime! - stop-by.getTime!
  if is-run => run!

reset = ->
  if delay == 0 => delay := 1000
  sound-toggle audio-remind, false
  sound-toggle audio-end, false
  stop-by := 0
  is-warned := false
  is-blink := false
  latency := 0
  start := null #new Date!
  is-run := true
  toggle!
  if handler => clearInterval handler
  handler := null
  $ \#timer .css \color, \#fff
  update-display delay


blink = ->
  is-blink := true
  is-light := !is-light
  $ \#timer .css \color, if is-light => \#fff else \#f00

count = ->
  diff = start.getTime! - (new Date!)getTime! + delay + latency
  if diff > 60000 => is-warned := false
  if diff < 60000 and !is-warned =>
    is-warned := true
    sound-toggle audio-remind, true
  if diff < 55000 => sound-toggle audio-remind, false
  if diff < 0 and !is-blink =>
    sound-toggle audio-end, true
    is-blink := true
    diff = 0
    clearInterval handler
    handler := setInterval ( -> blink!), 500
  update-display diff

run =  ->
  if start == null =>
    start := new Date!
    latency := 0
    is-blink := false
  if handler => clearInterval handler
  if is-blink => handler := setInterval (-> blink!), 500
  else handler := setInterval (-> count!), 100

resize = ->
  tm = $ \#timer
  w = tm.width!
  h = $ window .height!
  len = tm.text!length
  len>?=3
  tm.css \font-size, "#{1.2 * w/len}px"
  tm.css \line-height, "#{h}px"


window.onload = ->
  wave-path := document.getElementById \wave-path
  update-display delay
  #audio-remind := new-audio \audio/cop-car.mp3
  #audio-end := new-audio \audio/fire-alarm.mp3
  audio-remind := new-audio \audio/smb_warning.mp3
  audio-end := new-audio \audio/smb_mariodie.mp3
window.onresize = ->
  resize!
  if wave-raf => cancelAnimationFrame wave-raf
  wave-raf := requestAnimationFrame draw-wave
