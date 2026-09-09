package com.eventapp.event_app

import com.ryanheise.audioservice.AudioServiceActivity

// Muzika treba da svira i kad aplikacija nije na ekranu, sa kontrolama u
// notifikaciji. Zato aktivnost mora da bude AudioServiceActivity umesto
// obične FlutterActivity — inače servis ne može da je pokrene nazad.
class MainActivity : AudioServiceActivity()
