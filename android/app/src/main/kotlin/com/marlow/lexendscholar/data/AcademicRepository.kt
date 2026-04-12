package com.marlow.lexendscholar.data

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.serialization.Serializable

@Serializable
data class Student(
    val id: String,
    val name: String,
    val enrollment: String,
    val classId: String,
    val schoolId: String
)

@Serializable
data class AttendanceRecord(
    val id: String,
    val studentId: String,
    val date: String,
    val present: Boolean,
    val classId: String
)

@Serializable
data class Grade(
    val id: String,
    val studentId: String,
    val subject: String,
    val value: Double,
    val period: String
)

class AcademicRepository(private val supabase: SupabaseClient) {

    suspend fun getStudentsByClass(classId: String): List<Student> =
        supabase.from("students").select {
            filter { eq("class_id", classId) }
        }.decodeList()

    suspend fun recordAttendance(records: List<AttendanceRecord>) {
        supabase.from("attendance").upsert(records)
    }

    suspend fun getGrades(studentId: String, period: String): List<Grade> =
        supabase.from("grades").select {
            filter {
                eq("student_id", studentId)
                eq("period", period)
            }
        }.decodeList()

    suspend fun saveGrade(grade: Grade) {
        supabase.from("grades").upsert(grade)
    }
}
