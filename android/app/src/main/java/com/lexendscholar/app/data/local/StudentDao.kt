package com.lexendscholar.app.data.local

import androidx.room.*
import com.lexendscholar.app.data.model.Student
import kotlinx.coroutines.flow.Flow

@Dao
interface StudentDao {
    @Query("SELECT * FROM students ORDER BY name ASC")
    fun observeAll(): Flow<List<Student>>

    @Query("SELECT * FROM students WHERE is_synced = 0")
    suspend fun getUnsynced(): List<Student>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(student: Student)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(students: List<Student>)

    @Update
    suspend fun update(student: Student)

    @Delete
    suspend fun delete(student: Student)

    @Query("UPDATE students SET is_synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<String>)

    @Query("SELECT * FROM students WHERE id = :id")
    suspend fun getById(id: String): Student?
}
