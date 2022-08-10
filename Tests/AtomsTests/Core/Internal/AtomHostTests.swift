import XCTest

@testable import Atoms

@MainActor
final class AtomHostTests: XCTestCase {
    func testCast() {
        let host: AtomHostBase = AtomHost<ValueAtomState<Int>>()
        XCTAssertNotNil(host as? AtomHost<ValueAtomState<Int>>)
    }

    func testRelationship() {
        let host = AtomHost<ValueAtomState<Int>>()
        let atom = TestValueAtom(value: 0)
        var isTerminated = false

        host.relationship[atom] = Relation(retaining: AtomHostBase()) {
            isTerminated = true
        }

        XCTAssertNotNil(host.relationship[atom])

        host.relationship[atom] = nil

        XCTAssertTrue(isTerminated)
        XCTAssertNil(host.relationship[atom])
    }

    func testAddTermination() {
        var host: AtomHost<ValueAtomState<Int>>? = AtomHost()
        var isTerminated = false

        host?.addTermination {
            isTerminated = true
        }

        host = nil

        XCTAssertTrue(isTerminated)
    }

    func testNotifyUpdate() {
        let host = AtomHost<ValueAtomState<Int>>()
        var isUpdated = false

        host.state = ValueAtomState { _ in 0 }
        host.onUpdate = { _ in
            isUpdated = true
        }

        host.notifyUpdate()

        XCTAssertTrue(isUpdated)
    }

    func testWithTermination() {
        var host: AtomHost<ValueAtomState<Int>>? = AtomHost()
        weak var weakHost = host
        let atom = TestValueAtom(value: 0)
        var isTerminated = false
        var isRelationPurged = false

        host?.addTermination {
            isTerminated = true
        }

        host?.relationship[atom] = Relation(retaining: AtomHostBase()) {
            isRelationPurged = true
        }

        host?.withTermination { _ in
            host = nil

            XCTAssertNil(weakHost?.state)
            XCTAssertNotNil(weakHost)
            XCTAssertTrue(isTerminated)
            XCTAssertFalse(isRelationPurged)
        }

        XCTAssertNil(weakHost)
        XCTAssertTrue(isRelationPurged)
    }

    func testWithAsyncTermination() async {
        var host: AtomHost<ValueAtomState<Int>>? = AtomHost()
        weak var weakHost = host
        let atom = TestValueAtom(value: 0)
        var isTerminated = false
        var isRelationPurged = false

        host?.addTermination {
            isTerminated = true
        }

        host?.relationship[atom] = Relation(retaining: AtomHostBase()) {
            isRelationPurged = true
        }

        await host?.withAsyncTermination { _ in
            host = nil

            await Task {}.value

            XCTAssertNil(weakHost?.state)
            XCTAssertNotNil(weakHost)
            XCTAssertTrue(isTerminated)
            XCTAssertFalse(isRelationPurged)
        }

        XCTAssertNil(weakHost)
        XCTAssertTrue(isRelationPurged)
    }

    func testObserve() {
        var host: AtomHost<ValueAtomState<Int>>? = AtomHost()
        weak var weakHost = host
        var receiveCount = 0

        var relation: Relation? = host?.observe {
            receiveCount += 1
        }

        host?.notifyUpdate()

        XCTAssertNotNil(weakHost)
        XCTAssertEqual(receiveCount, 1)

        host = nil
        weakHost?.notifyUpdate()

        XCTAssertNotNil(weakHost)
        XCTAssertEqual(receiveCount, 2)

        relation = nil
        weakHost?.notifyUpdate()

        XCTAssertNil(relation)
        XCTAssertNil(weakHost)
        XCTAssertEqual(receiveCount, 2)
    }
}
