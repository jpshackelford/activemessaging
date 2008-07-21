class ProcessorStub < ActiveMessaging::BaseProcessor
  subscribes_to :hello_world
end