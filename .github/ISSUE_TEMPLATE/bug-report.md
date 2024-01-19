---
name: Bug Report
about: Create a bug report
title: "Issue title goes here"
labels: "🐞 Issue: Bug"
assignees: ''

---

## Describe the bug
A clear and concise description of what the bug is.

## To Reproduce
Describe a way to reproduce your bug. To get the gem version, run `BakingRack::VERSION`.

Use the reproduction script below to reproduce the issue:

```
# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "baking_rack", git: "https://github.com/dcunning/baking_rack.git", branch: "main"
  gem "minitest"
end

require "minitest/autorun"

class BugTest < Minitest::Test
  def test_some_failure
    # CHANGEME - Reproduce the issue here.
  end
end

```

## Expected behavior
A clear and concise description of what you expected to happen.

## Additional context
Add any other additional information about the problem here.
