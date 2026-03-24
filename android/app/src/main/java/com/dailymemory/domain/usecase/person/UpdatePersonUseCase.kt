package com.dailymemory.domain.usecase.person

import com.dailymemory.domain.model.Person
import com.dailymemory.domain.repository.PersonRepository
import javax.inject.Inject

/**
 * Use case for updating an existing person.
 */
class UpdatePersonUseCase @Inject constructor(
    private val personRepository: PersonRepository
) {
    suspend operator fun invoke(person: Person): Result<Person> {
        return try {
            personRepository.update(person)
            Result.success(person)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
