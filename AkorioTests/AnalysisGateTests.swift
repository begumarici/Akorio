import Foundation
import Testing
@testable import Akorio

struct AnalysisGateTests {
    @Test("The gate admits one caller until it is released")
    func admitsOneAtATime() {
        let gate = AnalysisGate()

        #expect(gate.tryEnter())
        #expect(!gate.tryEnter())

        gate.leave()
        #expect(gate.tryEnter())
    }

    @Test("Releasing an open gate is harmless")
    func leaveWhenOpen() {
        let gate = AnalysisGate()

        gate.leave()

        #expect(gate.tryEnter())
    }

    @Test("Only one of many simultaneous callers gets in")
    func singleWinnerUnderContention() {
        let gate = AnalysisGate()
        let winners = Winners()

        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
            if gate.tryEnter() { winners.add() }
        }

        #expect(winners.count == 1)
    }
}

private final class Winners: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func add() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
