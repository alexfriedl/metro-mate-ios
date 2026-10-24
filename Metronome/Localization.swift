import Foundation

extension String {
    // Values that are stored or compared stay English, the string catalog translates them only when shown
    var localizedForDisplay: String {
        Bundle.main.localizedString(forKey: self, value: nil, table: nil)
    }
}
