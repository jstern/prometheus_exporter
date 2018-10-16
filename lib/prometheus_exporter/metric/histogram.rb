# frozen_string_literal: true

module PrometheusExporter::Metric
  class Histogram < Base

    BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5.0, 10.0].freeze

    attr_reader :estimators, :count, :count

    def initialize(name, help, buckets = BUCKETS)
      super(name, help)
      @buckets = buckets.sort.reverse
      @sums = {}
      @counts = {}
      @observations = {}
    end

    def type
      "histogram"
    end

    def metric_text
      text = +""
      first = true
      @observations.each do |labels, buckets|
        text << "\n" unless first
        first = false
        count = @counts[labels]
        sum = @sums[labels]
        text << "#{prefix(@name)}_bucket#{labels_text(with_bucket(labels, "+Inf"))} #{count}\n"
        @buckets.each do |bucket|
          value = @observations[labels][bucket]
          text << "#{prefix(@name)}_bucket#{labels_text(with_bucket(labels, bucket.to_s))} #{value}\n"
        end
        text << "#{prefix(@name)}_count#{labels_text(labels)} #{count}\n"
        text << "#{prefix(@name)}_sum#{labels_text(labels)} #{sum}"
      end
      text
    end

    def observe(value, labels = nil)
      labels ||= {}
      buckets = ensure_histogram(labels)

      value = value.to_f
      @sums[labels] += value
      @counts[labels] += 1

      fill_buckets(value, buckets)
    end

    def ensure_histogram(labels)
      @sums[labels] ||= 0.0
      @counts[labels] ||= 0
      buckets = @observations[labels]
      if buckets.nil?
        buckets = @buckets.map{|b| [b, 0]}.to_h
        @observations[labels] = buckets
      end
      buckets
    end

    def fill_buckets(value, buckets)
      @buckets.each do |b|
        break if value > b
        buckets[b] += 1
      end
    end

    def with_bucket(labels, bucket)
      labels.merge({"le" => bucket})
    end

  end
end