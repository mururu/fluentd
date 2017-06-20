#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'cool.io'
require 'yajl'

require 'fluent/input'
require 'fluent/config/error'
require 'fluent/parser'

module Fluent
  class SyslogInput < Input
    Plugin.register_input('syslog', self)

    SYSLOG_REGEXP = /^\<([0-9]+)\>(.*)/

    FACILITY_MAP = {
      0   => 'kern',
      1   => 'user',
      2   => 'mail',
      3   => 'daemon',
      4   => 'auth',
      5   => 'syslog',
      6   => 'lpr',
      7   => 'news',
      8   => 'uucp',
      9   => 'cron',
      10  => 'authpriv',
      11  => 'ftp',
      12  => 'ntp',
      13  => 'audit',
      14  => 'alert',
      15  => 'at',
      16  => 'local0',
      17  => 'local1',
      18  => 'local2',
      19  => 'local3',
      20  => 'local4',
      21  => 'local5',
      22  => 'local6',
      23  => 'local7'
    }

    PRIORITY_MAP = {
      0  => 'emerg',
      1  => 'alert',
      2  => 'crit',
      3  => 'err',
      4  => 'warn',
      5  => 'notice',
      6  => 'info',
      7  => 'debug'
    }

    def initialize
      super
      require 'fluent/plugin/socket_util'
    end

    desc 'The port to listen to.'
    config_param :port, :integer, default: 5140
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'
    desc 'The prefix of the tag. The tag itself is generated by the tag prefix, facility level, and priority.'
    config_param :tag, :string
    desc 'The transport protocol used to receive logs.(udp, tcp)'
    config_param :protocol_type, default: :udp do |val|
      case val.downcase
      when 'tcp'
        :tcp
      when 'udp'
        :udp
      else
        raise ConfigError, "syslog input protocol type should be 'tcp' or 'udp'"
      end
    end
    desc 'If true, add source host to event record.'
    config_param :include_source_host, :bool, default: false, deprecated: "use source_hostname_key instead"
    desc 'Specify key of source host when include_source_host is true.'
    config_param :source_host_key, :string, default: 'source_host'.freeze, deprecated: "use source_hostname_key instead"
    desc "The field name of the client's hostname."
    config_param :source_hostname_key, :string, default: nil
    desc 'The field name of the priority.'
    config_param :priority_key, :string, default: nil
    desc 'The field name of the facility.'
    config_param :facility_key, :string, default: nil
    desc "The max bytes of message"
    config_param :message_length_limit, :size, default: 2048
    config_param :blocking_timeout, :time, default: 0.5

    config_param :allow_without_pri, :bool, default: false
    config_param :default_pri, type: :integer, default: 13 # 13 is the default value of rsyslog and syslog-ng

    def configure(conf)
      super

      if @default_pri < 0 || @default_pri > 255
        raise ConfigError, "syslog default pri should be 0 ~ 255"
      end

      if conf.has_key?('format')
        @parser = Plugin.new_parser(conf['format'])
        @parser.configure(conf)
      else
        ## This is confusing when config dump
        conf['without_priority'] = false
        @parser = TextParser::SyslogParser.new
        @parser.configure(conf)
      end

      if @source_hostname_key.nil? && @include_source_host
        @source_hostname_key = @source_host_key
      end
    end

    def start
      @loop = Coolio::Loop.new
      @handler = listen(method(:receive_data))
      @loop.attach(@handler)

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      @loop.watchers.each {|w| w.detach }
      @loop.stop
      @handler.close
      @thread.join
    end

    def run
      @loop.run(@blocking_timeout)
    rescue
      log.error "unexpected error", error: $!.to_s
      log.error_backtrace
    end

    private

    def receive_data(data, addr)
      m = SYSLOG_REGEXP.match(data)
      if m
        pri = m[1].to_i
        text = m[2]
      else
        if @allow_without_pri
          pri = @default_pri
          text = data
        else
          log.warn "invalid syslog message: #{data.dump}"
          return
        end
      end

      @parser.parse(text) { |time, record|
        unless time && record
          log.warn "pattern not match: #{text.inspect}"
          return
        end

        facility = FACILITY_MAP[pri >> 3]
        priority = PRIORITY_MAP[pri & 0b111]

        record[@priority_key] = priority if @priority_key
        record[@facility_key] = facility if @facility_key
        record[@source_hostname_key] = addr[2] if @source_hostname_key

        tag = "#{@tag}.#{facility}.#{priority}"
        emit(tag, time, record)
      }
    rescue => e
      log.error data.dump, error: e.to_s
      log.error_backtrace
    end

    private

    def listen(callback)
      log.info "listening syslog socket on #{@bind}:#{@port} with #{@protocol_type}"
      if @protocol_type == :udp
        @usock = SocketUtil.create_udp_socket(@bind)
        @usock.bind(@bind, @port)
        SocketUtil::UdpHandler.new(@usock, log, @message_length_limit, callback, !!@source_hostname_key)
      else
        # syslog family add "\n" to each message and this seems only way to split messages in tcp stream
        Coolio::TCPServer.new(@bind, @port, SocketUtil::TcpHandler, log, "\n", callback, !!@source_hostname_key)
      end
    end

    def emit(tag, time, record)
      router.emit(tag, time, record)
    rescue => e
      log.error "syslog failed to emit", error: e.to_s, error_class: e.class.to_s, tag: tag, record: Yajl.dump(record)
    end
  end
end
