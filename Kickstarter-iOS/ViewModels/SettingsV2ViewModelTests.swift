import Prelude
import XCTest
import Result
@testable import KsApi
@testable import Kickstarter_Framework
@testable import ReactiveExtensions_TestHelpers

internal final class SettingsV2ViewModelTests: TestCase {
  let vm = SettingsV2ViewModel()

  let logout = TestObserver<DiscoveryParams, NoError>()
  let transitionToViewController = TestObserver<UIViewController, NoError>()
  let goToAppStoreRating = TestObserver<String, NoError>()
  let reloadData = TestObserver<Void, NoError>()
  let showConfirmLogout = TestObserver<Void, NoError>()

  internal override func setUp() {
    super.setUp()

    self.vm.outputs.logoutWithParams.observe(logout.observer)
    self.vm.outputs.transitionToViewController.observe(transitionToViewController.observer)
    self.vm.outputs.goToAppStoreRating.observe(goToAppStoreRating.observer)
    self.vm.outputs.reloadData.observe(reloadData.observer)
    self.vm.outputs.showConfirmLogoutPrompt.signal.mapConst(()).observe(showConfirmLogout.observer)
  }

  func testLogoutCellTapped() {
    self.showConfirmLogout.assertValueCount(0)
    self.logout.assertValueCount(0)
    self.vm.settingsCellTapped(cellType: .logout)

    self.showConfirmLogout.assertValueCount(1, "Shows confirm logout alert.")

    self.vm.inputs.logoutCanceled()

    self.logout.assertValueCount(0, "Logout cancelled")

    self.vm.settingsCellTapped(cellType: .logout)

    self.showConfirmLogout.assertValueCount(2, "Show confirm logout alert")
    self.vm.inputs.logoutConfirmed()

    self.logout.assertValueCount(1, "Log out triggered")
  }

  func testNotificationsCellTapped() {
    self.transitionToViewController.assertValueCount(0)
    self.vm.settingsCellTapped(cellType: .notifications)
    self.transitionToViewController.assertValueCount(1)
  }

  func testCellSelection() {
    XCTAssertFalse(self.vm.shouldSelectRow(for: .appVersion))
    XCTAssertTrue(self.vm.shouldSelectRow(for: .newsletters))
  }

  func testAppStoreRatingCellTapped() {
    self.goToAppStoreRating.assertValueCount(0)
    self.vm.settingsCellTapped(cellType: .rateInAppStore)
    self.goToAppStoreRating.assertValueCount(1, "Opens app store url")
  }
}
