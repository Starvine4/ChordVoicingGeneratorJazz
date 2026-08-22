import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import MuseScore 3.0

MuseScore
{
    version: "4.0"
    description: "Jazz Chord Voicing Generator 0.2"
    menuPath: "Plugins.ChordVoicingGeneratorJazz"
    pluginType: "dialog"
    //dockArea: "left"
    width: 300
    height: 400

    Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            title = "Jazz chord voicing generator";
            thumbnailName = "WalkingBassIcon.png";
            categoryCode = "PitDad Tools";
        }
    }

    // --- UI ---
    Rectangle{
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
               text: "Read Selected Note"
               Layout.fillWidth: true
               onClicked: {
                   console.log("Button clicked!")
               }
           }

           Item {
               Layout.fillHeight: true
           }
       }
    }

    //=============================================================================
    // some faux enums as this seems to be best way to achieve this in qml

    QtObject
    {
        id: triadType

        property int major: 0
        property int minor: 1
        property int diminshed: 2
        property int augmented: 3
        property int dominant: 4
        property int halfDiminished: 5
    }

    //=============================================================================

    //=============================================================================

    // Helper function for determining extensions
    // returns true if the provided character is a number (1-9)
    // 0 is excluded, as that is used to indicate half diminished, and not used in extensions
    function isNumber(ch)
    {
      // and is NOT used any extensions..
      return "123456789".includes(ch);
    }

    //=============================================================================

    // parse a provided chord into its component parts
    // root: the root note of the chord
    // triad: the chord quality. One of the triadType values
    // extensions: a list of the extensions to the chord (e.g. #5, b9, etc)
    // bass: if its a slash chord, the bass note (after the slash)
    function parseChord(chord)
    {
        // letter
        var idx = 0;
        if ("()".includes(chord[idx])) idx++; // just ignore brackets!

        console.log(idx + " - " + chord + " - " + chord[idx])

        var root = chord[idx].toUpperCase();
        idx++;

        // could be #or b as well..
        if ('#b'.includes(chord[idx]))
        {
            root += chord[idx];
            idx++;
        }

        // triadType
        var triad = -1;
        var triadWord = "";
        while ( (idx < chord.length) && !isNumber(chord[idx]) && chord[idx] !== "/")
        {
            triadWord = triadWord + chord[idx++]
        }

        switch (triadWord)
        {
            case "":                                    // there is no triad type - just nothing, or straight to numbers
                if (idx === chord.length) {
                    triad =  triadType.major;               // just letter, so major
                }
                else if (chord[idx] === "6")
                {
                    triad =  triadType.major;               // 6, or 6/9 == major
                    idx++;
                } else
                    triad =  triadType.dominant;            // anything else is dominant = 7, 9, 13 etc.
                break;

            case "^":     triad = triadType.major;      break;
            case "∆":     triad = triadType.major;      break;
            case "Major": triad = triadType.major;      break;
            case "major": triad = triadType.major;      break;
            case "Maj":   triad = triadType.major;      break;
            case "maj":   triad = triadType.major;      break;
            case "Ma":    triad = triadType.major;      break;
            case "ma":    triad = triadType.major;      break;
            case "M":     triad = triadType.major;      break;
            case "j":     triad = triadType.major;      break;

            case "minor": triad = triadType.minor;      break;
            case "min":   triad = triadType.minor;      break;
            case "mi":    triad = triadType.minor;      break;
            case "m":     triad = triadType.minor;      break;
            case "-":     triad = triadType.minor;      break;
            case "-":     triad = triadType.minor;      break;

            case "o":     triad = triadType.diminished; break;
            case "O":     triad = triadType.diminished; break;
            case "dim":   triad = triadType.diminished; break;
            case "°":     triad = triadType.diminished; break;

            case "0":     triad = triadType.halfDiminished; break;
            case "ø":     triad = triadType.halfDiminished; break;

            case "+":     triad = triadType.augmented;  break;
            case "aug":   triad = triadType.augmented;  break;
        }

        // everything else is extensions.. until possibly a different bass note
        var extensionWord = "";
        var extensions = [];

        while ( (idx < chord.length) && (chord[idx] !== "/") )
        {
            if ("()".includes(extensionWord[c]))  continue; // just ignore it!
            extensionWord = extensionWord + chord[idx++]
        }

        var ex = "";
        if (extensionWord.includes("alt")) // its an altered chord, we'll use a 7#5#9
        {
            extensionWord = "7#5#9";
            triad = triadType.dominant;   // just to be sure!
        }

        for (var c in extensionWord)
        {
            if ("()".includes(extensionWord[c]))  continue; // just ignore it!
            if ("#b".includes(extensionWord[c]))         // if its a sharp or flat, that's the end of the current extension
            {
                extensions.push(ex);
                ex = extensionWord[c];
                continue;
            }
            ex = ex + extensionWord[c];
        }

        extensions.push(ex);

        // we have a slash chord! the rest of the chordSymbol will be the bass note
        var bassWord = "";

        if (chord[idx] === "/")
        {
          idx++;
          while ( idx < chord.length)
          {
            bassWord = bassWord + chord[idx++]
          }
        }

        var bass = bassWord;

        return {root: root, triad: triad, extensions: extensions, bass: bass}
    }

}
