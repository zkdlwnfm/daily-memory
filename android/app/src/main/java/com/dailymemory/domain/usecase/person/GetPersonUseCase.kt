package com.dailymemory.domain.usecase.person

import com.dailymemory.domain.model.Person
import com.dailymemory.domain.repository.PersonRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for getting a single person by ID.
 */
class GetPersonUseCase @Inject constructor(
    private val personRepository: PersonRepository
) {
    suspend operator fun invoke(id: String): Person? {
        return personRepository.getById(id)
    }

    fun observe(id: String): Flow<Person?> {
        return personRepository.observeById(id)
    }
}
