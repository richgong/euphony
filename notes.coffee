# rain
    @rain.setMidiData(@player.data, callback)

# load midi
    MIDI.loadPlugin ->
      # mute channel 10, which is reserved for percussion instruments only.
      # the channel index is off by one
      MIDI.channels[9].mute = true
      callback?()


# animation, listening to player
    @player = MIDI.Player
    @player.addListener (data) =>
      NOTE_OFF = 128
      NOTE_ON  = 144
      {note, message} = data
      if message is NOTE_ON
        @keyboard.press(note)
        @particles.createParticles(note)
      else if message is NOTE_OFF
        @keyboard.release(note)
    @player.setAnimation
      delay: 20
      callback: (data) =>
        {now, end} = data
        @onprogress?(
          current: now
          total: end
        )
        @rain.update(now * 1000)

    start: =>
        @player.start()

    resume: =>
        @player.currentTime += 1e-6 # bugfix for MIDI.js
        @player.resume()

    stop: =>
        @player.stop()

    pause: =>
        @player.pause()

# document dragger

    $(document).on 'drop', (event) ->
    event or= window.event
    event.preventDefault()
    event.stopPropagation()

    # jquery wraps the original event
    event = event.originalEvent or event

    files = event.files or event.dataTransfer.files
    file = files[0]

    reader = new FileReader()
    reader.onload = (e) ->
    midiFile = e.target.result
    player.stop()
    loader.message 'Loading MIDI', ->
        app.loadMidiFile midiFile, ->
        loader.stop ->
            player.play()
    reader.readAsDataURL(file)


# generate note rain
    # the raw midiData uses delta time between events to represent the flow
    # and it's quite unintuitive
    # here we calculates the start and end time of each notebox
    _getNoteInfos: (midiData) ->
        currentTime = 0
        noteInfos = []
        noteTimes = []

        for [{event}, interval] in midiData
            currentTime += interval
            {subtype, noteNumber, channel} = event

            # In General MIDI, channel 10 is reserved for percussion instruments only.
            # It doesn't make any sense to convert it into piano notes. So just skip it.
            continue if channel is 9 # off by 1

            if subtype is 'noteOn'
            # if note is on, record its start time
            noteTimes[noteNumber] = currentTime

            else if subtype is 'noteOff'
            # if note if off, calculate its duration and build the model
            startTime = noteTimes[noteNumber]
            duration = currentTime - startTime
            noteInfos.push {
                noteNumber: noteNumber
                startTime: startTime
                duration: duration
            }
        noteInfos


# render note rain
    {noteNumber, startTime, duration} = noteInfo

    # scale the length of the note
    length = duration * @lengthScale

    # calculate the note's position
    x = keyInfo[noteNumber].keyCenterPosX
    y = startTime * @lengthScale + (length / 2)
