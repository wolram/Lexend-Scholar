package com.lexendscholar.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lexendscholar.app.data.model.AttendanceRecord
import com.lexendscholar.app.data.model.Grade
import com.lexendscholar.app.data.model.Student
import com.lexendscholar.app.data.repository.AcademicRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AcademicViewModel @Inject constructor(
    private val repository: AcademicRepository
) : ViewModel() {

    val students: StateFlow<List<Student>> = repository.observeStudents()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedStudent = MutableStateFlow<Student?>(null)
    val selectedStudent: StateFlow<Student?> = _selectedStudent.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        fetchStudents()
    }

    private fun fetchStudents() {
        viewModelScope.launch {
            _isLoading.value = true
            repository.fetchStudentsFromRemote().onFailure {
                _error.value = it.message
            }
            _isLoading.value = false
        }
    }

    fun selectStudent(student: Student) {
        _selectedStudent.value = student
    }

    fun clearSelection() {
        _selectedStudent.value = null
    }

    fun saveAttendanceRecord(studentId: String, classId: String, status: String, teacherId: String) {
        viewModelScope.launch {
            val record = AttendanceRecord(
                id = UUID.randomUUID().toString(),
                studentId = studentId,
                classId = classId,
                date = java.time.LocalDate.now().toString(),
                status = status,
                notes = null,
                teacherId = teacherId
            )
            repository.saveAttendance(listOf(record))
        }
    }

    fun saveGrade(studentId: String, courseId: String, value: Double, type: String, teacherId: String) {
        viewModelScope.launch {
            val grade = Grade(
                id = UUID.randomUUID().toString(),
                studentId = studentId,
                courseId = courseId,
                value = value,
                type = type,
                description = null,
                date = java.time.LocalDate.now().toString(),
                teacherId = teacherId
            )
            repository.saveGrade(grade)
        }
    }
}
