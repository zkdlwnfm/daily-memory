package com.dailymemory.domain.usecase.person

import com.dailymemory.domain.model.Person
import com.dailymemory.domain.repository.PersonRepository
import javax.inject.Inject

/**
 * Use case for saving a new person.
 */
class SavePersonUseCase @Inject constructor(
    private val personRepository: PersonRepository
) {
    suspend operator fun invoke(person: Person): Result<Person> {
        return try {
            personRepository.insert(person)
            Result.success(person)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
