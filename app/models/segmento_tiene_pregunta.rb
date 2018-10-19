# encoding: utf-8

class SegmentoTienePregunta < ApplicationRecord

	belongs_to :pregunta
	belongs_to :segmento

end
