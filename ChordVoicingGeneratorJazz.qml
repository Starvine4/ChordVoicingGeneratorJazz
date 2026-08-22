import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import MuseScore 3.0

MuseScore {
    version: "4.0"
    description: "Jazz Chord Voicing Generator 0.2"
    menuPath: "Plugins.ChordVoicingGeneratorJazz"
    pluginType: "dialog"
    width: 400
    height: 500

    Component.onCompleted: {
        if (mscoreMajorVersion >= 4) {
            title = "Jazz Chord Voicing Generator"
            thumbnailName = "WalkingBassIcon.png"
            categoryCode = "PitDad Tools"
        }
    }

    property var letterToSemitone: {
        'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11
    }

    property var intervalToSemitone: {
        '1': 0, '2': 2, '3': 4, '4': 5, '5': 7, '6': 9, '7': 11
    }

    property int lowestPitch: 28

    QtObject {
        id: triadType
        property int major: 0
        property int minor: 1
        property int diminished: 2
        property int augmented: 3
        property int dominant: 4
        property int halfDiminished: 5
    }

    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: "Jazz Chord Voicing Generator"
                color: "white"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Button {
                text: "Read Selected Chords"
                Layout.fillWidth: true
                onClicked: {
                    readChords()
                }
            }

            Button {
                text: "Generate Voicings"
                Layout.fillWidth: true
                onClicked: {
                    generateVoicings()
                }
            }

            Text {
                id: outputText
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                text: "Select chord symbols and click button"
                verticalAlignment: Text.AlignTop
            }

            Label {
                id: statusLabel
                text: "Ready"
                color: "#88dd88"
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    function isNumber(ch) {
        return "123456789".includes(ch)
    }

    function parseChord(chord) {
        var idx = 0
        if ("()".includes(chord[idx])) idx++

        var root = chord[idx].toUpperCase()
        idx++
        if (idx < chord.length && '#b'.includes(chord[idx])) {
            root += chord[idx]
            idx++
        }

        var triad = -1
        var triadWord = ""
        while ((idx < chord.length) && !isNumber(chord[idx]) && chord[idx] !== "/") {
            triadWord = triadWord + chord[idx++]
        }

        switch (triadWord) {
            case "":
                if (idx === chord.length) {
                    triad = triadType.major
                } else if (chord[idx] === "6") {
                    triad = triadType.major
                    idx++
                } else {
                    triad = triadType.dominant
                }
                break
            case "^":
            case "∆":
            case "Major":
            case "major":
            case "Maj":
            case "maj":
            case "Ma":
            case "ma":
            case "M":
            case "j": triad = triadType.major; break
            case "minor":
            case "min":
            case "mi":
            case "m":
            case "-": triad = triadType.minor; break
            case "o":
            case "O":
            case "dim":
            case "°": triad = triadType.diminished; break
            case "0":
            case "ø": triad = triadType.halfDiminished; break
            case "+":
            case "aug": triad = triadType.augmented; break
            default: triad = triadType.dominant; break
        }

        var extensionWord = ""
        var extensions = []
        while ((idx < chord.length) && (chord[idx] !== "/")) {
            extensionWord = extensionWord + chord[idx++]
        }

        var ex = ""
        if (extensionWord.includes("alt")) {
            extensionWord = "7#5#9"
            triad = triadType.dominant
        }

        for (var c in extensionWord) {
            if ("()".includes(extensionWord[c])) continue
            if ("#b".includes(extensionWord[c])) {
                extensions.push(ex)
                ex = extensionWord[c]
                continue
            }
            ex = ex + extensionWord[c]
        }
        extensions.push(ex)

        var bass = ""
        if (idx < chord.length && chord[idx] === "/") {
            idx++
            while (idx < chord.length) {
                bass = bass + chord[idx++]
            }
        }

        return {root: root, triad: triad, extensions: extensions, bass: bass}
    }

    function getLetterPitch(letter) {
        var pitch = letterToSemitone[letter[0]]
        if (letter.length > 1) {
            pitch += (letter[1] === "b") ? -1 : 1
        }
        while (pitch < lowestPitch) {
            pitch += 12
        }
        return pitch
    }

    function getIntervalPitch(rootPitch, interval) {
        return rootPitch + intervalToSemitone[interval]
    }

    function getTriadName(triad) {
        switch (triad) {
            case triadType.major: return "Major"
            case triadType.minor: return "Minor"
            case triadType.diminished: return "Diminished"
            case triadType.augmented: return "Augmented"
            case triadType.dominant: return "Dominant"
            case triadType.halfDiminished: return "Half-Diminished"
            default: return "Unknown"
        }
    }

    function midiToNoteName(midi) {
        var noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
        var octave = Math.floor(midi / 12) - 1
        var noteIndex = midi % 12
        return noteNames[noteIndex] + octave
    }

    function getCursor() {
        var cursor = curScore.newCursor()
        cursor.staffIdx = 0
        cursor.voice = 0
        cursor.rewind(Cursor.SELECTION_START)
        return cursor
    }

    function getEndTick(cursor) {
        cursor.rewind(Cursor.SELECTION_END)
        var endTick
        if (cursor.tick === 0) {
            endTick = curScore.lastSegment.tick
        } else {
            endTick = cursor.tick
        }
        cursor.rewind(Cursor.SELECTION_START)
        return endTick
    }

    function findAllChordSymbols(segment, staff, endTick) {
        var chords = {}

        while (segment && (segment.tick < endTick)) {
            var annotations = segment.annotations
            for (var a in annotations) {
                var annotation = annotations[a]
                if ((annotation.name === "Harmony") && (annotation.track / 4 === staff)) {
                    chords[segment.tick] = {tick: segment.tick, text: annotation.text}
                }
            }
            segment = segment.next
        }

        var result = []
        for (var i in chords) {
            var chord = chords[i]
            if (result.length > 0) {
                result[result.length - 1].duration = chord.tick - result[result.length - 1].tick
            }
            result.push(chord)
        }

        if (result.length > 0) {
            var lastItem = result[result.length - 1]
            lastItem.duration = endTick - lastItem.tick
        }

        return result
    }

    function readChords() {
        var output = ""

        try {
            var cursor = getCursor()

            if (!cursor.segment) {
                statusLabel.text = "Error: Nothing selected"
                outputText.text = "Please select a region with chord symbols."
                return
            }

            var endTick = getEndTick(cursor)
            var selectedStaff = curScore.selection.startStaff
            var segment = curScore.selection.startSegment
            var chordSymbols = findAllChordSymbols(segment, selectedStaff, endTick)

            if (chordSymbols.length === 0) {
                statusLabel.text = "No chords found"
                outputText.text = "No chord symbols in selection."
                return
            }

            output = "Found " + chordSymbols.length + " chord(s):\n\n"

            for (var i = 0; i < chordSymbols.length; i++) {
                var chordSymbol = chordSymbols[i]
                var chord = parseChord(chordSymbol.text)
                var rootPitch = getLetterPitch(chord.root)

                output += (i + 1) + ". " + chordSymbol.text + "\n"
                output += "   Root: " + chord.root + " (MIDI " + rootPitch + ")\n"
                output += "   Type: " + getTriadName(chord.triad) + "\n\n"
            }

            outputText.text = output
            statusLabel.text = "Analyzed " + chordSymbols.length + " chord(s)"

        } catch (e) {
            statusLabel.text = "Error: " + e
            outputText.text = "Error: " + e
        }
    }

    function generateVoicings() {
        var output = ""

        try {
            var cursor = getCursor()

            if (!cursor.segment) {
                statusLabel.text = "Error: Nothing selected"
                outputText.text = "Please select a region with chord symbols."
                return
            }

            var endTick = getEndTick(cursor)
            var selectedStaff = curScore.selection.startStaff
            var segment = curScore.selection.startSegment
            var chordSymbols = findAllChordSymbols(segment, selectedStaff, endTick)

            if (chordSymbols.length === 0) {
                statusLabel.text = "No chords found"
                outputText.text = "No chord symbols in selection."
                return
            }

            output = "Generating voicings for " + chordSymbols.length + " chord(s):\n\n"

            curScore.startCmd()

            for (var i = 0; i < chordSymbols.length; i++) {
                var chordSymbol = chordSymbols[i]
                var chord = parseChord(chordSymbol.text)
                var rootPitch = getLetterPitch(chord.root)

                output += (i + 1) + ". " + chordSymbol.text + "\n"

                // Calculate all pitches: root, 3rd, 5th, 7th
                var intervals = ["1", "3", "5", "7"]
                var pitches = []
                var noteNames = []
                for (var j = 0; j < intervals.length; j++) {
                    var interval = intervals[j]
                    var notePitch = getIntervalPitch(rootPitch, interval)
                    // Transpose to good octave range
                    while (notePitch > 72) notePitch -= 12
                    while (notePitch < 55) notePitch += 12
                    pitches.push(notePitch)
                    noteNames.push(midiToNoteName(notePitch))
                }

                // Left hand: root (pitches[0]) and 5th (pitches[2])
                var leftCursor = curScore.newCursor()
                leftCursor.staffIdx = selectedStaff + 1
                leftCursor.voice = 0
                leftCursor.rewindToTick(chordSymbol.tick)
                leftCursor.setDuration(1, 4)
                leftCursor.addNote(pitches[0], false)
                leftCursor.addNote(pitches[2], true)

                // Right hand: 3rd (pitches[1]) and 7th (pitches[3])
                var rightCursor = curScore.newCursor()
                rightCursor.staffIdx = selectedStaff
                rightCursor.voice = 0
                rightCursor.rewindToTick(chordSymbol.tick)
                rightCursor.setDuration(1, 4)
                rightCursor.addNote(pitches[1], false)
                rightCursor.addNote(pitches[3], true)

                output += "   RH (guide tones): " + noteNames[1] + ", " + noteNames[3] + "\n"
                output += "   LH (root & 5th): " + noteNames[0] + ", " + noteNames[2] + "\n"
            }

            curScore.endCmd()
            outputText.text = output
            statusLabel.text = "Generated voicings for " + chordSymbols.length + " chord(s)"

        } catch (e) {
            statusLabel.text = "Error: " + e
            outputText.text = "Error: " + e
        }
    }
}