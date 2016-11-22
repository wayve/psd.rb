require 'psd/layer_info'

class PSD
  class Artboard < LayerInfo
    def self.should_parse?(key)
      key == 'artb'
    end

    attr_reader :left, :right, :top, :bottom, :width, :height

    def parse
      @file.seek 4, IO::SEEK_CUR
      @data = Descriptor.new(@file).parse

      @left = @data['artboardRect']['Left']
      @top = @data['artboardRect']['Top ']
      @right = @data['artboardRect']['Rght']
      @bottom = @data['artboardRect']['Btom']
      @height = @bottom - @top
      @width  = @right - @left
    end
  end
end
