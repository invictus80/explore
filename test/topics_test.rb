require_relative "./test_helper"

describe "topics" do
  topics.each do |topic|
    describe "#{topic} topic" do
      it "has an index.md" do
        path = File.join(topics_dir, topic, "index.md")

        assert File.file?(path), "expected #{path} to be a file"
      end

      it "has only one image with the right name" do
        paths = image_paths_for(topic)

        assert paths.size <= 1, "expected at most one image, found #{paths.size}"

        if path = paths.first
          assert_equal topic, File.basename(path, File.extname(path)),
            "expected image to be named [topic].[extension]"
        end
      end

      it "has no unexpected files or directories" do
        files = Dir["#{topics_dir}/#{topic}/**/*"].reject do |entry|
          file_name = File.basename(entry)
          image_files = possible_image_file_names_for(topic)

          entry == "." || entry == ".." || file_name == "index.md" ||
            image_files.include?(file_name)
        end

        assert_empty files, "expected only index.md and a single image"
      end

      it "has Jekyll front matter in index.md" do
        path = File.join(topics_dir, topic, "index.md")

        if File.file?(path)
          lines = File.readlines(path)

          assert lines.size > 0
          assert_equal "---\n", lines[0], "expected file to start with Jekyll front matter ---"

          end_index = lines.slice(1..-1).index("---\n")
          assert end_index, "expected Jekyll front matter to end with ---"
        end
      end

      it "has expected metadata in Jekyll front matter" do
        metadata = metadata_for(topic)
        refute_empty metadata, "expected some metadata for topic"

        metadata.each do |key, value|
          assert_includes VALID_METADATA_KEYS, key, "unexpected metadata key '#{key}'"
        end

        REQUIRED_METADATA_KEYS.each do |key|
          assert metadata.key?(key), "expected to have '#{key}' defined for topic"
          assert metadata[key] && metadata[key].strip.size > 0,
            "expected to have a value for '#{key}'"
      end

      it "follows the Topic Page Style Guide" do
        text = text_for(topic)
        end_punctuation = %w[. , ; :]
        text.lines do |line|
          line.chomp!

          refute_includes line, "&", 'Use "and" rather than an ampersand'
          refute_includes line, "!", "Avoid exclamation points in topic pages"
          refute_includes line, "open-source",
                          "Use open source without a hyphen"

          %w[Jan Feb Mar Apr Jun Jul Aug Sep Oct Nov Dec].each do |month|
            refute_includes line, "#{month} ", "Include and spell out the month"
          end

          %w[1st 2nd 3rd 1th 2th 3th 4th 5th 6th 7th 8th 9th].each do |date_end|
            refute_includes line, date_end,
                            'Include the day number without the "th" or "nd" at the end'
          end

          %w[GitHubbing Gitting].each do |no_git_verb|
            refute_includes line, no_git_verb,
                            "Never use “GitHub” or “Git” as a verb."
          end

          %w[Github github].each do |wrong_github|
            refute_includes line, wrong_github,
                            'Always use correct capitalization when referring to "GitHub"'
          end

          (end_punctuation + [" "]).each do |punctuation|
            refute_includes line, "git#{punctuation}",
                            'Always use correct capitalization when referring to "Git"'

            (1..10).each do |digit|
              refute_includes line, " #{digit}#{punctuation}",
                              'Write out "one" and every number less than 10'
            end
          end
        end
        text.delete("\n").split(".").each do |sentence|
          # This is arbitrary; 2 is more correct but 3 avoids false positives.
          next if sentence.count(",") < 3

          %w[and or].each do |conjunction|
            next unless sentence.include? " #{conjunction} "
            assert_includes sentence, ", #{conjunction}", "Always use the Oxford comma"
          end
        end
      end
    end
  end
end
