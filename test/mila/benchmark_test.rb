require 'test_helper'

module Mila
  module Benchmark
    class BenchmarkTest < Minitest::Test
      include Support::Fixtures

      def test_json_parse
        assert true
      end

      def test_another_json
        json = load_fixture('json_1.json', format: :string)
        tests = lambda do |x|
          mila_json = Mila::JSON::Parser.new(:multi_json)
          mila_default = Mila::JSON::Parser.new(:default)
          x.report('json') do
            ::JSON.parse(json, symbolize_names: true)
          end

          x.report 'mila default' do
            mila_default.parse(json)
          end

          x.report('mila simple json') do
            Mila::JSON.parse(json)
          end

          x.report('mila json') do
            mila_json.parse(json)
          end

          x.report('multijson') do
            MultiJson.load(json, symbolize_keys: true)
          end

          x.report('oj') do
            Oj.load(json, symbol_keys: true)
          end
        end

        Benchmark.ips(name: 'standard', &tests)

        RubyVM::YJIT.enable

        Benchmark.ips(name: 'yjit', &tests)
      end

      def test_id
        json_file = Pathname('test.json')
        string = json_file.open { |f| f.readline }
        hash = JSON.parse(string, symbolize_names: true)
        puts create_session.call(:getId, hash)
      end

      def create_session
        session = V8Session.new
        session.eval_inline do
          <<~JS
             function parseJson(string) {
               return JSON.parse(string)
             }
            #{' '}
             function getIdFromString(string) {
               var obj = parseJson(string)

            }#{' '}
            function getId(obj) {
              return obj.id
            }
          JS
        end
        session
        # result = session.call(:parseJson, "{\"foo\": \"bar\"}")
      end

      def test_parse
        json_file = Pathname('test.json')
        string = json_file.open { |f| f.readline }
        ips(3) do |x|
          x.report('stock') do
            JSON.parse(string, symbolize_names: true)
                .dig(:id)
          end
          session = create_session

          x.report('v8 parse & dig') do
            session.call(:getIdFromString, string)
          end

          hash = JSON.parse(string, symbolize_names: true)
          x.report('v8 dig') do
            session.call(:getId, hash)
          end
        end
      end
    end
  end
end
