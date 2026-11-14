import Testing
@testable import Akorio

@MainActor
struct AppRouterTests {
    @Test("Navigation helpers push screens in order")
    func pushesScreens() {
        let router = AppRouter()

        router.goToSettings()
        router.goToSaved()

        #expect(router.path == [.settings, .saved])
    }

    @Test("Going back pops one screen at a time")
    func goBackPopsOne() {
        let router = AppRouter()
        router.goToSettings()
        router.goToSaved()

        router.goBack()

        #expect(router.path == [.settings])
    }

    @Test("Returning to the root fires the callback, however the path changed")
    func returnedHomeCallback() {
        let router = AppRouter()
        var callCount = 0
        router.onReturnedHome = { callCount += 1 }

        router.goToSettings()
        router.path = []          // what the swipe-back gesture does
        router.goBack()           // already at root: nothing happens

        #expect(callCount == 1)
    }

    @Test("Moving between pushed screens does not fire the callback")
    func noCallbackWhileDeep() {
        let router = AppRouter()
        var callCount = 0
        router.onReturnedHome = { callCount += 1 }

        router.goToSettings()
        router.goToSaved()
        router.goBack()

        #expect(callCount == 0)
    }

    @Test("Only the practice plan screen is popped by popPracticePlan")
    func popsOnlyPracticePlan() {
        let router = AppRouter()
        router.goToSettings()

        router.popPracticePlan()
        #expect(router.path == [.settings])

        router.goToPracticePlan()
        router.popPracticePlan()
        #expect(router.path == [.settings])
    }

    @Test("goHome selects the Home tab and clears the stack")
    func goHome() {
        let router = AppRouter()
        router.selectedTab = .tuner
        router.goToSettings()

        router.goHome()

        #expect(router.selectedTab == .home)
        #expect(router.path.isEmpty)
    }
}
