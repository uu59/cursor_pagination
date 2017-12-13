
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "cursor_pagination"
  spec.version       = "1.0.0"
  spec.authors       = ["crzrcn"]
  spec.email         = ["fernanlink@gmail.com"]

  spec.summary       = %q{ Write a short summary, because RubyGems requires one.}
  spec.description   = %q{ Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/crzrcn/cursor_pagination"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = "MPL-2.0"

  spec.add_dependency "activerecord", "~> 5.1"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "mysql2", "~> 0.4"
  spec.add_development_dependency "pry-byebug", "~> 3.5"
end
