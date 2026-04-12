import Charts
import SwiftUI

struct MainView: View {
    @State private var selection: SchoolSection = .dashboard
    @State private var isPresentingAssignmentComposer = false

    var body: some View {
        NavigationSplitView {
            SchoolSidebar(
                selection: $selection,
                isPresentingAssignmentComposer: $isPresentingAssignmentComposer
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 300)
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    DashboardView()
                case .students:
                    StudentsWorkspaceView()
                case .teachers:
                    TeachersWorkspaceView()
                case .classes:
                    ClassesWorkspaceView(isPresentingAssignmentComposer: $isPresentingAssignmentComposer)
                case .attendance:
                    AttendanceView()
                case .schedule:
                    ScheduleView()
                case .calendar:
                    CalendarView()
                case .reports:
                    ReportsView()
                case .settings:
                    SettingsView()
                }
            }
            .background(SchoolCanvasBackground())
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $isPresentingAssignmentComposer) {
            AssignmentComposerView()
        }
    }
}

private struct SchoolSidebar: View {
    @Binding var selection: SchoolSection
    @Binding var isPresentingAssignmentComposer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SchoolPalette.primary)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lexend Academy")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                        Text("ADMIN PORTAL")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .kerning(1.8)
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }

                Text("A polished iPad and iPhone app generated from the exported design set in `iosapp`.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)

            List {
                ForEach(SchoolSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: section.symbol)
                                .font(.system(size: 15, weight: .bold))
                            Text(section.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(selection == section ? SchoolPalette.primary : SchoolPalette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(selection == section ? SchoolPalette.primary.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            VStack(alignment: .leading, spacing: 14) {
                Button {
                    isPresentingAssignmentComposer = true
                } label: {
                    Label("Create Assignment", systemImage: "square.and.pencil")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .schoolProminentButton()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Academic year 2026")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text("Designed for responsive split view and Liquid Glass on iOS 26 and later.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    SchoolPalette.background,
                    Color.white.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: 20)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Overview",
                    title: "Dashboard Overview",
                    subtitle: "Welcome back. Here is what is happening across your school today."
                ) {
                    HStack(spacing: 12) {
                        IconBadge(symbol: "bell.badge.fill", accent: SchoolPalette.warning)

                        Button {
                        } label: {
                            Label("New Enrollment", systemImage: "plus")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .schoolProminentButton()
                    }
                }

                AdaptiveGlassGroup(spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(DemoData.dashboardMetrics) { metric in
                            MetricCard(metric: metric)
                        }
                    }
                }

                if horizontalSizeClass == .compact {
                    VStack(spacing: 20) {
                        attendanceCard
                        recentActivityCard
                    }
                } else {
                    HStack(alignment: .top, spacing: 20) {
                        attendanceCard
                        recentActivityCard
                            .frame(maxWidth: 360)
                    }
                }

                HStack {
                    Text("© 2026 Lexend Scholar")
                    Spacer()
                    Text("Support")
                    Text("Privacy")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
                .padding(.top, 8)
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }

    private var attendanceCard: some View {
        SchoolCard(
            title: "Weekly Attendance",
            subtitle: "Overview of student presence across all grades"
        ) {
            Chart(DemoData.attendanceTrend) { point in
                AreaMark(
                    x: .value("Day", point.label),
                    y: .value("Attendance", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            SchoolPalette.primary.opacity(0.35),
                            SchoolPalette.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Day", point.label),
                    y: .value("Attendance", point.value)
                )
                .foregroundStyle(SchoolPalette.primary)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 260)
            .chartYScale(domain: 60...100)
            .chartXAxis {
                AxisMarks(values: DemoData.attendanceTrend.map(\.label))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }

    private var recentActivityCard: some View {
        SchoolCard(
            title: "Recent Activities",
            subtitle: "Latest changes from admissions, finance, and operations"
        ) {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(DemoData.recentActivities) { activity in
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(activity.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: activity.symbol)
                                    .foregroundStyle(activity.accent)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(activity.detail)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Text(activity.time)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText.opacity(0.7))
                        }
                    }
                }

                Button("View All Activity") {
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primary)
            }
        }
    }
}

private struct StudentsWorkspaceView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var searchText = ""
    @State private var selectedStudentID = DemoData.students.first?.id ?? ""

    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return DemoData.students
        }

        return DemoData.students.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.studentNumber.localizedCaseInsensitiveContains(searchText) ||
            $0.grade.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedStudent: Student {
        filteredStudents.first(where: { $0.id == selectedStudentID }) ??
        DemoData.students.first!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Students",
                    title: "Student Success Hub",
                    subtitle: "Directory, profile detail, guardian context, and academic health in one place."
                ) {
                    HStack(spacing: 12) {
                        SchoolSearchBar(text: $searchText, placeholder: "Search students, IDs, or grades")
                            .frame(width: 320)

                        Button {
                        } label: {
                            Label("Add Student", systemImage: "person.badge.plus")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .schoolProminentButton()
                    }
                }

                if horizontalSizeClass == .compact {
                    VStack(spacing: 20) {
                        directoryCard
                        studentDetailStack
                    }
                } else {
                    HStack(alignment: .top, spacing: 20) {
                        directoryCard
                            .frame(width: 320)
                        studentDetailStack
                    }
                }
            }
            .padding(28)
            .onChange(of: filteredStudents.map(\.id)) { _, ids in
                if !ids.contains(selectedStudentID), let firstID = ids.first {
                    selectedStudentID = firstID
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var directoryCard: some View {
        SchoolCard(
            title: "Student Directory",
            subtitle: "\(filteredStudents.count) profiles available"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(filteredStudents) { student in
                    Button {
                        selectedStudentID = student.id
                    } label: {
                        HStack(spacing: 14) {
                            InitialAvatar(name: student.name, accent: student.accent, size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(student.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.primaryText)
                                Text("\(student.grade) • \(student.department)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                            }

                            Spacer()

                            StatusChip(
                                text: student.status,
                                color: colorForStudentStatus(student.status)
                            )
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(selectedStudentID == student.id ? SchoolPalette.surfaceAlt : Color.white.opacity(0.45))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var studentDetailStack: some View {
        VStack(spacing: 20) {
            if horizontalSizeClass == .compact {
                VStack(spacing: 20) {
                    studentHeroCard
                    studentPerformanceCard
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    studentHeroCard
                    studentPerformanceCard
                        .frame(maxWidth: 340)
                }
            }

            if horizontalSizeClass == .compact {
                VStack(spacing: 20) {
                    studentContactCard
                    studentAttendanceCard
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    studentContactCard
                    studentAttendanceCard
                }
            }

            if horizontalSizeClass == .compact {
                VStack(spacing: 20) {
                    academicHistoryCard
                    sideContextCard
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    academicHistoryCard
                    sideContextCard
                        .frame(maxWidth: 320)
                }
            }
        }
    }

    private var studentHeroCard: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    InitialAvatar(name: selectedStudent.name, accent: selectedStudent.accent, size: 110)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedStudent.name)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)

                        HStack(spacing: 10) {
                            StatusChip(text: selectedStudent.grade, color: selectedStudent.accent)
                            StatusChip(text: selectedStudent.studentNumber, color: SchoolPalette.secondaryText)
                            StatusChip(text: selectedStudent.status, color: colorForStudentStatus(selectedStudent.status))
                        }

                        Text(selectedStudent.bio)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                AdaptiveGlassGroup(spacing: 16) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 14)], spacing: 14) {
                        statBlock(title: "GPA", value: String(format: "%.1f", selectedStudent.gpa))
                        statBlock(title: "Attendance", value: "\(selectedStudent.attendance)%")
                        statBlock(title: "Class Rank", value: selectedStudent.rank)
                        statBlock(title: "Credits", value: String(format: "%.1f", selectedStudent.credits))
                    }
                }
            }
        }
    }

    private var studentPerformanceCard: some View {
        SchoolCard(
            title: "Performance Trend",
            subtitle: "Semester and coursework health"
        ) {
            Chart {
                ForEach(selectedStudent.performance) { point in
                    BarMark(
                        x: .value("Segment", point.label),
                        y: .value("Primary", point.value)
                    )
                    .foregroundStyle(selectedStudent.accent.gradient)

                    if let secondaryValue = point.secondaryValue {
                        RuleMark(y: .value("Baseline", secondaryValue))
                            .foregroundStyle(SchoolPalette.secondaryText.opacity(0.45))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
            }
            .frame(height: 220)
            .chartYScale(domain: 60...100)

            VStack(alignment: .leading, spacing: 12) {
                performanceStatRow(label: "Semester average", value: "94.8%")
                performanceStatRow(label: "Advisor", value: selectedStudent.advisor)
                Text("Academic standing: Distinguished Honors")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }
        }
    }

    private var studentContactCard: some View {
        SchoolCard(
            title: "Contact Information",
            subtitle: "Primary contact channels and guardian reference"
        ) {
            VStack(alignment: .leading, spacing: 18) {
                infoRow(symbol: "envelope.fill", title: "Email", value: selectedStudent.email)
                infoRow(symbol: "phone.fill", title: "Phone", value: selectedStudent.phone)
                infoRow(symbol: "mappin.and.ellipse", title: "Address", value: selectedStudent.address)

                Divider()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Guardian Contacts")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)

                    ForEach(selectedStudent.guardians) { guardian in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(guardian.name) (\(guardian.relationship))")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text("\(guardian.phone) • \(guardian.email)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var studentAttendanceCard: some View {
        SchoolCard(
            title: "Attendance Record",
            subtitle: "Last 24 academic days"
        ) {
            AdaptiveGlassGroup(spacing: 14) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    statBlock(title: "Overall", value: "\(selectedStudent.attendance)%")
                    statBlock(title: "Present", value: "176")
                    statBlock(title: "Absent", value: "4")
                    statBlock(title: "Late", value: "2")
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Last 30 Days Engagement")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundStyle(SchoolPalette.secondaryText)

                AttendanceHeatStrip(states: selectedStudent.attendanceMarks)
            }
        }
    }

    private var academicHistoryCard: some View {
        SchoolCard(
            title: "Academic History",
            subtitle: "Recent course results and transcript view"
        ) {
            VStack(spacing: 12) {
                ForEach(selectedStudent.courseHistory) { course in
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(course.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: course.symbol)
                                    .foregroundStyle(course.accent)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(course.instructor)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Text(course.term)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText.opacity(0.8))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            Text(course.grade)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            StatusChip(text: course.status, color: SchoolPalette.success)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var sideContextCard: some View {
        VStack(spacing: 20) {
            SchoolCard(
                title: "Guardian Focus",
                subtitle: "Last confirmed contacts"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(selectedStudent.guardians) { guardian in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(guardian.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(guardian.relationship)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Text(guardian.phone)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                }
            }

            SchoolCard(
                title: "Administrative Notes",
                subtitle: "Latest internal annotations"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(selectedStudent.notes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.date)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primary)
                            Text(note.message)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(1.0)
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }

    private func performanceStatRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
        .padding(.vertical, 2)
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SchoolPalette.secondaryText)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.1)
                    .foregroundStyle(SchoolPalette.secondaryText)
                Text(value)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
            }
        }
    }
}

private struct TeachersWorkspaceView: View {
    @State private var selectedTeacherID = DemoData.teachers.first?.id ?? ""

    private var selectedTeacher: Teacher {
        DemoData.teachers.first(where: { $0.id == selectedTeacherID }) ?? DemoData.teachers.first!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Faculty",
                    title: "Teacher Profiles",
                    subtitle: "Focused view of faculty workload, expertise, and advisory coverage."
                ) {
                    Button {
                    } label: {
                        Label("Schedule Check-in", systemImage: "calendar.badge.plus")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DemoData.teachers) { teacher in
                            Button {
                                selectedTeacherID = teacher.id
                            } label: {
                                HStack(spacing: 10) {
                                    InitialAvatar(name: teacher.name, accent: teacher.accent, size: 38)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(teacher.name)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text(teacher.department)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(selectedTeacherID == teacher.id ? SchoolPalette.surfaceAlt : Color.white.opacity(0.7))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 18) {
                                InitialAvatar(name: selectedTeacher.name, accent: selectedTeacher.accent, size: 96)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(selectedTeacher.name)
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                    Text(selectedTeacher.title)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                    StatusChip(text: selectedTeacher.department, color: selectedTeacher.accent)
                                }
                            }

                            Text(selectedTeacher.summary)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)

                            AdaptiveGlassGroup {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                                    teacherMetric(title: "Advisees", value: "\(selectedTeacher.advisees)")
                                    teacherMetric(title: "Courses", value: "\(selectedTeacher.activeCourses)")
                                    teacherMetric(title: "Weekly Load", value: "\(selectedTeacher.weeklyLoad)h")
                                }
                            }
                        }
                    }

                    SchoolCard(
                        title: "Availability",
                        subtitle: "Office hours and support windows"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(selectedTeacher.availability, id: \.self) { slot in
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(selectedTeacher.accent)
                                    Text(slot)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.primaryText)
                                }
                            }

                            Divider()

                            Text(selectedTeacher.email)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Text(selectedTeacher.office)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                    .frame(maxWidth: 320)
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Focus Areas",
                        subtitle: "Key contributions in the academic program"
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(selectedTeacher.expertise, id: \.self) { item in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(selectedTeacher.accent)
                                        .frame(width: 8, height: 8)
                                    Text(item)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.primaryText)
                                }
                            }
                        }
                    }

                    SchoolCard(
                        title: "Assigned Courses",
                        subtitle: "Current classes overseen by this faculty member"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(DemoData.courses.filter { $0.teacher == selectedTeacher.name }) { course in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(course.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text("\(course.grade) • \(course.room) • \(course.period)")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                    Spacer()
                                    StatusChip(text: course.status, color: course.accent)
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }

    private func teacherMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(selectedTeacher.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }
}

private struct ClassesWorkspaceView: View {
    @Binding var isPresentingAssignmentComposer: Bool

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 240), spacing: 18)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Academics",
                    title: "Class Schedule & Courses",
                    subtitle: "Manage sections, faculty assignments, and upcoming coursework."
                ) {
                    Button {
                        isPresentingAssignmentComposer = true
                    } label: {
                        Label("Create Assignment", systemImage: "square.and.pencil")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                HStack(spacing: 10) {
                    StatusChip(text: "All Grades", color: SchoolPalette.primary)
                    StatusChip(text: "Department Mix", color: SchoolPalette.violet)
                    StatusChip(text: "Teacher Load", color: SchoolPalette.success)
                }

                AdaptiveGlassGroup(spacing: 18) {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(DemoData.courses) { course in
                            SchoolCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        StatusChip(text: course.grade, color: course.accent)
                                        Spacer()
                                        Image(systemName: "ellipsis")
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }

                                    Text(course.title)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.primaryText)

                                    Text(course.teacher)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("\(course.period) • Room \(course.room)", systemImage: "clock.fill")
                                        Label("\(course.enrolled)/\(course.capacity) seats occupied", systemImage: "person.3.sequence.fill")
                                        Label("Next: \(course.nextAssignment)", systemImage: "checklist")
                                    }
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)

                                    HStack {
                                        Text(course.department)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                        Spacer()
                                        StatusChip(text: course.status, color: course.accent)
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Schedule Pulse",
                        subtitle: "Classes across the current operational week"
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(DemoData.schedule.prefix(4)) { entry in
                                HStack(alignment: .top, spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(entry.accent.opacity(0.14))
                                        .frame(width: 12)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(entry.day) • \(entry.start) - \(entry.end)")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                        Text("\(entry.course) • \(entry.room)")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                }
                            }
                        }
                    }

                    SchoolCard(
                        title: "Assignment Queue",
                        subtitle: "What is about to go live"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(DemoData.courses.prefix(4)) { course in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(course.nextAssignment)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text(course.title)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                    Spacer()
                                    Text(course.period)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(course.accent)
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }
}

private struct AttendanceView: View {
    private let roster = DemoData.students

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Operations",
                    title: "Attendance Tracking",
                    subtitle: "Grade 10-A coverage, intervention flags, and classroom presence trends."
                ) {
                    StatusChip(text: "Grade 10-A", color: SchoolPalette.primary)
                }

                AdaptiveGlassGroup(spacing: 18) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 18)], spacing: 18) {
                        MetricCard(
                            metric: DashboardMetric(
                                id: "overall-att",
                                title: "Overall Presence",
                                value: "98%",
                                change: "+1.1%",
                                symbol: "checkmark.circle.fill",
                                accent: SchoolPalette.success,
                                changeColor: SchoolPalette.success
                            )
                        )
                        MetricCard(
                            metric: DashboardMetric(
                                id: "present",
                                title: "Present Students",
                                value: "176",
                                change: "Stable",
                                symbol: "person.fill.checkmark",
                                accent: SchoolPalette.primary,
                                changeColor: SchoolPalette.secondaryText
                            )
                        )
                        MetricCard(
                            metric: DashboardMetric(
                                id: "absent",
                                title: "Absences",
                                value: "4",
                                change: "-2",
                                symbol: "person.fill.xmark",
                                accent: SchoolPalette.danger,
                                changeColor: SchoolPalette.danger
                            )
                        )
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Engagement Heatmap",
                        subtitle: "Rolling 24-day presence signal"
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(roster) { student in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(student.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                    AttendanceHeatStrip(states: student.attendanceMarks)
                                }
                            }
                        }
                    }

                    SchoolCard(
                        title: "Intervention Watch",
                        subtitle: "Students requiring follow-up"
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(roster.filter { $0.attendance < 95 }) { student in
                                HStack {
                                    InitialAvatar(name: student.name, accent: student.accent, size: 40)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(student.name)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text("\(student.attendance)% attendance • Advisor: \(student.advisor)")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 320)
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ScheduleView: View {
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Timetable",
                    title: "Master Class Schedule",
                    subtitle: "A responsive schedule canvas inspired by the exported calendar view."
                ) {
                    StatusChip(text: "This Week", color: SchoolPalette.primary)
                }

                HStack(spacing: 18) {
                    miniContextCard(title: "View Context", value: "All campuses", accent: SchoolPalette.primary)
                    miniContextCard(title: "Departments", value: "6 active", accent: SchoolPalette.violet)
                    miniContextCard(title: "Quick Stats", value: "31 sessions", accent: SchoolPalette.success)
                }

                SchoolCard(
                    title: "Week at a Glance",
                    subtitle: "Department-balanced schedule board"
                ) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(weekdays, id: \.self) { day in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(day)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.primaryText)

                                ForEach(DemoData.schedule.filter { $0.day == day }) { entry in
                                    HStack(spacing: 14) {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(entry.accent.opacity(0.14))
                                            .frame(width: 14)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.course)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                            Text("\(entry.start) - \(entry.end) • \(entry.room) • \(entry.teacher)")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundStyle(SchoolPalette.secondaryText)
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }

    private func miniContextCard(title: String, value: String, accent: Color) -> some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
        }
    }
}

private struct CalendarView: View {
    private let calendarSlots: [Int?] = Array(repeating: nil, count: 3) + Array(1...31).map(Optional.some)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Calendar",
                    title: "Academic Calendar",
                    subtitle: "October 2026 priorities, deadlines, and institutional events."
                ) {
                    StatusChip(text: "October 2026", color: SchoolPalette.primary)
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Month Grid",
                        subtitle: "Key event dates from the academic office"
                    ) {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                    .frame(maxWidth: .infinity)
                            }

                            ForEach(calendarSlots.indices, id: \.self) { index in
                                let day = calendarSlots[index]
                                let event = DemoData.calendarEvents.first(where: { $0.day == day })

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(day.map(String.init) ?? "")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(day == nil ? .clear : SchoolPalette.primaryText)
                                    if let event {
                                        Text(event.category)
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(event.accent)
                                            .lineLimit(1)
                                    } else {
                                        Spacer()
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(event?.accent.opacity(0.10) ?? Color.white.opacity(0.65))
                                )
                            }
                        }
                    }

                    SchoolCard(
                        title: "Upcoming Events",
                        subtitle: "What needs coordination next"
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(DemoData.calendarEvents) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(event.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Spacer()
                                        Text(event.dateLabel)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(event.accent)
                                    }

                                    Text(event.detail)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 340)
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ReportsView: View {
    private var reportMetrics: [DashboardMetric] {
        [
            DashboardMetric(id: "gpa", title: "Average GPA", value: "3.2", change: "+0.2", symbol: "chart.bar.fill", accent: SchoolPalette.primary, changeColor: SchoolPalette.success),
            DashboardMetric(id: "att", title: "Attendance Rate", value: "94.2%", change: "+1.4%", symbol: "checkmark.rectangle.stack.fill", accent: SchoolPalette.success, changeColor: SchoolPalette.success),
            DashboardMetric(id: "credits", title: "Credits Earned", value: "12,450", change: "Target 15k", symbol: "checkmark.seal.fill", accent: SchoolPalette.violet, changeColor: SchoolPalette.secondaryText),
            DashboardMetric(id: "risk", title: "At-Risk Students", value: "45", change: "-5 students", symbol: "exclamationmark.triangle.fill", accent: SchoolPalette.danger, changeColor: SchoolPalette.danger)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Analytics",
                    title: "Academic Reports & Analytics",
                    subtitle: "Institution-level metrics, charts, and export-ready report templates."
                ) {
                    Button {
                    } label: {
                        Label("Export All", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                AdaptiveGlassGroup(spacing: 18) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 18)], spacing: 18) {
                        ForEach(reportMetrics) { metric in
                            MetricCard(metric: metric)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Performance Trends",
                        subtitle: "GPA and passing baseline across reporting windows"
                    ) {
                        Chart {
                            ForEach(DemoData.students.first!.performance) { point in
                                LineMark(
                                    x: .value("Window", point.label),
                                    y: .value("GPA Equivalent", point.value)
                                )
                                .foregroundStyle(SchoolPalette.primary)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                                if let secondary = point.secondaryValue {
                                    LineMark(
                                        x: .value("Window", point.label),
                                        y: .value("Passing", secondary)
                                    )
                                    .foregroundStyle(SchoolPalette.violet)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                }
                            }
                        }
                        .frame(height: 260)
                        .chartYScale(domain: 60...100)
                    }

                    SchoolCard(
                        title: "Attendance Trends",
                        subtitle: "Pulse from the last five checkpoints"
                    ) {
                        Chart(DemoData.attendanceTrend) { point in
                            BarMark(
                                x: .value("Day", point.label),
                                y: .value("Rate", point.value)
                            )
                            .foregroundStyle(SchoolPalette.primary.gradient)
                        }
                        .frame(height: 260)
                        .chartYScale(domain: 50...100)
                    }
                    .frame(maxWidth: 340)
                }

                SchoolCard(
                    title: "Available Reports",
                    subtitle: "Templates aligned with the exported analytics screens"
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(DemoData.reportTemplates) { report in
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(report.accent.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                    .overlay {
                                        Image(systemName: report.symbol)
                                            .foregroundStyle(report.accent)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(report.title)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Text(report.detail)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                }

                                Spacer()

                                Text(report.updated)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(report.accent)
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }
}

private struct SettingsView: View {
    @State private var schoolName = "Lexend Academy of Arts & Sciences"
    @State private var contactEmail = "admin@lexendscholar.edu"
    @State private var phoneNumber = "+1 (555) 123-4567"
    @State private var address = "1284 Education Plaza, Suite 400, Cambridge, MA 02138"
    @State private var preferences = DemoData.preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SchoolSectionHeader(
                    eyebrow: "Settings",
                    title: "System Configuration",
                    subtitle: "Institutional profile, administrative users, and automation preferences."
                ) {
                    Button {
                    } label: {
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                HStack(alignment: .top, spacing: 20) {
                    SchoolCard(
                        title: "Institutional Profile",
                        subtitle: "Core school identity and contact fields"
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            editableField(title: "School Name", text: $schoolName)
                            editableField(title: "Contact Email", text: $contactEmail)
                            editableField(title: "Phone Number", text: $phoneNumber)
                            editableField(title: "Address", text: $address)
                        }
                    }

                    SchoolCard(
                        title: "System Preferences",
                        subtitle: "Signal routing for academic operations"
                    ) {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach($preferences) { $preference in
                                Toggle(isOn: $preference.isEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preference.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text(preference.detail)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(SchoolPalette.secondaryText)
                                    }
                                }
                                .tint(SchoolPalette.primary)
                            }
                        }
                    }
                    .frame(maxWidth: 360)
                }

                SchoolCard(
                    title: "Administrative Users",
                    subtitle: "People currently allowed to manage institutional data"
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(DemoData.adminUsers) { user in
                            HStack {
                                InitialAvatar(name: user.name, accent: SchoolPalette.primary, size: 42)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                    Text(user.email)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(user.role)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.primaryText)
                                    StatusChip(
                                        text: user.status,
                                        color: user.status == "Pending" ? SchoolPalette.warning : SchoolPalette.success
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollIndicators(.hidden)
    }

    private func editableField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(1.1)
                .foregroundStyle(SchoolPalette.secondaryText)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(SchoolPalette.outline, lineWidth: 1)
                )
        }
    }
}

private struct AssignmentComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = "Semester Reflection Essay"
    @State private var course = DemoData.courses.first?.title ?? ""
    @State private var dueDate = Date.now.addingTimeInterval(60 * 60 * 24 * 7)
    @State private var instructions = "Invite students to connect current unit insights with a real campus initiative."

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment") {
                    TextField("Title", text: $title)
                    Picker("Course", selection: $course) {
                        ForEach(DemoData.courses, id: \.title) { course in
                            Text(course.title).tag(course.title)
                        }
                    }
                    DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle("Create New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

private struct AttendanceHeatStrip: View {
    let states: [AttendanceState]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 12), spacing: 6)], spacing: 6) {
            ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(state.color)
                    .frame(height: 16)
            }
        }
    }
}

private struct IconBadge: View {
    let symbol: String
    let accent: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(accent)
            .padding(14)
            .background(
                Circle()
                    .fill(accent.opacity(0.12))
            )
    }
}

private func colorForStudentStatus(_ status: String) -> Color {
    switch status.lowercased() {
    case "active":
        SchoolPalette.success
    case "support":
        SchoolPalette.warning
    default:
        SchoolPalette.secondaryText
    }
}
