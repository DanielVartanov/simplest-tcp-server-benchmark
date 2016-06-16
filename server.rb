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
    server_socket = TCPServer.new '', 2000

    benchmarker.tap do
      10000.times do
        client_socket = server_socket.accept

        benchmarker.measure do
          client_socket.puts Time.now
        end

        client_socket.close
      end
    end
  end
end

puts SingleThreadedServer.new(ServerBenchmarker.new).benchmark!
