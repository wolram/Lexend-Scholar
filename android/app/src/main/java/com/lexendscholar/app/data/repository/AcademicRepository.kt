package com.lexendscholar.app.data.repository

import com.lexendscholar.app.data.local.AppDatabase
import com.lexendscholar.app.data.model.AttendanceRecord
import com.lexendscholar.app.data.model.Grade
import com.lexendscholar.app.data.model.SchoolClass
import com.lexendscholar.app.data.model.Student
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AcademicRepository @Inject constructor(
    private val postgrest: Postgrest,
    private val database: AppDatabase
) {
    private val studentDao get() = database.studentDao()
    private val attendanceDao get() = database.attendanceDao()
    private val gradeDao get() = database.gradeDao()

    // Students
    fun observeStudents(): Flow<List<Student>> = studentDao.observeAll()

    suspend fun fetchStudentsFromRemote(): Result<List<Student>> {
        return try {
            val students = postgrest.from("students")
                .select(Columns.ALL)
                .decodeList<Student>()
            studentDao.insertAll(students)
            Result.success(students)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createStudent(student: Student): Result<Unit> {
        return try {
            postgrest.from("students").insert(student)
            studentDao.insert(student.copy(isSynced = true))
            Result.success(Unit)
        } catch (e: Exception) {
            // Save locally for later sync
            studentDao.insert(student.copy(isSynced = false))
            Result.failure(e)
        }
    }

    // Attendance
    fun observeAttendance(classId: String, date: String): Flow<List<AttendanceRecord>> =
        attendanceDao.observeByClassAndDate(classId, date)

    suspend fun saveAttendance(records: List<AttendanceRecord>): Result<Unit> {
        return try {
            postgrest.from("attendance_records").upsert(records)
            attendanceDao.insertAll(records.map { it.copy(isSynced = true) })
            Result.success(Unit)
        } catch (e: Exception) {
            attendanceDao.insertAll(records.map { it.copy(isSynced = false) })
            Result.failure(e)
        }
    }

    // Grades
    fun observeGrades(studentId: String): Flow<List<Grade>> =
        gradeDao.observeByStudent(studentId)

    suspend fun saveGrade(grade: Grade): Result<Unit> {
        return try {
            postgrest.from("grades").upsert(grade)
            gradeDao.insert(grade.copy(isSynced = true))
            Result.success(Unit)
        } catch (e: Exception) {
            gradeDao.insert(grade.copy(isSynced = false))
            Result.failure(e)
        }
    }

    suspend fun syncPendingData() {
        val unsyncedStudents = studentDao.getUnsynced()
        if (unsyncedStudents.isNotEmpty()) {
            try {
                postgrest.from("students").upsert(unsyncedStudents)
                studentDao.markSynced(unsyncedStudents.map { it.id })
            } catch (_: Exception) {}
        }

        val unsyncedAttendance = attendanceDao.getUnsynced()
        if (unsyncedAttendance.isNotEmpty()) {
            try {
                postgrest.from("attendance_records").upsert(unsyncedAttendance)
                attendanceDao.markSynced(unsyncedAttendance.map { it.id })
            } catch (_: Exception) {}
        }

        val unsyncedGrades = gradeDao.getUnsynced()
        if (unsyncedGrades.isNotEmpty()) {
            try {
                postgrest.from("grades").upsert(unsyncedGrades)
                gradeDao.markSynced(unsyncedGrades.map { it.id })
            } catch (_: Exception) {}
        }
    }
}
