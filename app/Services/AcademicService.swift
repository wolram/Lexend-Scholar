// LS-47: Migrar DemoData para fetch real via Supabase
import SwiftUI

// MARK: - Remote Data Transfer Objects

struct StudentDTO: Codable, Identifiable {
    let id: String
    let name: String
    let grade: String
    let studentNumber: String
    let department: String
    let status: String
    let bio: String
    let email: String
    let phone: String
    let address: String
    let gpa: Double
    let attendance: Int
    let rankLabel: String
    let credits: Double
    let advisor: String

    enum CodingKeys: String, CodingKey {
        case id, name, grade, department, status, bio, email, phone, address, gpa, attendance, credits, advisor
        case studentNumber = "student_number"
        case rankLabel = "rank_label"
    }

    func toStudent() -> Student {
        Student(
            id: id,
            name: name,
            grade: grade,
            studentNumber: studentNumber,
            department: department,
            status: status,
            accent: accentForDepartment(department),
            bio: bio,
            email: email,
            phone: phone,
            address: address,
            gpa: gpa,
            attendance: attendance,
            rank: rankLabel,
            credits: credits,
            advisor: advisor,
            performance: [],
            courseHistory: [],
            guardians: [],
            notes: [],
            attendanceMarks: []
        )
    }

    private func accentForDepartment(_ dep: String) -> Color {
        switch dep.lowercased() {
        case "stem", "tecnologia": return SchoolPalette.primary
        case "ciências", "sciences": return SchoolPalette.violet
        case "humanidades", "humanities": return SchoolPalette.warning
        default: return SchoolPalette.success
        }
    }
}

struct TeacherDTO: Codable, Identifiable {
    let id: String
    let name: String
    let title: String
    let department: String
    let email: String
    let office: String
    let advisees: Int
    let activeCourses: Int
    let weeklyLoad: Int
    let summary: String

    enum CodingKeys: String, CodingKey {
        case id, name, title, department, email, office, advisees, summary
        case activeCourses = "active_courses"
        case weeklyLoad = "weekly_load"
    }

    func toTeacher() -> Teacher {
        Teacher(
            id: id,
            name: name,
            title: title,
            department: department,
            email: email,
            office: office,
            expertise: [],
            advisees: advisees,
            activeCourses: activeCourses,
            weeklyLoad: weeklyLoad,
            accent: accentForDepartment(department),
            summary: summary,
            availability: []
        )
    }

    private func accentForDepartment(_ dep: String) -> Color {
        switch dep.lowercased() {
        case "matemática", "mathematics": return SchoolPalette.primary
        case "ciências", "sciences": return SchoolPalette.violet
        case "humanidades", "humanities": return SchoolPalette.success
        default: return SchoolPalette.warning
        }
    }
}

// MARK: - AcademicService

@MainActor
final class AcademicService: ObservableObject {
    static let shared = AcademicService()

    @Published private(set) var students: [Student] = DemoData.students
    @Published private(set) var teachers: [Teacher] = DemoData.teachers
    @Published private(set) var isLoadingStudents = false
    @Published private(set) var isLoadingTeachers = false
    @Published private(set) var studentsError: String?
    @Published private(set) var teachersError: String?

    private let supabase = SupabaseService.shared
    private let syncService = SyncService.shared

    private init() {}

    // MARK: - Students

    func fetchStudents() async {
        isLoadingStudents = true
        studentsError = nil
        do {
            // Try remote first
            let dtos: [StudentDTO] = try await supabase.fetch(from: "students")
            let fetched = dtos.map { $0.toStudent() }
            students = fetched.isEmpty ? DemoData.students : fetched
            // Cache locally via SwiftData
            await syncService.cacheStudents(dtos)
        } catch {
            // Fallback to local cache
            let cached = await syncService.loadCachedStudents()
            if cached.isEmpty {
                studentsError = "Sem conexão e sem cache local. Exibindo dados de demonstração."
                students = DemoData.students
            } else {
                students = cached.map { $0.toStudent() }
            }
        }
        isLoadingStudents = false
    }

    func createStudent(_ dto: StudentDTO) async throws {
        _ = try await supabase.insert(into: "students", value: dto)
        await syncService.cacheStudents([dto])
        await fetchStudents()
    }

    func updateStudent(_ dto: StudentDTO) async throws {
        _ = try await supabase.update(table: "students", id: dto.id, value: dto)
        await fetchStudents()
    }

    func deleteStudent(id: String) async throws {
        try await supabase.delete(from: "students", id: id)
        await syncService.removeStudent(id: id)
        students.removeAll { $0.id == id }
    }

    // MARK: - Teachers

    func fetchTeachers() async {
        isLoadingTeachers = true
        teachersError = nil
        do {
            let dtos: [TeacherDTO] = try await supabase.fetch(from: "teachers")
            let fetched = dtos.map { $0.toTeacher() }
            teachers = fetched.isEmpty ? DemoData.teachers : fetched
            await syncService.cacheTeachers(dtos)
        } catch {
            let cached = await syncService.loadCachedTeachers()
            if cached.isEmpty {
                teachersError = "Sem conexão e sem cache local. Exibindo dados de demonstração."
                teachers = DemoData.teachers
            } else {
                teachers = cached.map { $0.toTeacher() }
            }
        }
        isLoadingTeachers = false
    }

    func createTeacher(_ dto: TeacherDTO) async throws {
        _ = try await supabase.insert(into: "teachers", value: dto)
        await syncService.cacheTeachers([dto])
        await fetchTeachers()
    }

    func updateTeacher(_ dto: TeacherDTO) async throws {
        _ = try await supabase.update(table: "teachers", id: dto.id, value: dto)
        await fetchTeachers()
    }

    func deleteTeacher(id: String) async throws {
        try await supabase.delete(from: "teachers", id: id)
        await syncService.removeTeacher(id: id)
        teachers.removeAll { $0.id == id }
    }
}
