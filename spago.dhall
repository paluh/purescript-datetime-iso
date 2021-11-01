{ name = "datetime-iso"
, dependencies =
  [ "argonaut"
  , "console"
  , "datetime"
  , "effect"
  , "newtype"
  , "parsing"
  , "prelude"
  , "psci-support"
  , "spec"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
