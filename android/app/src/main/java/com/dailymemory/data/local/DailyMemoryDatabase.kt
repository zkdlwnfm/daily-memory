package com.dailymemory.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.dailymemory.data.local.converter.Converters
import com.dailymemory.data.local.dao.MemoryDao
import com.dailymemory.data.local.dao.PersonDao
import com.dailymemory.data.local.dao.ReminderDao
import com.dailymemory.data.local.entity.MemoryEntity
import com.dailymemory.data.local.entity.PersonEntity
import com.dailymemory.data.local.entity.ReminderEntity

@Database(
    entities = [
        MemoryEntity::class,
        PersonEntity::class,
        ReminderEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class DailyMemoryDatabase : RoomDatabase() {

    abstract fun memoryDao(): MemoryDao
    abstract fun personDao(): PersonDao
    abstract fun reminderDao(): ReminderDao

    companion object {
        const val DATABASE_NAME = "dailymemory.db"
    }
}
