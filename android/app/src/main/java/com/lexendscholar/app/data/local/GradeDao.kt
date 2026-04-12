package com.lexendscholar.app.data.local

import androidx.room.*
import com.lexendscholar.app.data.model.Grade
import kotlinx.coroutines.flow.Flow

@Dao
interface GradeDao {
    @Query("SELECT * FROM grades WHERE student_id = :studentId ORDER BY date DESC")
    fun observeByStudent(studentId: String): Flow<List<Grade>>

    @Query("SELECT * FROM grades WHERE is_synced = 0")
    suspend fun getUnsynced(): List<Grade>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(grade: Grade)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(grades: List<Grade>)

    @Query("UPDATE grades SET is_synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<String>)
}
