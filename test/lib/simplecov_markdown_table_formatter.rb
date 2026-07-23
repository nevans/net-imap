# frozen_string_literal: true

require "simplecov"

# This formatter is much faster than the HTML formatter, and it prints much more
# useful info to stderr than any of the bundled formatters.
#
# TODO: extract this to its own gem?  it needs some basic tests
# TODO: output to ENV["GITHUB_STEP_OUTPUT"]
class SimpleCovMarkdownTableFormatter < SimpleCov::Formatter::Base
  def format(result)
    return if @silent
    output = "### Coverage report for #{result.command_name}\n"
    output << format_markdown_table(result)
    $stderr.puts output
    output
  end

  def format_markdown_table(result)
    groups = { "All files" => result }.merge(result.groups)
      .transform_values(&:coverage_statistics)

    name_size = groups.keys.map(&:length).max
    criteria_sizes = groups
      .values.map { _1.transform_values(&:total) }     #=> Array[Hash[name, total]]
      .reduce { _1.merge(_2) {|_, a, b| [a, b].max } } #=> Hash[name, max]
      .transform_values { _1.to_s.length }             #=> Hash[name, strlen]

    rows = format_markdown_table_header(name_size, criteria_sizes)

    rows.concat groups.map {|name, stats|
      format_row_cells(name, stats, name_size, criteria_sizes)
    }
      .map { format_markdown_table_row _1 }

    rows.join("\n")
  end

  private

  def format_markdown_table_header(name_size, criteria_sizes)
    heading_cells = format_markdown_table_row([
      "Group".center(name_size),
      *criteria_sizes.map {|name, size|
        "#{name.to_s.capitalize} coverage".center(column_width(size))
      }
    ])
    border_line = format_row_cells("", name_size, criteria_sizes)
      .then { format_markdown_table_row _1 }
      .then { _1.tr(" ", "-") }
    [heading_cells, border_line]
  end

  def format_markdown_table_row(cells) = "| #{cells.join(" | ")} |"

  def format_row_cells(name, stats = {}, name_size, criteria_sizes)
    name = name.ljust(name_size)
    cols = criteria_sizes.map {|criterion, size|
      format_stat_column(stats[criterion], size)
    }
    [name, *cols]
  end

  def column_width(size) = 10 + size * 2 + 1 # "000.00% = " + 2*size + "/"

  def colorize_percent(percent)
    formatted = "%6.2f%%" % [percent]
    color     = SimpleCov::Color.for_percent(percent)
    SimpleCov::Color.colorize(formatted, color)
  end

  def format_stat_column(stat, size)
    if stat
      "%%s = %%%{size}s/%%%{size}s" % {size:} % stat_values(stat)
    else
      ""
    end
      .ljust(column_width(size))
  end

  # converts SimpleCov::CoverageStatistics to [String, String, String]
  def stat_values(stat)
    return ["0", "0", colorize_percent(0.0)] unless stat
    percent = colorize_percent SimpleCov.round_coverage(stat.percent)
    [percent, stat.covered, stat.total]
  end

end
