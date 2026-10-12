import SwiftUI
import Foundation

struct NotaArithmeticAdjustmentSession: Identifiable {
    let id = UUID()
    let blocks: [NotaArithmeticAdjustmentBlock]
}

struct NotaArithmeticAdjustmentBlock: Identifiable {
    struct Operand: Identifiable {
        let id: UUID
        var value: Double
        var range: NSRange
        var usesDecimalSeparator: Bool
    }

    let id: UUID
    let sourceItemID: String?
    let contextSnippet: String?
    var expression: String
    var operands: [Operand]

    init(
        id: UUID = UUID(),
        sourceItemID: String? = nil,
        contextSnippet: String? = nil,
        expression: String
    ) {
        self.id = id
        self.sourceItemID = sourceItemID
        self.contextSnippet = contextSnippet
        self.expression = expression
        self.operands = []
        refreshOperands()
    }

    mutating func updateExpression(_ newValue: String) {
        expression = newValue
        refreshOperands()
    }

    mutating func updateOperand(id operandID: UUID, value: Double) {
        guard let operandIndex = operands.firstIndex(where: { $0.id == operandID }),
              let expressionRange = Range(operands[operandIndex].range, in: expression) else {
            return
        }

        let replacement = Self.format(
            value,
            usesDecimalSeparator: operands[operandIndex].usesDecimalSeparator
        )
        expression.replaceSubrange(expressionRange, with: replacement)
        refreshOperands()
    }

    private mutating func refreshOperands() {
        let previousOperands = operands
        let pattern = #"(?:[0-9]+(?:[\.,][0-9]+)?|[\.,][0-9]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            operands = []
            return
        }

        let fullRange = NSRange(expression.startIndex..<expression.endIndex, in: expression)
        operands = regex.matches(in: expression, range: fullRange).enumerated().compactMap { index, match in
            guard let range = Range(match.range, in: expression) else { return nil }
            let token = String(expression[range])
            let normalizedToken = token.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalizedToken) else { return nil }

            let previousID = previousOperands.indices.contains(index)
                ? previousOperands[index].id
                : UUID()
            return Operand(
                id: previousID,
                value: value,
                range: match.range,
                usesDecimalSeparator: token.contains(".") || token.contains(",")
            )
        }
    }

    private static func format(_ value: Double, usesDecimalSeparator: Bool) -> String {
        if !usesDecimalSeparator, value.rounded() == value {
            return String(Int(value))
        }

        let formatted = value.formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...4))
        )
        return formatted
    }
}

struct NotaArithmeticAdjusterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blocks: [NotaArithmeticAdjustmentBlock]

    let onSave: ([NotaArithmeticAdjustmentBlock]) -> Void

    init(
        blocks: [NotaArithmeticAdjustmentBlock],
        onSave: @escaping ([NotaArithmeticAdjustmentBlock]) -> Void
    ) {
        _blocks = State(initialValue: blocks)
        self.onSave = onSave
    }

    private var canSave: Bool {
        !blocks.isEmpty
            && blocks.allSatisfy {
                !$0.operands.isEmpty
                    && NotaArithmeticCalculation.isValidExpression($0.expression)
            }
    }

    private var formattedTotal: String? {
        NotaArithmeticCalculation.formattedTotal(for: blocks.map(\.expression))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach($blocks) { $block in
                        ArithmeticBlockAdjustmentCard(block: $block)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Cancelar", role: .cancel) {
                    dismiss()
                }

                Spacer()

                Button("Guardar") {
                    onSave(blocks)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(!canSave)
            }
            .padding(16)
        }
        .frame(
            minWidth: 320,
            idealWidth: 520,
            maxWidth: 560,
            minHeight: 420,
            idealHeight: 560,
            maxHeight: 650
        )
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "dial.medium")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 38, height: 38)
                .background(.tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Ajustar valores")
                    .font(.headline)
                if let formattedTotal {
                    Text("\(blocks.count) bloque(s) · Suma total: \(formattedTotal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(blocks.count) bloque(s) aritmético(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .padding(8)
                    .background(.secondary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar")
        }
        .padding(16)
    }
}

private struct ArithmeticBlockAdjustmentCard: View {
    @Binding var block: NotaArithmeticAdjustmentBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if let contextSnippet = block.contextSnippet {
                    Text(verbatim: contextSnippet)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(-1)
                        .accessibilityLabel("Elemento: \(contextSnippet)")
                } else {
                    Text("Inicio del texto")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let result = NotaArithmeticCalculation.formattedResult(for: block.expression) {
                    Text("= \(result)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .accessibilityLabel("Resultado \(result)")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Expresión no válida")
                }
            }

            HStack(spacing: 0) {
                Text("=")
                    .font(.title3.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Expresión",
                    text: Binding(
                        get: { block.expression },
                        set: { block.updateExpression($0) }
                    )
                )
                .font(.title3.monospaced())
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(0)
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 11))
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .stroke(.secondary.opacity(0.22), lineWidth: 1)
            }

            if block.operands.isEmpty {
                Label("Añade al menos un valor numérico.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 18) {
                        ForEach(Array(block.operands.enumerated()), id: \.element.id) { index, operand in
                            ArithmeticOperandWheel(
                                title: "Operando \(index + 1)",
                                value: Binding(
                                    get: {
                                        block.operands.first(where: { $0.id == operand.id })?.value
                                            ?? operand.value
                                    },
                                    set: { block.updateOperand(id: operand.id, value: $0) }
                                ),
                                step: operand.usesDecimalSeparator ? 0.1 : 1
                            )
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .scrollIndicators(.hidden)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.secondary.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

private struct ArithmeticOperandWheel: View {
    let title: String
    @Binding var value: Double
    let step: Double

    private var selectedTick: Binding<Int> {
        Binding(
            get: { Int((value / step).rounded()) },
            set: { value = Double($0) * step }
        )
    }

    private var maximumTick: Int {
        let currentTick = Int((value / step).rounded())
        let defaultMaximum = step < 1 ? 10_000 : 1_000
        return max(defaultMaximum, currentTick + 100)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker(title, selection: selectedTick) {
                ForEach(0...maximumTick, id: \.self) { tick in
                    Text(formattedValue(for: tick))
                        .font(.body.monospacedDigit())
                        .tag(tick)
                }
            }
            .labelsHidden()
#if os(macOS)
            .pickerStyle(.inline)
#else
            .pickerStyle(.wheel)
#endif
            .frame(width: 112, height: 112)
            .clipped()
            .accessibilityLabel(title)
        }
        .frame(width: 116)
    }

    private func formattedValue(for tick: Int) -> String {
        let tickValue = Double(tick) * step
        return tickValue.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(step < 1 ? 1 : 0))
        )
    }
}
