import KsApi
import Prelude
import ReactiveCocoa
import Result

public protocol ActivityUpdateViewModelInputs {
  /// Call to configure with the activity.
  func configureWith(activity activity: Activity)

  /// Call when the project image is tapped.
  func tappedProjectImage()
}

public protocol ActivityUpdateViewModelOutputs {
  /// Emits the update's body to be displayed.
  var body: Signal<String, NoError> { get }

  /// Emits the cell's accessibility label to be read by voiceover.
  var cellAccessibilityLabel: Signal<String, NoError> { get }

  /// Emits the cell's accessibility value to be read by voiceover.
  var cellAccessibilityValue: Signal<String, NoError> { get }

  /// Emits when we should notify the delegate that the project image button was tapped.
  var notifyDelegateTappedProjectImage: Signal<Activity, NoError> { get }

  /// Emits the project button's accessibility label to be read by voiceover.
  var projectButtonAccessibilityLabel: Signal<String, NoError> { get }

  /// Emits the project image URL to be displayed.
  var projectImageURL: Signal<NSURL?, NoError> { get }

  /// Emits the project name to be displayed.
  var projectName: Signal<String, NoError> { get }

  /// Emits the update sequence title to be displayed.
  var sequenceTitle: Signal<String, NoError> { get }

  /// Emits the timestamp to be displayed.
  var timestamp: Signal<String, NoError> { get }

  /// Emits the update title to be displayed.
  var title: Signal<String, NoError> { get }
}

public protocol ActivityUpdateViewModelType {
  var inputs: ActivityUpdateViewModelInputs { get }
  var outputs: ActivityUpdateViewModelOutputs { get }
}

public final class ActivityUpdateViewModel: ActivityUpdateViewModelType, ActivityUpdateViewModelInputs,
ActivityUpdateViewModelOutputs {

  public init() {
    let activity = self.activityProperty.signal.ignoreNil()
    let project = activity.map { $0.project }.ignoreNil()
    let update = activity.map { $0.update }.ignoreNil()

    self.body = update
      .map { $0.body?.htmlStripped()?.truncated(maxLength: 300) ?? "" }

    self.projectImageURL = project.map { $0.photo.med }.map(NSURL.init(string:))

    self.projectName = project.map { $0.name }
    self.projectButtonAccessibilityLabel = self.projectName

    self.title = update.map { $0.title }

    self.sequenceTitle = update
      .map { Strings.activity_project_update_update_count(update_count: Format.wholeNumber($0.sequence)) }

    self.timestamp = activity
      .map { Format.date(secondsInUTC: $0.createdAt, dateStyle: .MediumStyle, timeStyle: .NoStyle) }

    self.notifyDelegateTappedProjectImage = activity
      .takeWhen(self.tappedProjectImageProperty.signal)

    self.cellAccessibilityLabel = self.sequenceTitle
    self.cellAccessibilityValue = self.title
  }

  private let activityProperty = MutableProperty<Activity?>(nil)
  public func configureWith(activity activity: Activity) {
    self.activityProperty.value = activity
  }
  private let tappedProjectImageProperty = MutableProperty()
  public func tappedProjectImage() {
    self.tappedProjectImageProperty.value = ()
  }

  public let body: Signal<String, NoError>
  public let cellAccessibilityLabel: Signal<String, NoError>
  public let cellAccessibilityValue: Signal<String, NoError>
  public let notifyDelegateTappedProjectImage: Signal<Activity, NoError>
  public let projectButtonAccessibilityLabel: Signal<String, NoError>
  public let projectImageURL: Signal<NSURL?, NoError>
  public let projectName: Signal<String, NoError>
  public let sequenceTitle: Signal<String, NoError>
  public let timestamp: Signal<String, NoError>
  public let title: Signal<String, NoError>

  public var inputs: ActivityUpdateViewModelInputs { return self }
  public var outputs: ActivityUpdateViewModelOutputs { return self }
}
