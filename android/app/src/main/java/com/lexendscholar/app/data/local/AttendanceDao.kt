package com.lexendscholar.app.data.local

import androidx.room.*
import com.lexendscholar.app.data.model.AttendanceRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface AttendanceDao {
    @Query("SELECT * FROM attendance_records WHERE class_id = :classId AND date = :date")
    fun observeByClassAndDate(classId: String, date: String): Flow<List<AttendanceRecord>>

    @Query("SELECT * FROM attendance_records WHERE is_synced = 0")
    suspend fun getUnsynced(): List<AttendanceRecord>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(record: AttendanceRecord)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(records: List<AttendanceRecord>)

    @Query("UPDATE attendance_records SET is_synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<String>)
}
