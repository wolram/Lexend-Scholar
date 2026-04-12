package com.marlow.lexendscholar.data.local

import androidx.room.*

@Entity(tableName = "pending_attendance")
data class PendingAttendance(
    @PrimaryKey val id: String,
    val studentId: String,
    val classId: String,
    val date: String,
    val present: Boolean,
    val synced: Boolean = false
)

@Dao
interface AttendanceDao {
    @Query("SELECT * FROM pending_attendance WHERE synced = 0")
    suspend fun getPending(): List<PendingAttendance>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(record: PendingAttendance)

    @Query("UPDATE pending_attendance SET synced = 1 WHERE id = :id")
    suspend fun markSynced(id: String)
}

@Database(entities = [PendingAttendance::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun attendanceDao(): AttendanceDao
}
