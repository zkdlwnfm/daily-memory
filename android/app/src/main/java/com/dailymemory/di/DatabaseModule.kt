package com.dailymemory.di

import android.content.Context
import androidx.room.Room
import com.dailymemory.data.local.DailyMemoryDatabase
import com.dailymemory.data.local.dao.MemoryDao
import com.dailymemory.data.local.dao.PersonDao
import com.dailymemory.data.local.dao.ReminderDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(
        @ApplicationContext context: Context
    ): DailyMemoryDatabase {
        return Room.databaseBuilder(
            context,
            DailyMemoryDatabase::class.java,
            DailyMemoryDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    @Singleton
    fun provideMemoryDao(database: DailyMemoryDatabase): MemoryDao {
        return database.memoryDao()
    }

    @Provides
    @Singleton
    fun providePersonDao(database: DailyMemoryDatabase): PersonDao {
        return database.personDao()
    }

    @Provides
    @Singleton
    fun provideReminderDao(database: DailyMemoryDatabase): ReminderDao {
        return database.reminderDao()
    }
}
