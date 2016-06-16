require 'socket'
require 'descriptive_statistics'

class ServerBenchmarker
  def initialize
    self.reversed_request_durations = []
  end

  def measure
    start_time = Time.now
    yield
    reversed_request_durations << 1.0 / (Time.now - start_time)
  end

  def mean_value
    reversed_request_durations.mean
  end

  def standard_deviation
    reversed_request_durations.standard_deviation
  end

  def to_s
    """
      mean value: #{'%.01f' % mean_value} req/s
      stddev: #{'%.01f' % standard_deviation}
    """
  end

  private

  attr_accessor :reversed_request_durations
end

class SingleThreadedServer < Struct.new(:benchmarker)
  def benchmark!
    connections.map do |client_socket|
      benchmarker.measure do
        client_socket.puts Time.now
      end
      client_socket.close
    end.first(1000)
  end

  private

  def connections
    Enumerator.new do |yielder|
      loop { yielder.yield server_socket.accept }
    end.lazy
  end

  def server_socket
    @server_socket ||= TCPServer.new '', 2000
  end
end


ServerBenchmarker.new.tap do |benchmarker|
  SingleThreadedServer.new(benchmarker).benchmark!
  puts benchmarker
end
