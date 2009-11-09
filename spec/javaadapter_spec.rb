require File.dirname(__FILE__) + '/spec_helper'

describe JRAW::RjbAdapter do

  it "should extract the Java class name from a string" do
    JRAW::RjbAdapter.extract_class_name("java.lang.String").should eql("String")
    JRAW::RjbAdapter.extract_class_name("Foo").should eql("Foo")
    JRAW::RjbAdapter.extract_class_name("java.lang.__String").should eql("__String")
    JRAW::RjbAdapter.extract_class_name("java.lang.Outer$Inner").should eql("Outer$Inner")
  end

  it "should import a class" do
    result = JRAW::RjbAdapter.import_class("java.lang.String")
    result.should_not be_nil
    result.should respond_to(:new)
  end
end