package com.lexendscholar.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.lexendscholar.app.data.model.AttendanceRecord
import com.lexendscholar.app.data.model.Grade
import com.lexendscholar.app.data.model.SchoolClass
import com.lexendscholar.app.data.model.Student

@Database(
    entities = [Student::class, AttendanceRecord::class, Grade::class, SchoolClass::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun studentDao(): StudentDao
    abstract fun attendanceDao(): AttendanceDao
    abstract fun gradeDao(): GradeDao
}
