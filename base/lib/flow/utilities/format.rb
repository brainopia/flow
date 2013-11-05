module Flow::Utilities
  module Format
    extend self

    def pretty_name(target)
      target.name
        .gsub('::', '_')
        .gsub(/([^_])([A-Z])/,'\1_\2')
        .downcase
        .gsub(/^flow_(action_|directive_)?/, '')
    end
  end
end
