package com.lexendscholar.app.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@Entity(tableName = "students")
data class Student(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    @SerialName("student_number") val studentNumber: String,
    val grade: String,
    val department: String,
    val status: String,
    val gpa: Double,
    @SerialName("attendance_rate") val attendanceRate: Int,
    @SerialName("school_id") val schoolId: String,
    @SerialName("is_synced") val isSynced: Boolean = false
)

@Serializable
@Entity(tableName = "attendance_records")
data class AttendanceRecord(
    @PrimaryKey val id: String,
    @SerialName("student_id") val studentId: String,
    @SerialName("class_id") val classId: String,
    val date: String,
    val status: String, // present, absent, late
    val notes: String?,
    @SerialName("teacher_id") val teacherId: String,
    @SerialName("is_synced") val isSynced: Boolean = false
)

@Serializable
@Entity(tableName = "grades")
data class Grade(
    @PrimaryKey val id: String,
    @SerialName("student_id") val studentId: String,
    @SerialName("course_id") val courseId: String,
    val value: Double,
    val type: String, // exam, assignment, project
    val description: String?,
    val date: String,
    @SerialName("teacher_id") val teacherId: String,
    @SerialName("is_synced") val isSynced: Boolean = false
)

@Serializable
@Entity(tableName = "classes")
data class SchoolClass(
    @PrimaryKey val id: String,
    val name: String,
    val grade: String,
    val subject: String,
    @SerialName("teacher_id") val teacherId: String,
    val room: String,
    val enrolled: Int,
    val capacity: Int
)
