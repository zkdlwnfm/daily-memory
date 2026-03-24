package com.dailymemory

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class DailyMemoryApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Initialize any app-wide configurations here
    }
}
