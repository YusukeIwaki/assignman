class BaseUseCase
  class Error < StandardError; end
  class ValidationError < Error; end
  class AuthorizationError < Error; end
  class NotFoundError < Error; end

  def self.call(*, **)
    new.call(*, **)
  end

  protected

  def success(data = nil)
    OpenStruct.new(success?: true, failure?: false, data: data, error: nil)
  end

  def failure(error)
    OpenStruct.new(success?: false, failure?: true, data: nil, error: error)
  end
end
