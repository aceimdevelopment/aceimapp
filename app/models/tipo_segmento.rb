# encoding: utf-8
class TipoSegmento < ApplicationRecord

	belongs_to :segmentos,
	:foreign_key => :tipo_segmento_id

end