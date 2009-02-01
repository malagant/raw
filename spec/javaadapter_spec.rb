require File.dirname(__FILE__) + '/spec_helper'

describe RAW::RjbAdapter do

  it "should extract the Java class name from a string" do
    RAW::RjbAdapter.extract_class_name("java.lang.String").should eql("String")
    RAW::RjbAdapter.extract_class_name("Foo").should eql("Foo")
    RAW::RjbAdapter.extract_class_name("java.lang.__String").should eql("__String")
    RAW::RjbAdapter.extract_class_name("java.lang.Outer$Inner").should eql("Outer$Inner")
  end

  it "should import a class" do
    result = RAW::RjbAdapter.import_class("java.lang.String")
    result.should_not be_nil
    result.should respond_to(:new)
  end
end