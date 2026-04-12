import SwiftUI

enum SchoolSection: String, CaseIterable, Identifiable {
    case dashboard
    case students
    case teachers
    case classes
    case attendance
    case schedule
    case calendar
    case reports
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .students: "Students"
        case .teachers: "Teachers"
        case .classes: "Classes"
        case .attendance: "Attendance"
        case .schedule: "Schedule"
        case .calendar: "Calendar"
        case .reports: "Reports"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2.fill"
        case .students: "person.3.fill"
        case .teachers: "person.text.rectangle.fill"
        case .classes: "book.closed.fill"
        case .attendance: "checklist.checked"
        case .schedule: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .calendar: "calendar"
        case .reports: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape.fill"
        }
    }
}

struct DashboardMetric: Identifiable {
    let id: String
    let title: String
    let value: String
    let change: String
    let symbol: String
    let accent: Color
    let changeColor: Color
}

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let time: String
    let symbol: String
    let accent: Color
}

struct ProgressPoint: Identifiable {
    let id: String
    let label: String
    let value: Double
    let secondaryValue: Double?
}

enum AttendanceState: String, Identifiable {
    case present
    case absent
    case late

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .present: SchoolPalette.primary
        case .absent: SchoolPalette.danger
        case .late: SchoolPalette.warning
        }
    }
}

struct Guardian: Identifiable {
    let id: String
    let name: String
    let relationship: String
    let phone: String
    let email: String
}

struct AdminNote: Identifiable {
    let id: String
    let date: String
    let message: String
}

struct CourseResult: Identifiable {
    let id: String
    let title: String
    let instructor: String
    let term: String
    let grade: String
    let status: String
    let accent: Color
    let symbol: String
}

struct Student: Identifiable {
    let id: String
    let name: String
    let grade: String
    let studentNumber: String
    let department: String
    let status: String
    let accent: Color
    let bio: String
    let email: String
    let phone: String
    let address: String
    let gpa: Double
    let attendance: Int
    let rank: String
    let credits: Double
    let advisor: String
    let performance: [ProgressPoint]
    let courseHistory: [CourseResult]
    let guardians: [Guardian]
    let notes: [AdminNote]
    let attendanceMarks: [AttendanceState]
}

struct Teacher: Identifiable {
    let id: String
    let name: String
    let title: String
    let department: String
    let email: String
    let office: String
    let expertise: [String]
    let advisees: Int
    let activeCourses: Int
    let weeklyLoad: Int
    let accent: Color
    let summary: String
    let availability: [String]
}

struct Course: Identifiable {
    let id: String
    let title: String
    let grade: String
    let department: String
    let teacher: String
    let room: String
    let period: String
    let enrolled: Int
    let capacity: Int
    let status: String
    let accent: Color
    let nextAssignment: String
}

struct ScheduleEntry: Identifiable {
    let id: String
    let day: String
    let start: String
    let end: String
    let course: String
    let room: String
    let teacher: String
    let accent: Color
}

struct AcademicEvent: Identifiable {
    let id: String
    let title: String
    let day: Int
    let dateLabel: String
    let category: String
    let detail: String
    let accent: Color
}

struct ReportTemplate: Identifiable {
    let id: String
    let title: String
    let detail: String
    let updated: String
    let symbol: String
    let accent: Color
}

struct AdminUser: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let status: String
}

struct SettingPreference: Identifiable {
    let id: String
    let title: String
    let detail: String
    var isEnabled: Bool
}

enum DemoData {
    static let dashboardMetrics: [DashboardMetric] = [
        DashboardMetric(id: "students", title: "Total Students", value: "1,250", change: "+2.5%", symbol: "graduationcap.fill", accent: SchoolPalette.primary, changeColor: SchoolPalette.success),
        DashboardMetric(id: "teachers", title: "Active Teachers", value: "85", change: "0.0%", symbol: "person.fill.badge.plus", accent: SchoolPalette.violet, changeColor: SchoolPalette.secondaryText),
        DashboardMetric(id: "attendance", title: "Attendance Rate", value: "96.5%", change: "+1.2%", symbol: "checkmark.seal.fill", accent: SchoolPalette.success, changeColor: SchoolPalette.success),
        DashboardMetric(id: "pending", title: "Pending Enrollments", value: "12", change: "-5.0%", symbol: "doc.text.magnifyingglass", accent: SchoolPalette.warning, changeColor: SchoolPalette.danger)
    ]

    static let recentActivities: [ActivityItem] = [
        ActivityItem(id: "act-1", title: "New student registered", detail: "Alex Johnson joined Grade 5", time: "2 hours ago", symbol: "person.badge.plus", accent: SchoolPalette.primary),
        ActivityItem(id: "act-2", title: "Staff meeting scheduled", detail: "Monthly review in Conference Room A", time: "5 hours ago", symbol: "calendar.badge.clock", accent: SchoolPalette.warning),
        ActivityItem(id: "act-3", title: "Tuition payment received", detail: "Michael Wong - Term 2 fees", time: "Yesterday", symbol: "banknote.fill", accent: SchoolPalette.success)
    ]

    static let attendanceTrend: [ProgressPoint] = [
        ProgressPoint(id: "mon", label: "Mon", value: 72, secondaryValue: nil),
        ProgressPoint(id: "tue", label: "Tue", value: 89, secondaryValue: nil),
        ProgressPoint(id: "wed", label: "Wed", value: 80, secondaryValue: nil),
        ProgressPoint(id: "thu", label: "Thu", value: 94, secondaryValue: nil),
        ProgressPoint(id: "fri", label: "Fri", value: 98, secondaryValue: nil)
    ]

    static let students: [Student] = [
        Student(
            id: "stu-001",
            name: "Sophia Anderson",
            grade: "Grade 10-A",
            studentNumber: "#STU-2023-001",
            department: "STEM",
            status: "Active",
            accent: SchoolPalette.primary,
            bio: "Sophomore student specializing in STEM tracks. Active member of the Robotics Club and Varsity Debate Team. Maintains consistent excellence in mathematics and physics.",
            email: "sophia.a@student.edu",
            phone: "+1 (555) 123-4567",
            address: "1248 Oakwood Ave, Apt 4B, Riverside, CA 92501",
            gpa: 3.8,
            attendance: 98,
            rank: "12 / 145",
            credits: 64.0,
            advisor: "Dr. Sarah Jenkins",
            performance: [
                ProgressPoint(id: "p1", label: "Sem 1", value: 92.4, secondaryValue: 88.0),
                ProgressPoint(id: "p2", label: "Sem 2", value: 94.8, secondaryValue: 90.0),
                ProgressPoint(id: "p3", label: "Projects", value: 96.0, secondaryValue: 91.5),
                ProgressPoint(id: "p4", label: "Labs", value: 95.0, secondaryValue: 93.2)
            ],
            courseHistory: [
                CourseResult(id: "cr-1", title: "Advanced Algebra II", instructor: "Dr. Emily Wick", term: "Fall 2023", grade: "A", status: "Completed", accent: SchoolPalette.primary, symbol: "sum"),
                CourseResult(id: "cr-2", title: "Organic Chemistry", instructor: "Prof. Marcus Chen", term: "Fall 2023", grade: "A-", status: "Completed", accent: SchoolPalette.violet, symbol: "flask.fill"),
                CourseResult(id: "cr-3", title: "Modern World History", instructor: "Sarah Jenkins", term: "Spring 2023", grade: "B+", status: "Completed", accent: SchoolPalette.warning, symbol: "globe.americas.fill"),
                CourseResult(id: "cr-4", title: "English Literature", instructor: "Dr. Alan Turing", term: "Spring 2023", grade: "A", status: "Completed", accent: SchoolPalette.success, symbol: "books.vertical.fill")
            ],
            guardians: [
                Guardian(id: "g-1", name: "Robert Anderson", relationship: "Father", phone: "+1 (555) 987-6543", email: "robert.anderson@email.com"),
                Guardian(id: "g-2", name: "Elena Anderson", relationship: "Mother", phone: "+1 (555) 222-8844", email: "elena.anderson@email.com")
            ],
            notes: [
                AdminNote(id: "n-1", date: "Dec 12, 2023", message: "Applied for Science Fair sponsorship. Approved by department head."),
                AdminNote(id: "n-2", date: "Jan 18, 2024", message: "Mentoring younger robotics students every Thursday afternoon.")
            ],
            attendanceMarks: [.present, .present, .present, .present, .present, .late, .present, .present, .present, .present, .present, .absent, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present]
        ),
        Student(
            id: "stu-002",
            name: "Elena Rodriguez",
            grade: "Grade 11-B",
            studentNumber: "#ST-2023-9041",
            department: "Sciences",
            status: "Active",
            accent: SchoolPalette.violet,
            bio: "Junior student focused on environmental science and biotechnology. Leads the sustainability committee and science peer tutors.",
            email: "elena.r@student.edu",
            phone: "+1 (555) 642-1188",
            address: "21 Cedar Lane, Cambridge, MA 02138",
            gpa: 3.9,
            attendance: 97,
            rank: "4 / 138",
            credits: 72.0,
            advisor: "Prof. Marcus Chen",
            performance: [
                ProgressPoint(id: "ep1", label: "Sem 1", value: 95.0, secondaryValue: 91.0),
                ProgressPoint(id: "ep2", label: "Sem 2", value: 96.2, secondaryValue: 92.3),
                ProgressPoint(id: "ep3", label: "Projects", value: 97.0, secondaryValue: 93.5)
            ],
            courseHistory: [],
            guardians: [],
            notes: [],
            attendanceMarks: [.present, .present, .present, .present, .present, .present, .present, .late, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .present, .absent, .present, .present]
        ),
        Student(
            id: "stu-003",
            name: "Jordan Lee",
            grade: "Grade 9-C",
            studentNumber: "#ST-2024-1882",
            department: "Humanities",
            status: "Support",
            accent: SchoolPalette.warning,
            bio: "Freshman with strong writing skills and active participation in Model UN. Currently supported through a tailored academic coaching plan.",
            email: "jordan.lee@student.edu",
            phone: "+1 (555) 300-1120",
            address: "88 River Street, Boston, MA 02111",
            gpa: 2.9,
            attendance: 91,
            rank: "88 / 163",
            credits: 31.5,
            advisor: "Dr. Alan Turing",
            performance: [
                ProgressPoint(id: "jp1", label: "Sem 1", value: 78.0, secondaryValue: 70.0),
                ProgressPoint(id: "jp2", label: "Sem 2", value: 82.0, secondaryValue: 74.0),
                ProgressPoint(id: "jp3", label: "Projects", value: 84.0, secondaryValue: 76.5)
            ],
            courseHistory: [],
            guardians: [],
            notes: [],
            attendanceMarks: [.present, .late, .present, .absent, .present, .present, .present, .present, .late, .present, .present, .present, .present, .absent, .present, .present, .present, .present, .late, .present, .present, .present, .present, .present]
        )
    ]

    static let teachers: [Teacher] = [
        Teacher(
            id: "t-1",
            name: "Dr. Sarah Jenkins",
            title: "Principal and Mathematics Chair",
            department: "Mathematics",
            email: "s.jenkins@lexend.edu",
            office: "North Hall, Office 304",
            expertise: ["Curriculum Design", "STEM Pathways", "Faculty Coaching"],
            advisees: 18,
            activeCourses: 4,
            weeklyLoad: 22,
            accent: SchoolPalette.primary,
            summary: "Leads the STEM department while mentoring teaching staff and coordinating district-wide academic planning.",
            availability: ["Mon 09:00 - 11:00", "Wed 14:00 - 16:00", "Fri 10:00 - 12:00"]
        ),
        Teacher(
            id: "t-2",
            name: "Prof. Marcus Chen",
            title: "Senior Science Instructor",
            department: "Sciences",
            email: "m.chen@lexend.edu",
            office: "Science Wing, Lab 8",
            expertise: ["Biochemistry", "Project-Based Learning", "Student Labs"],
            advisees: 12,
            activeCourses: 5,
            weeklyLoad: 18,
            accent: SchoolPalette.violet,
            summary: "Coordinates laboratory experiences across upper grades and oversees capstone science projects.",
            availability: ["Tue 08:00 - 09:30", "Thu 13:00 - 15:00"]
        ),
        Teacher(
            id: "t-3",
            name: "Dr. Alan Turing",
            title: "Humanities and Writing Mentor",
            department: "Humanities",
            email: "a.turing@lexend.edu",
            office: "West Hall, Room 12",
            expertise: ["Writing Studio", "Critical Reading", "Debate Coaching"],
            advisees: 26,
            activeCourses: 3,
            weeklyLoad: 16,
            accent: SchoolPalette.success,
            summary: "Supports cross-disciplinary writing programs and develops reading interventions for early secondary students.",
            availability: ["Mon 13:00 - 15:00", "Thu 09:00 - 11:00"]
        )
    ]

    static let courses: [Course] = [
        Course(id: "c-1", title: "Advanced Algebra II", grade: "Grade 10-A", department: "Mathematics", teacher: "Dr. Sarah Jenkins", room: "304", period: "Period 2", enrolled: 24, capacity: 30, status: "Active", accent: SchoolPalette.primary, nextAssignment: "Problem Set 08"),
        Course(id: "c-2", title: "Organic Chemistry", grade: "Grade 12-C", department: "Sciences", teacher: "Prof. Marcus Chen", room: "Lab 12", period: "Period 4", enrolled: 18, capacity: 22, status: "Active", accent: SchoolPalette.violet, nextAssignment: "Reaction Map"),
        Course(id: "c-3", title: "Modern World History", grade: "Grade 11-B", department: "Humanities", teacher: "Dr. Alan Turing", room: "210", period: "Period 1", enrolled: 28, capacity: 30, status: "Active", accent: SchoolPalette.warning, nextAssignment: "Essay Outline"),
        Course(id: "c-4", title: "Introduction to Physics", grade: "Grade 9-A", department: "Sciences", teacher: "Prof. Marcus Chen", room: "Lab 4", period: "Period 3", enrolled: 30, capacity: 30, status: "Full", accent: SchoolPalette.success, nextAssignment: "Lab Notes"),
        Course(id: "c-5", title: "English Literature", grade: "Grade 10-B", department: "Humanities", teacher: "Dr. Alan Turing", room: "118", period: "Period 5", enrolled: 26, capacity: 28, status: "Active", accent: SchoolPalette.primary, nextAssignment: "Reading Reflection"),
        Course(id: "c-6", title: "Computer Science I", grade: "Grade 9-D", department: "Technology", teacher: "Dr. Sarah Jenkins", room: "Innovation Lab", period: "Period 6", enrolled: 20, capacity: 24, status: "Active", accent: SchoolPalette.violet, nextAssignment: "Algorithm Journal")
    ]

    static let schedule: [ScheduleEntry] = [
        ScheduleEntry(id: "s-1", day: "Monday", start: "08:00", end: "09:20", course: "Advisory and Check-in", room: "Forum", teacher: "Leadership Team", accent: SchoolPalette.secondaryText),
        ScheduleEntry(id: "s-2", day: "Monday", start: "09:30", end: "10:50", course: "Advanced Algebra II", room: "304", teacher: "Dr. Sarah Jenkins", accent: SchoolPalette.primary),
        ScheduleEntry(id: "s-3", day: "Tuesday", start: "11:00", end: "12:20", course: "Organic Chemistry", room: "Lab 12", teacher: "Prof. Marcus Chen", accent: SchoolPalette.violet),
        ScheduleEntry(id: "s-4", day: "Wednesday", start: "13:00", end: "14:20", course: "Modern World History", room: "210", teacher: "Dr. Alan Turing", accent: SchoolPalette.warning),
        ScheduleEntry(id: "s-5", day: "Thursday", start: "14:30", end: "15:50", course: "Computer Science I", room: "Innovation Lab", teacher: "Dr. Sarah Jenkins", accent: SchoolPalette.success),
        ScheduleEntry(id: "s-6", day: "Friday", start: "10:00", end: "11:20", course: "English Literature", room: "118", teacher: "Dr. Alan Turing", accent: SchoolPalette.primary)
    ]

    static let calendarEvents: [AcademicEvent] = [
        AcademicEvent(id: "e-1", title: "Midterm Progress Reports", day: 7, dateLabel: "Oct 7", category: "Reporting", detail: "Reports published to guardians at 18:00.", accent: SchoolPalette.primary),
        AcademicEvent(id: "e-2", title: "Parent Advisory Meeting", day: 12, dateLabel: "Oct 12", category: "Community", detail: "Open forum with leadership and department chairs.", accent: SchoolPalette.warning),
        AcademicEvent(id: "e-3", title: "Robotics Regional Qualifier", day: 19, dateLabel: "Oct 19", category: "Student Life", detail: "Sophia Anderson's team competes in district finals.", accent: SchoolPalette.violet),
        AcademicEvent(id: "e-4", title: "Science Fair Submission Deadline", day: 24, dateLabel: "Oct 24", category: "Academic", detail: "Final abstracts and mentor approvals due.", accent: SchoolPalette.success),
        AcademicEvent(id: "e-5", title: "Faculty Planning Day", day: 29, dateLabel: "Oct 29", category: "Operations", detail: "No afternoon classes. Timetable revised.", accent: SchoolPalette.danger)
    ]

    static let reportTemplates: [ReportTemplate] = [
        ReportTemplate(id: "r-1", title: "Performance Snapshot", detail: "Student achievement trends by department and grade level.", updated: "Updated 2 hours ago", symbol: "chart.bar.xaxis", accent: SchoolPalette.primary),
        ReportTemplate(id: "r-2", title: "Attendance Intervention", detail: "Students below 92% attendance and active response plans.", updated: "Updated yesterday", symbol: "waveform.path.ecg", accent: SchoolPalette.danger),
        ReportTemplate(id: "r-3", title: "Faculty Workload", detail: "Teaching load, office hours, and advisory assignments.", updated: "Updated today", symbol: "person.2.wave.2.fill", accent: SchoolPalette.violet),
        ReportTemplate(id: "r-4", title: "Calendar Readiness", detail: "Upcoming deadlines and campus events requiring coordination.", updated: "Updated 30 min ago", symbol: "calendar.badge.exclamationmark", accent: SchoolPalette.warning)
    ]

    static let adminUsers: [AdminUser] = [
        AdminUser(id: "u-1", name: "Dr. Julian Harper", email: "j.harper@lexendscholar.edu", role: "Super Admin", status: "Active"),
        AdminUser(id: "u-2", name: "Laura Kim", email: "l.kim@lexendscholar.edu", role: "Registrar", status: "Active"),
        AdminUser(id: "u-3", name: "Mateo Silva", email: "m.silva@lexendscholar.edu", role: "Attendance Lead", status: "Pending")
    ]

    static let preferences: [SettingPreference] = [
        SettingPreference(id: "p-1", title: "Guardian digest emails", detail: "Send a weekly summary every Friday at 18:00.", isEnabled: true),
        SettingPreference(id: "p-2", title: "At-risk alerts", detail: "Notify advisors when GPA or attendance falls under threshold.", isEnabled: true),
        SettingPreference(id: "p-3", title: "Auto-lock grading periods", detail: "Close gradebook edits 48h after report publication.", isEnabled: false)
    ]
}
