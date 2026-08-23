# ChordVoicingGeneratorJazz

This Musescore 4 plugin generates a jazz piano chord voicing, based on the chord symbol in the staff.

This plugin is currently in progress but the goal is to generate Drop 2, 3 note(for solo accompaniment), Left hand(for trio accompaniment) and two hand(for ensemble accompaniment) voicings.

Currently generates simple voicings and can implement a charlston rhythm:
<img width="820" height="561" alt="image" src="https://github.com/user-attachments/assets/9b270f3e-2ae6-44fa-b515-5939eebf4761" />

The following chord symbol features are supported in the current version:
Feature | Example
------- | -------
*letter*[b ♭ # ♯] | A, Bb, C#
Major, major, Maj, maj, Ma, ma, M, j | Cma, DM7
minor, min, mi, m, -, − | Dmi, D-9
dim, o, ° | Ebdim, E°7
ø, O, 0 | Abø7
aug, + | Db+
t, ∆, ^ | C∆7
69, | G69
*number* | C7, E13
(Major, major, Maj, maj, Ma, ma, M, j *number*) | Cmi(ma7)
alt | Dalt
sus[*number*] | Asus, Dsus2
b*number* ... | C7b5b9
#*number* ... | Eb7#9#11
/ *letter*[b #] | D7/A

The Chord recognition logic is credited to the Walking Bass plugin by philxan
