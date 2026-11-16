# frozen_string_literal: true

# The local Rails port. Development reads PORT (each checkout sets its own in .envrc so
# several apps can run side by side); every other environment keeps the fixed 3000 contract so
# tests do not depend on which checkout they run in.
module DevelopmentPort
  DEFAULT = "3000"

  module_function

  def value
    return DEFAULT unless defined?(Rails) && Rails.env.development?

    port = ENV.fetch("PORT", DEFAULT).to_s
    port.match?(/\A\d+\z/) ? port : DEFAULT
  end
end
