require 'psd/layer/info/artboard'
require 'psd/layer/info/black_white'
require 'psd/layer/info/blend_clipping_elements'
require 'psd/layer/info/blend_interior_elements'
require 'psd/layer/info/brightness_contrast'
require 'psd/layer/info/channel_blending_restrictions'
require 'psd/layer/info/channel_mixer'
require 'psd/layer/info/color_balance'
require 'psd/layer/info/color_lookup'
require 'psd/layer/info/content_generator'
require 'psd/layer/info/curves'
require 'psd/layer/info/effects_layer'
require 'psd/layer/info/exposure'
require 'psd/layer/info/fill_opacity'
require 'psd/layer/info/gradient_fill'
require 'psd/layer/info/gradient_map'
require 'psd/layer/info/hue_saturation'
require 'psd/layer/info/invert'
require 'psd/layer/info/knockout'
require 'psd/layer/info/layer_effects'
require 'psd/layer/info/layer_mask_as_global_mask'
require 'psd/layer/info/layer_group'
require 'psd/layer/info/layer_id'
require 'psd/layer/info/layer_name_source'
require 'psd/layer/info/layer_section_divider'
require 'psd/layer/info/legacy_typetool'
require 'psd/layer/info/levels'
require 'psd/layer/info/locked'
require 'psd/layer/info/metadata_setting'
require 'psd/layer/info/object_effects'
require 'psd/layer/info/pattern'
require 'psd/layer/info/pattern_fill'
require 'psd/layer/info/photo_filter'
require 'psd/layer/info/placed_layer'
require 'psd/layer/info/posterize'
require 'psd/layer/info/reference_point'
require 'psd/layer/info/selective_color'
require 'psd/layer/info/sheet_color'
require 'psd/layer/info/solid_color'
require 'psd/layer/info/threshold'
require 'psd/layer/info/transparency_shapes_layer'
require 'psd/layer/info/typetool'
require 'psd/layer/info/unicode_name'
require 'psd/layer/info/vector_mask'
require 'psd/layer/info/vector_mask_as_global_mask'
require 'psd/layer/info/vector_origination'
require 'psd/layer/info/vector_stroke'
require 'psd/layer/info/vector_stroke_content'
require 'psd/layer/info/vibrance'

class PSD
  class Layer
    module Info
      # All of the extra layer info sections that we know how to parse.
      LAYER_INFO = {
        artboard: Artboard,
        black_white: BlackWhite,
        blend_clipping_elements: BlendClippingElements,
        blend_interior_elements: BlendInteriorElements,
        brightness_contrast: BrightnessContrast,
        channel_blending_restrictions: ChannelBlendingRestrictions,
        channel_mixer: ChannelMixer,
        color_balance: ColorBalance,
        color_lookup: ColorLookup,
        content_generator: ContentGenerator,
        curves: Curves,
        effects_layer: EffectsLayer,
        exposure: Exposure,
        fill_opacity: FillOpacity,
        gradient_fill: GradientFill,
        gradient_map: GradientMap,
        hue_saturation: HueSaturation,
        invert: Invert,
        knockout: Knockout,
        layer_effects: LayerEffects,
        layer_mask_as_global_mask: LayerMaskAsGlobalMask,
        layer_id: LayerID,
        layer_name_source: LayerNameSource,
        legacy_type: LegacyTypeTool,
        levels: Levels,
        locked: Locked,
        metadata: MetadataSetting,
        name: UnicodeName,
        nested_section_divider: NestedLayerDivider,
        object_effects: ObjectEffects,
        pattern_fill: PatternFill,
        photo_filter: PhotoFilter,
        placed_layer: PlacedLayer,
        posterize: Posterize,
        reference_point: ReferencePoint,
        selective_color: SelectiveColor,
        section_divider: LayerSectionDivider,
        sheet_color: SheetColor,
        solid_color: SolidColor,
        threshold: Threshold,
        transparency_shapes_layer: TransparencyShapesLayer,
        type: TypeTool,
        vector_mask: VectorMask,
        vector_mask_as_global_mask: VectorMaskAsGlobalMask,
        vector_origination: VectorOrigination,
        vector_stroke: VectorStroke,
        vector_stroke_content: VectorStrokeContent,
        vibrance: Vibrance
      }.freeze

      BIG_LAYER_INFO_KEYS = %w{ LMsk Lr16 Lr32 Layr Mt16 Mt32 Mtrn Alph FMsk lnk2 FEid FXid PxSD }

      attr_reader :adjustments
      alias :info :adjustments

      LAYER_INFO.keys.each do |key|
        define_method(key) { @adjustments[key] }
      end

      private

      def parse_additional_layer_info_length(key)
        if @header.big? && BIG_LAYER_INFO_KEYS.include?(key)
          Util.pad2 @file.read_longlong
        else
          Util.pad2 @file.read_int
        end
      end

      # This section is a bit tricky to parse because it represents all of the
      # extra data that describes this layer.
      def parse_layer_info
        @extra_data_begin = @file.tell

        while @file.tell < @layer_end
          # Signature, don't need
          @file.seek 4, IO::SEEK_CUR

          # Key, very important
          key = @file.read_string(4)
          @info_keys << key

          length = parse_additional_layer_info_length(key)
          pos = @file.tell

          key_parseable = false
          LAYER_INFO.each do |name, info|
            next unless info.should_parse?(key)

            PSD.logger.debug "Layer Info: key = #{key}, start = #{pos}, length = #{length}"

            i = info.new(self, length)
            @adjustments[name] = LazyExecute.new(i, @file).now(:skip).later(:parse)

            key_parseable = true and break
          end

          unless key_parseable
            PSD.logger.debug "Skipping unknown layer info block: key = #{key}, length = #{length}"
            @file.seek length, IO::SEEK_CUR
          end
        end

        @extra_data_end = @file.tell
      end
    end
  end
end
