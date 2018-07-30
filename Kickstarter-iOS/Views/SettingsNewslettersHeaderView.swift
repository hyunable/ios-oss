import KsApi
import Library
import Prelude
import UIKit

final internal class SettingsNewslettersHeaderView: UITableViewCell, ValueCell {

  private let viewModel: SettingsNewslettersCellViewModelType = SettingsNewsletterCellViewModel()

  @IBOutlet fileprivate weak var descriptionLabel: UILabel!
  @IBOutlet fileprivate weak var newsletterSwitch: UISwitch!
  @IBOutlet fileprivate weak var titleLabel: UILabel!

  @IBOutlet fileprivate var separatorViews: [UIView]!

  public weak var delegate: SettingsNewslettersCellDelegate?

  func configureWith(value: User) {
      self.viewModel.inputs.configureWith(value: value)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.viewModel.inputs.awakeFromNib()
  }

  override func bindStyles() {
    super.bindStyles()

    _ = self.descriptionLabel
      |> settingsSectionLabelStyle
      |> UILabel.lens.font .~ .ksr_body(size: 13)
      |> UILabel.lens.numberOfLines .~ 0
      |> UILabel.lens.textColor .~ .ksr_dark_grey_400
      |> UILabel.lens.text %~ { _ in
        Strings.Stay_up_to_date_newsletter()
    }

    _ = self.newsletterSwitch
      |> UISwitch.lens.onTintColor .~ .ksr_green_700

    _ = self.separatorViews
      ||> separatorStyle

    _ = self.titleLabel
      |> settingsSectionLabelStyle
      |> UILabel.lens.text %~ { _ in Strings.profile_settings_newsletter_subscribe_all() }
  }

  override func bindViewModel() {
    super.bindViewModel()

    self.viewModel.outputs.updateCurrentUser
      .observeForUI()
      .observeValues { [weak self] in
        self?.delegate?.didUpdate(user: $0)
    }

    self.newsletterSwitch.rac.on = self.viewModel.outputs.subscribeToAllSwitchIsOn.skipNil()
  }

  @IBAction func newsletterSwitchTapped(_ sender: UISwitch) {
    self.viewModel.inputs.allNewslettersSwitchTapped(on: sender.isOn)
  }
}
