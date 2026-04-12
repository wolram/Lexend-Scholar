import SwiftUI

// MARK: - Models

enum CategoriaEvento: String, CaseIterable {
    case academico = "Acadêmico"
    case feriado = "Feriado"
    case reuniao = "Reunião"
    case prova = "Prova"
    case evento = "Evento"
    case recesso = "Recesso"

    var color: Color {
        switch self {
        case .academico: return SchoolPalette.primary
        case .feriado: return SchoolPalette.danger
        case .reuniao: return SchoolPalette.warning
        case .prova: return SchoolPalette.violet
        case .evento: return SchoolPalette.success
        case .recesso: return SchoolPalette.secondaryText
        }
    }

    var symbol: String {
        switch self {
        case .academico: return "graduationcap.fill"
        case .feriado: return "star.fill"
        case .reuniao: return "person.2.fill"
        case .prova: return "pencil.and.list.clipboard"
        case .evento: return "sparkles"
        case .recesso: return "moon.fill"
        }
    }
}

struct EventoLetivo: Identifiable {
    let id: String
    let titulo: String
    let descricao: String
    let data: Date
    let dataFim: Date?
    let categoria: CategoriaEvento
    let turmas: [String]
}

// MARK: - CalendarioLetivoView

struct CalendarioLetivoView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var filtroCategoria: CategoriaEvento? = nil
    @State private var showAddEvento = false
    @State private var selectedEvento: EventoLetivo?

    private let eventos: [EventoLetivo] = EventoLetivo.demo

    private var eventosDoDia: [EventoLetivo] {
        let cal = Calendar.current
        return eventos.filter { evento in
            let matchData = cal.isDate(evento.data, inSameDayAs: selectedDate)
            let matchCategoria = filtroCategoria == nil || evento.categoria == filtroCategoria
            return matchData && matchCategoria
        }
    }

    private var eventoDoMes: [EventoLetivo] {
        let cal = Calendar.current
        return eventos.filter { evento in
            cal.isDate(evento.data, equalTo: currentMonth, toGranularity: .month)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        calendarioGrid
                        categoriasFiltro
                        eventosDoDiaSection
                        proximosEventos
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddEvento) {
                AddEventoView()
            }
            .sheet(item: $selectedEvento) { evento in
                EventoDetailView(evento: evento)
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Acadêmico",
            title: "Calendário Letivo",
            subtitle: "\(eventoDoMes.count) eventos este mês"
        ) {
            Button { showAddEvento = true } label: {
                Label("Novo Evento", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    private var calendarioGrid: some View {
        SchoolCard {
            VStack(spacing: 16) {
                monthNavigation
                weekdayHeaders
                daysGrid
            }
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
            }
            Spacer()
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
            Spacer()
            Button {
                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
            }
        }
    }

    private var weekdayHeaders: some View {
        HStack {
            ForEach(["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let days = daysInMonth(for: currentMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(for: day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let cal = Calendar.current
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(date)
        let hasEvento = eventos.contains { cal.isDate($0.data, inSameDayAs: date) }

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : isToday ? SchoolPalette.primary : SchoolPalette.primaryText)
                    .frame(width: 32, height: 32)
                    .background(
                        isSelected ? SchoolPalette.primary : isToday ? SchoolPalette.primary.opacity(0.12) : Color.clear,
                        in: Circle()
                    )
                if hasEvento {
                    Circle()
                        .fill(isSelected ? .white : SchoolPalette.primary)
                        .frame(width: 4, height: 4)
                }
            }
        }
    }

    private var categoriasFiltro: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Todos", color: SchoolPalette.secondaryText, isSelected: filtroCategoria == nil) {
                    filtroCategoria = nil
                }
                ForEach(CategoriaEvento.allCases, id: \.self) { cat in
                    filterChip(label: cat.rawValue, color: cat.color, isSelected: filtroCategoria == cat) {
                        filtroCategoria = filtroCategoria == cat ? nil : cat
                    }
                }
            }
        }
    }

    private func filterChip(label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1), in: Capsule())
        }
    }

    private var eventosDoDiaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDate, style: .date)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Spacer()
                Text("\(eventosDoDia.count) eventos")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }

            if eventosDoDia.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundStyle(SchoolPalette.secondaryText.opacity(0.5))
                    Text("Nenhum evento nesta data")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(eventosDoDia) { evento in
                    EventoCard(evento: evento)
                        .onTapGesture { selectedEvento = evento }
                }
            }
        }
    }

    private var proximosEventos: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Próximos Eventos")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)

            let proximos = eventos
                .filter { $0.data > Date() }
                .sorted { $0.data < $1.data }
                .prefix(5)

            ForEach(Array(proximos)) { evento in
                EventoCard(evento: evento)
                    .onTapGesture { selectedEvento = evento }
            }
        }
    }

    private func daysInMonth(for date: Date) -> [Date?] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: date),
              let firstWeekday = cal.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        let leadingBlanks = (firstWeekday - 1)
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - EventoCard

struct EventoCard: View {
    let evento: EventoLetivo

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4)
                .fill(evento.categoria.color)
                .frame(width: 4)
                .frame(minHeight: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label(evento.categoria.rawValue, systemImage: evento.categoria.symbol)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(evento.categoria.color)
                    Spacer()
                    Text(evento.data, style: .date)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
                Text(evento.titulo)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Text(evento.descricao)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SchoolPalette.outline))
    }
}

// MARK: - EventoDetailView

struct EventoDetailView: View {
    let evento: EventoLetivo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SchoolCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label(evento.categoria.rawValue, systemImage: evento.categoria.symbol)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(evento.categoria.color)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(evento.categoria.color.opacity(0.1), in: Capsule())
                                    Spacer()
                                }
                                Text(evento.titulo)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.primaryText)
                                Text(evento.descricao)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                Divider()
                                Label(evento.data.formatted(date: .long, time: .omitted), systemImage: "calendar")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                if !evento.turmas.isEmpty {
                                    Label(evento.turmas.joined(separator: ", "), systemImage: "person.3.fill")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .tint(SchoolPalette.primary)
                }
            }
        }
    }
}

// MARK: - AddEventoView

struct AddEventoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var titulo = ""
    @State private var descricao = ""
    @State private var data = Date()
    @State private var categoria = CategoriaEvento.academico
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        SchoolCard(title: "Novo Evento") {
                            VStack(spacing: 14) {
                                eventField("Título do Evento", placeholder: "Ex: Conselho de Classe", text: $titulo)
                                eventField("Descrição", placeholder: "Detalhes do evento...", text: $descricao)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Data")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                    DatePicker("", selection: $data, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(SchoolPalette.primary)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Categoria")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                    Picker("Categoria", selection: $categoria) {
                                        ForEach(CategoriaEvento.allCases, id: \.self) { cat in
                                            Text(cat.rawValue).tag(cat)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(SchoolPalette.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Button {
                            isSaving = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isSaving = false
                                dismiss()
                            }
                        } label: {
                            Text(isSaving ? "Salvando..." : "Adicionar Evento")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(titulo.isEmpty ? SchoolPalette.outline : SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 20)
                        }
                        .disabled(titulo.isEmpty || isSaving)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Novo Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .tint(SchoolPalette.secondaryText)
                }
            }
        }
    }

    private func eventField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(SchoolPalette.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SchoolPalette.outline))
        }
    }
}

// MARK: - Demo Data

extension EventoLetivo {
    static let demo: [EventoLetivo] = {
        let cal = Calendar.current
        let base = Date()
        func d(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: base) ?? base }
        return [
            EventoLetivo(id: "el-1", titulo: "Conselho de Classe", descricao: "Reunião pedagógica de avaliação bimestral.", data: d(2), dataFim: nil, categoria: .reuniao, turmas: ["1º Ano A", "2º Ano B"]),
            EventoLetivo(id: "el-2", titulo: "Prova de Matemática", descricao: "AV2 de Matemática para o 1º Ano A.", data: d(5), dataFim: nil, categoria: .prova, turmas: ["1º Ano A"]),
            EventoLetivo(id: "el-3", titulo: "Semana da Ciência", descricao: "Feira de ciências aberta à comunidade.", data: d(10), dataFim: d(12), categoria: .evento, turmas: ["Todas"]),
            EventoLetivo(id: "el-4", titulo: "Feriado Nacional", descricao: "Dia do Trabalhador.", data: d(19), dataFim: nil, categoria: .feriado, turmas: []),
            EventoLetivo(id: "el-5", titulo: "Encerramento do Bimestre", descricao: "Fechamento de notas e frequências.", data: d(25), dataFim: nil, categoria: .academico, turmas: ["Todas"]),
            EventoLetivo(id: "el-6", titulo: "Recesso Escolar", descricao: "Recesso de meio de ano.", data: d(30), dataFim: d(37), categoria: .recesso, turmas: []),
            EventoLetivo(id: "el-7", titulo: "Reunião de Pais", descricao: "Apresentação dos resultados do 1º bimestre.", data: d(-3), dataFim: nil, categoria: .reuniao, turmas: ["Todas"])
        ]
    }()
}

#Preview {
    CalendarioLetivoView()
}
