// LS-49: Implementar persistência offline com SwiftData + sync
import Foundation
import SwiftData

// MARK: - Persistent Student

@Model
final class PersistentStudent {
    @Attribute(.unique) var id: String
    var name: String
    var grade: String
    var studentNumber: String
    var department: String
    var status: String
    var bio: String
    var email: String
    var phone: String
    var address: String
    var gpa: Double
    var attendance: Int
    var rankLabel: String
    var credits: Double
    var advisor: String
    var updatedAt: Date
    var needsSync: Bool

    init(from dto: StudentDTO) {
        self.id = dto.id
        self.name = dto.name
        self.grade = dto.grade
        self.studentNumber = dto.studentNumber
        self.department = dto.department
        self.status = dto.status
        self.bio = dto.bio
        self.email = dto.email
        self.phone = dto.phone
        self.address = dto.address
        self.gpa = dto.gpa
        self.attendance = dto.attendance
        self.rankLabel = dto.rankLabel
        self.credits = dto.credits
        self.advisor = dto.advisor
        self.updatedAt = Date()
        self.needsSync = false
    }

    func toDTO() -> StudentDTO {
        StudentDTO(
            id: id,
            name: name,
            grade: grade,
            studentNumber: studentNumber,
            department: department,
            status: status,
            bio: bio,
            email: email,
            phone: phone,
            address: address,
            gpa: gpa,
            attendance: attendance,
            rankLabel: rankLabel,
            credits: credits,
            advisor: advisor
        )
    }
}

// MARK: - Persistent Teacher

@Model
final class PersistentTeacher {
    @Attribute(.unique) var id: String
    var name: String
    var title: String
    var department: String
    var email: String
    var office: String
    var advisees: Int
    var activeCourses: Int
    var weeklyLoad: Int
    var summary: String
    var updatedAt: Date
    var needsSync: Bool

    init(from dto: TeacherDTO) {
        self.id = dto.id
        self.name = dto.name
        self.title = dto.title
        self.department = dto.department
        self.email = dto.email
        self.office = dto.office
        self.advisees = dto.advisees
        self.activeCourses = dto.activeCourses
        self.weeklyLoad = dto.weeklyLoad
        self.summary = dto.summary
        self.updatedAt = Date()
        self.needsSync = false
    }

    func toDTO() -> TeacherDTO {
        TeacherDTO(
            id: id,
            name: name,
            title: title,
            department: department,
            email: email,
            office: office,
            advisees: advisees,
            activeCourses: activeCourses,
            weeklyLoad: weeklyLoad,
            summary: summary
        )
    }
}

// MARK: - Persistent Guardian

@Model
final class PersistentGuardian {
    @Attribute(.unique) var id: String
    var studentId: String
    var name: String
    var relationship: String
    var phone: String
    var email: String
    var updatedAt: Date

    init(id: String, studentId: String, name: String, relationship: String, phone: String, email: String) {
        self.id = id
        self.studentId = studentId
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.email = email
        self.updatedAt = Date()
    }
}

// MARK: - Sync Log

@Model
final class SyncLogEntry {
    var entityType: String
    var entityId: String
    var operation: String
    var occurredAt: Date
    var synced: Bool

    init(entityType: String, entityId: String, operation: String) {
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.occurredAt = Date()
        self.synced = false
    }
}

// MARK: - Container Factory

enum SwiftDataStack {
    static let schema = Schema([
        PersistentStudent.self,
        PersistentTeacher.self,
        PersistentGuardian.self,
        SyncLogEntry.self
    ])

    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true
    )

    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
