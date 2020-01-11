# frozen_string_literal: true

require 'test_helper'

describe PPP do
  it 'has a version number' do
    refute_nil ::PPP::VERSION
  end

  it "doesn't explode" do
    def some_method(arg)
      ppp
    end

    some_method 'hi'
  end
end
