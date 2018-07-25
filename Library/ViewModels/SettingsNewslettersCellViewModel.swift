import KsApi
import Prelude
import ReactiveSwift
import Result

public protocol SettingsNewslettersCellViewModelInputs {

  func allNewslettersSwitchTapped(on: Bool)
  func awakeFromNib()
  func configureWith(value: (newsletter: Newsletter, user: User))
  func newslettersSwitchTapped(on: Bool)
}

public protocol SettingsNewslettersCellViewModelOutputs {

  var showOptInPrompt: Signal<String, NoError> { get }
  var subscribeToAllSwitchIsOn: Signal<Bool?, NoError> { get }
  var switchIsOn: Signal<Bool?, NoError> { get }
  var unableToSaveError: Signal<String, NoError> { get }
  var updateCurrentUser: Signal<User, NoError> { get }
}

public protocol SettingsNewslettersCellViewModelType {

  var inputs: SettingsNewslettersCellViewModelInputs { get }
  var outputs: SettingsNewslettersCellViewModelOutputs { get }
}

public final class SettingsNewsletterCellViewModel: SettingsNewslettersCellViewModelType,
SettingsNewslettersCellViewModelInputs, SettingsNewslettersCellViewModelOutputs {

  public init() {

    let newsletter = self.newsletterProperty.signal.skipNil().take(first: 1)

    newsletter.signal.observeValues { v in
      print("\n\n\n===== NEWSLETTER! \(v) =====\n\n\n")
    }

    let initialUser = self.initialUserProperty.signal.skipNil().take(first: 1)

    initialUser.signal.observeValues { v in
      print("===== NEW USER! \(v.newsletters) =====")
    }

//    let initialUser = self.initialUserProperty.signal
//      .flatMap {
//        AppEnvironment.current.apiService.fetchUserSelf()
//          .wrapInOptional()
//          .prefix(value: AppEnvironment.current.currentUser)
//          .demoteErrors()
//      }
//      .skipNil()
//      .skipRepeats()

    let newsletterOn: Signal<(Newsletter, Bool), NoError> = newsletter
      .takePairWhen(self.newslettersSwitchTappedProperty.signal.skipNil())
      .map { newsletter, isOn in (newsletter, isOn) }

    self.showOptInPrompt = newsletterOn
      .filter { _, on in AppEnvironment.current.config?.countryCode == "DE" && on }
      .map { newsletter, _ in newsletter.displayableName }

    let userAttributeChanged: Signal<(UserAttribute, Bool), NoError> = Signal.combineLatest(
        newsletter,
        self.newslettersSwitchTappedProperty.signal.skipNil()
    ).map { newsletter, isOn in
      (UserAttribute.newsletter(newsletter), isOn)
    }

    let updatedUser = initialUser
      .switchMap { user in
        userAttributeChanged.scan(user) { user, attributeAndOn in
          let (attribute, on) = attributeAndOn
          return user |> attribute.lens .~ on
        }
    }

    let updateUserAllOn = initialUser
      .takePairWhen(self.allNewslettersSwitchProperty.signal.skipNil())
      .map { user, on in
        return user
          |> User.lens.newsletters .~ User.NewsletterSubscriptions.all(on: on)
    }

    let updateEvent = Signal.merge(updatedUser, updateUserAllOn)
      .switchMap {
        AppEnvironment.current.apiService.updateUserSelf($0)
          .ksr_delay(AppEnvironment.current.apiDelayInterval, on: AppEnvironment.current.scheduler)
          .materialize()
    }

    self.unableToSaveError = updateEvent.errors()
      .map { env in
        env.errorMessages.first ?? Strings.profile_settings_error()
      }

    let previousUserOnError = Signal.merge(initialUser, updatedUser, updateUserAllOn)
      .combinePrevious()
      .takeWhen(self.unableToSaveError)
      .map { previous, _ in previous }

    self.updateCurrentUser = Signal.merge(initialUser, updatedUser, updateUserAllOn, previousUserOnError)

    self.subscribeToAllSwitchIsOn = self.updateCurrentUser
      .map(userIsSubscribedToAll(user:))

    self.switchIsOn = self.updateCurrentUser
      .combineLatest(with: newsletter)
      .map(userIsSubscribed(user:newsletter:))

    // Koala
    userAttributeChanged
      .observeValues { attribute, on in
        switch attribute {
        case let .newsletter(newsletter):
          AppEnvironment.current.koala.trackChangeNewsletter(
            newsletterType: newsletter, sendNewsletter: on, project: nil, context: .settings
          )
        default: break
      }
    }
  }

  fileprivate let awakeFromNibProperty = MutableProperty(())
  public func awakeFromNib() {
    self.awakeFromNibProperty.value = ()
  }

  fileprivate let initialUserProperty = MutableProperty<User?>(nil)
  fileprivate let newsletterProperty = MutableProperty<Newsletter?>(nil)
  public func configureWith(value: (newsletter: Newsletter, user: User)) {
    self.newsletterProperty.value = value.newsletter
    self.initialUserProperty.value = value.user
  }

  fileprivate let newslettersSwitchTappedProperty = MutableProperty<Bool?>(nil)
  public func newslettersSwitchTapped(on: Bool) {
    self.newslettersSwitchTappedProperty.value = on
  }

  fileprivate let allNewslettersSwitchProperty = MutableProperty<Bool?>(nil)
  public func allNewslettersSwitchTapped(on: Bool) {
    self.allNewslettersSwitchProperty.value = on
  }

  public let showOptInPrompt: Signal<String, NoError>
  public let subscribeToAllSwitchIsOn: Signal<Bool?, NoError>
  public let switchIsOn: Signal<Bool?, NoError>
  public let unableToSaveError: Signal<String, NoError>
  public let updateCurrentUser: Signal<User, NoError>

  public var inputs: SettingsNewslettersCellViewModelInputs { return self }
  public var outputs: SettingsNewslettersCellViewModelOutputs { return self }
}

private func userIsSubscribedToAll(user: User) -> Bool? {

  return user.newsletters.arts == true
    && user.newsletters.games == true
    && user.newsletters.happening == true
    && user.newsletters.invent == true
    && user.newsletters.promo == true
    && user.newsletters.weekly == true
    && user.newsletters.films == true
    && user.newsletters.publishing == true
    && user.newsletters.alumni == true
}

private func userIsSubscribed(user: User, newsletter: Newsletter) -> Bool? {
  switch newsletter {
  case .arts:
    return user.newsletters.arts
  case .games:
    return user.newsletters.games
  case .happening:
    return user.newsletters.happening
  case .invent:
    return user.newsletters.invent
  case .promo:
    return user.newsletters.promo
  case .weekly:
    return user.newsletters.weekly
  case .films:
    return user.newsletters.films
  case .publishing:
    return user.newsletters.publishing
  case .alumni:
    return user.newsletters.alumni
  }
}
