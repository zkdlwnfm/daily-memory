package com.dailymemory.di

import com.dailymemory.data.repository.MemoryRepositoryImpl
import com.dailymemory.data.repository.PersonRepositoryImpl
import com.dailymemory.data.repository.ReminderRepositoryImpl
import com.dailymemory.domain.repository.MemoryRepository
import com.dailymemory.domain.repository.PersonRepository
import com.dailymemory.domain.repository.ReminderRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing repository implementations.
 * Binds repository interfaces to their implementations.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindMemoryRepository(
        memoryRepositoryImpl: MemoryRepositoryImpl
    ): MemoryRepository

    @Binds
    @Singleton
    abstract fun bindPersonRepository(
        personRepositoryImpl: PersonRepositoryImpl
    ): PersonRepository

    @Binds
    @Singleton
    abstract fun bindReminderRepository(
        reminderRepositoryImpl: ReminderRepositoryImpl
    ): ReminderRepository
}
