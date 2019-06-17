require 'date'
require 'time'

class Tag
  attr_reader :tag

  def initialize(tag)
    @tag = tag
  end

  def tag_type
    @tag_type ||= %x{git cat-file -t #{tag}}.chomp
  end

  def is_full_tag?
    tag_type == 'tag'
  end

  def content
    @content ||= %x{git tag -v #{tag} 2>/dev/null}
  end

  def lines
    content.split("\n")
  end

  def tagger
    if lines[3] =~ /^tagger (\w+ <[^>]+>) (\d+ [+-]\d+)/
      {
        name: $1,
        timestamp: DateTime.strptime($2, '%s %z')
      }
    end
  end

  def timestamp
    tagger[:timestamp]
  end

  def rest
    lines[5..-1]
  end

  def to_s
    "T: #{tag}\n#{tagger}\n#{rest}\n"
  end
end

class MergeCommit
  attr_reader :sha, :date, :message

  def initialize(line)
    (@sha, @date, @message) = line
  end

  def earliest_tag
    %x{git tag --contains #{sha}}
      .split("\n")
      .select {|t| t =~ /^alpha_release-/}
      .sort_by {|t| t.split('-').last.to_i }
      .map {|t| Tag.new(t)}
      .first
  end

  def timestamp
    DateTime.parse(date)
  end

  def to_s
    "#{sha}  #{date}  #{message}"
  end
end

class Stats
  SEP="_&_"

  def self.for(path, limit=2000)
    Dir.chdir path
    Enumerator.new do |yielder|
      %x{git log --merges --pretty='%H#{SEP}%ci#{SEP}%s'}.split("\n").take(limit).map do |l|
        m = MergeCommit.new(l.split(SEP))
        time_to_build = (m.earliest_tag.timestamp - m.timestamp).to_f * 24 * 60 * 60
        yielder << {
          sha: m.sha,
          merge_date: m.timestamp,
          first_tag: m.earliest_tag.tag,
          first_tag_date: m.earliest_tag.timestamp,
          time_to_build_in_seconds: time_to_build.to_i,
          time_to_build_in_words: humanize(time_to_build),
          merge_message: m.message
        }
      end
    end
  end

  def self.humanize secs
    [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)

        "#{n.to_i} #{name}" unless n.to_i==0
      end
    }.compact.reverse.join(' ')
  end

end