// LS-49: Implementar persistência offline com SwiftData + sync
import Foundation
import SwiftData

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    @Published private(set) var pendingSyncCount: Int = 0
    @Published private(set) var isSyncing: Bool = false

    private init() {
        do {
            let container = try SwiftDataStack.makeContainer()
            modelContainer = container
            modelContext = ModelContext(container)
        } catch {
            print("[SyncService] SwiftData container failed: \(error)")
        }
    }

    // MARK: - Students

    func cacheStudents(_ dtos: [StudentDTO]) async {
        guard let ctx = modelContext else { return }
        for dto in dtos {
            let descriptor = FetchDescriptor<PersistentStudent>(
                predicate: #Predicate { $0.id == dto.id }
            )
            if let existing = try? ctx.fetch(descriptor).first {
                existing.name = dto.name
                existing.grade = dto.grade
                existing.status = dto.status
                existing.gpa = dto.gpa
                existing.attendance = dto.attendance
                existing.updatedAt = Date()
            } else {
                ctx.insert(PersistentStudent(from: dto))
            }
        }
        try? ctx.save()
    }

    func loadCachedStudents() async -> [StudentDTO] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<PersistentStudent>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = (try? ctx.fetch(descriptor)) ?? []
        return results.map { $0.toDTO() }
    }

    func removeStudent(id: String) async {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<PersistentStudent>(
            predicate: #Predicate { $0.id == id }
        )
        if let found = try? ctx.fetch(descriptor).first {
            ctx.delete(found)
            try? ctx.save()
        }
    }

    // MARK: - Teachers

    func cacheTeachers(_ dtos: [TeacherDTO]) async {
        guard let ctx = modelContext else { return }
        for dto in dtos {
            let descriptor = FetchDescriptor<PersistentTeacher>(
                predicate: #Predicate { $0.id == dto.id }
            )
            if let existing = try? ctx.fetch(descriptor).first {
                existing.name = dto.name
                existing.title = dto.title
                existing.department = dto.department
                existing.updatedAt = Date()
            } else {
                ctx.insert(PersistentTeacher(from: dto))
            }
        }
        try? ctx.save()
    }

    func loadCachedTeachers() async -> [TeacherDTO] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<PersistentTeacher>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = (try? ctx.fetch(descriptor)) ?? []
        return results.map { $0.toDTO() }
    }

    func removeTeacher(id: String) async {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<PersistentTeacher>(
            predicate: #Predicate { $0.id == id }
        )
        if let found = try? ctx.fetch(descriptor).first {
            ctx.delete(found)
            try? ctx.save()
        }
    }

    // MARK: - Guardians

    func cacheGuardians(_ guardians: [Guardian], forStudentId studentId: String) async {
        guard let ctx = modelContext else { return }
        // Remove old guardians for this student
        let descriptor = FetchDescriptor<PersistentGuardian>(
            predicate: #Predicate { $0.studentId == studentId }
        )
        let old = (try? ctx.fetch(descriptor)) ?? []
        for item in old { ctx.delete(item) }

        for g in guardians {
            ctx.insert(PersistentGuardian(
                id: g.id,
                studentId: studentId,
                name: g.name,
                relationship: g.relationship,
                phone: g.phone,
                email: g.email
            ))
        }
        try? ctx.save()
    }

    func loadCachedGuardians(forStudentId studentId: String) async -> [Guardian] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<PersistentGuardian>(
            predicate: #Predicate { $0.studentId == studentId }
        )
        let results = (try? ctx.fetch(descriptor)) ?? []
        return results.map {
            Guardian(id: $0.id, name: $0.name, relationship: $0.relationship, phone: $0.phone, email: $0.email)
        }
    }

    // MARK: - Sync Pending

    func refreshPendingCount() {
        guard let ctx = modelContext else { return }
        let sDescriptor = FetchDescriptor<PersistentStudent>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let tDescriptor = FetchDescriptor<PersistentTeacher>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let sCount = (try? ctx.fetch(sDescriptor).count) ?? 0
        let tCount = (try? ctx.fetch(tDescriptor).count) ?? 0
        pendingSyncCount = sCount + tCount
    }

    func syncPending() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        guard let ctx = modelContext else { return }
        let supabase = SupabaseService.shared

        // Sync pending students
        let sDescriptor = FetchDescriptor<PersistentStudent>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let pendingStudents = (try? ctx.fetch(sDescriptor)) ?? []
        for ps in pendingStudents {
            do {
                _ = try await supabase.update(table: "students", id: ps.id, value: ps.toDTO())
                ps.needsSync = false
            } catch {
                print("[SyncService] Failed to sync student \(ps.id): \(error)")
            }
        }

        // Sync pending teachers
        let tDescriptor = FetchDescriptor<PersistentTeacher>(
            predicate: #Predicate { $0.needsSync == true }
        )
        let pendingTeachers = (try? ctx.fetch(tDescriptor)) ?? []
        for pt in pendingTeachers {
            do {
                _ = try await supabase.update(table: "teachers", id: pt.id, value: pt.toDTO())
                pt.needsSync = false
            } catch {
                print("[SyncService] Failed to sync teacher \(pt.id): \(error)")
            }
        }

        try? ctx.save()
        refreshPendingCount()
    }
}
