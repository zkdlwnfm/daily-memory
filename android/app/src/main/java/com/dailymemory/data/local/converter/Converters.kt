package com.dailymemory.data.local.converter

import androidx.room.TypeConverter
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Photo
import com.dailymemory.domain.model.Relationship
import com.dailymemory.domain.model.RepeatType
import com.dailymemory.domain.model.SyncStatus
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class Converters {

    private val dateTimeFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME

    // LocalDateTime
    @TypeConverter
    fun fromLocalDateTime(value: LocalDateTime?): String? {
        return value?.format(dateTimeFormatter)
    }

    @TypeConverter
    fun toLocalDateTime(value: String?): LocalDateTime? {
        return value?.let { LocalDateTime.parse(it, dateTimeFormatter) }
    }

    // List<String>
    @TypeConverter
    fun fromStringList(value: List<String>): String {
        return JSONArray(value).toString()
    }

    @TypeConverter
    fun toStringList(value: String): List<String> {
        val jsonArray = JSONArray(value)
        return (0 until jsonArray.length()).map { jsonArray.getString(it) }
    }

    // Category
    @TypeConverter
    fun fromCategory(value: Category): String {
        return value.name
    }

    @TypeConverter
    fun toCategory(value: String): Category {
        return Category.fromString(value)
    }

    // Relationship
    @TypeConverter
    fun fromRelationship(value: Relationship): String {
        return value.name
    }

    @TypeConverter
    fun toRelationship(value: String): Relationship {
        return Relationship.fromString(value)
    }

    // RepeatType
    @TypeConverter
    fun fromRepeatType(value: RepeatType): String {
        return value.name
    }

    @TypeConverter
    fun toRepeatType(value: String): RepeatType {
        return RepeatType.fromString(value)
    }

    // SyncStatus
    @TypeConverter
    fun fromSyncStatus(value: SyncStatus): String {
        return value.name
    }

    @TypeConverter
    fun toSyncStatus(value: String): SyncStatus {
        return try {
            SyncStatus.valueOf(value)
        } catch (e: IllegalArgumentException) {
            SyncStatus.PENDING
        }
    }

    companion object {
        private val dateTimeFormatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME

        // Photo list JSON conversion
        fun photosToJson(photos: List<Photo>): String {
            val jsonArray = JSONArray()
            photos.forEach { photo ->
                val jsonObject = JSONObject().apply {
                    put("id", photo.id)
                    put("url", photo.url)
                    put("thumbnailUrl", photo.thumbnailUrl)
                    put("aiAnalysis", photo.aiAnalysis)
                    put("createdAt", photo.createdAt.format(dateTimeFormatter))
                }
                jsonArray.put(jsonObject)
            }
            return jsonArray.toString()
        }

        fun jsonToPhotos(json: String): List<Photo> {
            if (json.isEmpty() || json == "[]") return emptyList()
            val jsonArray = JSONArray(json)
            return (0 until jsonArray.length()).map { i ->
                val obj = jsonArray.getJSONObject(i)
                Photo(
                    id = obj.getString("id"),
                    url = obj.getString("url"),
                    thumbnailUrl = obj.optString("thumbnailUrl", null),
                    aiAnalysis = obj.optString("aiAnalysis", null),
                    createdAt = LocalDateTime.parse(obj.getString("createdAt"), dateTimeFormatter)
                )
            }
        }

        // Float list JSON conversion (for embeddings)
        fun floatListToJson(list: List<Float>): String {
            return JSONArray(list).toString()
        }

        fun jsonToFloatList(json: String): List<Float> {
            if (json.isEmpty() || json == "[]") return emptyList()
            val jsonArray = JSONArray(json)
            return (0 until jsonArray.length()).map { jsonArray.getDouble(it).toFloat() }
        }
    }
}
