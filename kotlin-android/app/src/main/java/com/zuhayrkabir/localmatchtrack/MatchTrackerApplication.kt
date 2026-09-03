package com.zuhayrkabir.localmatchtrack

import android.app.Application
import com.zuhayrkabir.localmatchtrack.ditto.DittoMatchService

class MatchTrackerApplication : Application() {
    val dittoService: DittoMatchService by lazy {
        DittoMatchService(applicationContext)
    }
}
