require 'rails_helper'

# Controller specs are deprecated in Rails 8. This functionality is comprehensively tested
# in request specs (spec/requests/checkout_spec.rb) and integration specs
# (spec/integration/controllers_bug_detection_spec.rb and spec/integration/full_application_spec.rb)
# which provide better coverage and are the recommended approach for modern Rails applications.

RSpec.describe CheckoutController, type: :controller do
  xit 'is covered by request and integration specs' do
    # Controller specs deprecated in Rails 8. See request and integration specs for coverage.
  end
end
