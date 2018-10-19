#encoding: utf-8
module CalificacionHelper
  def colocar_tabla(usuarios,historiales,editar)
    form_tag "guardar_notas" do
      haml_tag(:table, :class => 'tablesorter', :id => 'tablesorter') do
        haml_tag :thead do
          haml_tag :tr do
            haml_tag :th, "#"
            haml_tag :th, "Nombre"
            haml_tag :th, "Cédula"
            haml_tag :th, "Nota"
            haml_tag :th, "Descripción"
          end
        end
        haml_tag :tbody do  
          usuarios.each_with_index{ |u,i|
            nota = historiales.select{|valor| valor.usuario_ci == u.ci}.first.nota_final.to_i
            haml_tag :tr do
              haml_tag :td, i+1
              haml_tag :td, u.nombre_completo
              haml_tag :td, u.ci
              if editar
                haml_tag :td do
                  if HistorialAcademico::NOTASSTRING.include? nota.to_s
                    haml_concat(text_field :historial_academico,u.ci, \
                    {:value => HistorialAcademico.colocar_nota(nota), \
                    :maxlength => 2})
                  else
                    haml_concat(text_field :historial_academico,u.ci,\
                    {:placeholder => HistorialAcademico.colocar_nota(nota), \
                    :maxlength => 2})
                  end
                end
              else
                haml_tag :td, HistorialAcademico.colocar_nota(nota)
              end
              haml_tag :td do
                haml_tag(:div, :id => "descripcion_#{u.ci}") do
                    haml_concat HistorialAcademico::NOTASPALABRAS[nota+2]
                end
              end
            end
          }
        end
      end 
      if editar
          haml_tag :br
          haml_concat (submit_tag :Calificar)
      end
    end 
  end
  
  def colocar_tabla_ingles(usuarios,historiales,editar)
    form_tag "guardar_notas_ingles" do
      haml_tag(:table, :class => 'tablesorter', :id => "ingles") do
        haml_tag :thead do
          haml_tag :tr do
            haml_tag :th, "#"
            haml_tag :th, "Nombre"
            haml_tag :th, "Cédula"
            haml_tag :th, "E. Teórico 1 (30%)"
            haml_tag :th, "E. Teórico 2 (30%)"
            haml_tag :th, "E. Oral (20%)"
            haml_tag :th, "Otros (20%)"
            haml_tag :th, "Nota"
            haml_tag :th, "Descripción"
          end
        end
        haml_tag :tbody do  
          historiales.each_with_index{ |h,i|
            haml_tag :tr do
              haml_tag :td, i+1
              haml_tag :td, h.usuario.nombre_completo
              haml_tag :td, h.usuario.ci
              valor = nil
              if h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota == -1
                valor = "PI"
              else
                valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota
              end
              if editar
                haml_tag :td do
                  if h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota != HistorialAcademico::SC
                    haml_concat (text_field :nota1,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota1,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              if h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota == -1
                valor = "PI"
              else
                valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota
              end
              if editar
                haml_tag :td do
                  if h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota != HistorialAcademico::SC
                    haml_concat (text_field :nota2,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota2,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              if h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota == -1
                valor = "PI"
              else
                valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota
              end  
              if editar
                haml_tag :td do
                  if h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota != HistorialAcademico::SC
                    haml_concat (text_field :nota3,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota3,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              if h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota == -1
                valor = "PI"
              else
                valor = h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota
              end  
              if editar
                haml_tag :td do
                  if h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota != HistorialAcademico::SC
                    haml_concat (text_field :nota4,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota4,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              if h.nota_final != HistorialAcademico::SC
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat HistorialAcademico.colocar_nota(h.nota_final)
                end
              else 
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat "SC"
                end
              end
              if h.nota_final == -1
                valor = -1
              else
                valor = h.nota_final
              end
              if editar
                haml_concat(hidden_field :notafinal,h.usuario.ci,{:value => valor})
              end
              
              haml_tag :td do
                haml_tag(:div, :id => "descripcion_#{h.usuario.ci}") do
                    haml_concat HistorialAcademico::NOTASPALABRAS[h.nota_final+2]
                end
              end
            end
          }
        end
      end 
      if editar
          haml_tag :br
          haml_concat(submit_tag :Calificar)
      end
    end 
  end

  # Nueva funcion helper para calificaciones generales

  def colocar_tabla_30(usuarios,historiales,editar)
    form_tag "guardar_notas_30" do
      haml_tag(:table, :class => 'tablesorter', :id => "ingles") do
        haml_tag :thead do
          haml_tag :tr do
            haml_tag :th, "#"
            haml_tag :th, "Nombre"
            haml_tag :th, "Cédula"
            haml_tag :th, "E. Teórico 1 (30%)"
            haml_tag :th, "E. Teórico 2 (30%)"
            haml_tag :th, "E. Oral (30%)"
            haml_tag :th, "Otros (10%)"
            haml_tag :th, "Final"
            haml_tag :th, "Descripción"
          end
        end
        haml_tag :tbody do  
          historiales.each_with_index{ |h,i|
            haml_tag :tr do
              haml_tag :td, i+1
              haml_tag :td, h.usuario.nombre_completo
              haml_tag :td, h.usuario.ci
              valor = nil
              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota_valor
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota1,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota1,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota_valor
              
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota2,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota2,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end

              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota_valor
                
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota3,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota3,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end

              valor = h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota_valor

              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota4,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota4,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              if h.nota_final != HistorialAcademico::SC
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat HistorialAcademico.colocar_nota(h.nota_final)
                end
              else 
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat "SC"
                end
              end
              if h.nota_final == -1
                valor = -1
              else
                valor = h.nota_final
              end
              if editar
                haml_concat(hidden_field :notafinal,h.usuario.ci,{:value => valor})
              end
              
              haml_tag :td do
                haml_tag(:div, :id => "descripcion_#{h.usuario.ci}") do
                    haml_concat HistorialAcademico::NOTASPALABRAS[h.nota_final+2]
                end
              end
            end
          }
        end
      end 
      if editar
          haml_tag :br
          haml_concat(submit_tag :Calificar)
      end
    end 
  end


  def colocar_tabla_general(usuarios,historiales,editar)
    form_tag "guardar_notas_ingles" do
      haml_tag(:table, :class => 'tablesorter', :id => "ingles") do
        haml_tag :thead do
          haml_tag :tr do
            haml_tag :th, "#"
            haml_tag :th, "Nombre"
            haml_tag :th, "Cédula"
            haml_tag :th, "E. Teórico 1 (30%)"
            haml_tag :th, "E. Teórico 2 (30%)"
            haml_tag :th, "E. Oral (20%)"
            haml_tag :th, "Redacción (10%)"            
            haml_tag :th, "Otros (10%)"
            haml_tag :th, "Final"
            haml_tag :th, "Descripción"
          end
        end
        haml_tag :tbody do  
          historiales.each_with_index{ |h,i|
            haml_tag :tr do
              haml_tag :td, i+1
              haml_tag :td, h.usuario.nombre_completo
              haml_tag :td, h.usuario.ci
              valor = nil
              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota_valor
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota1,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota1,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota_valor
              
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota2,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota2,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end

              valor = h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota_valor
                
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota3,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota3,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end

              valor = h.nota_en_evaluacion(HistorialAcademico::REDACCION).nota_valor
              
              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota5,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota5,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end

              valor = h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota_valor

              if editar
                haml_tag :td do
                  if valor != HistorialAcademico::SC
                    haml_concat (text_field :nota4,h.usuario.ci, \
                    {:value => valor, :maxlength => 5})
                  else
                    haml_concat(text_field :nota4,h.usuario.ci,{:placeholder => "SC",:maxlength => 5})
                  end
                end
              else
                haml_tag :td, valor
              end
              
              if h.nota_final != HistorialAcademico::SC
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat HistorialAcademico.colocar_nota(h.nota_final)
                end
              else 
                haml_tag(:td,:id => "nota_final_"+h.usuario.ci) do
                  haml_concat "SC"
                end
              end
              if h.nota_final == -1
                valor = -1
              else
                valor = h.nota_final
              end
              if editar
                haml_concat(hidden_field :notafinal,h.usuario.ci,{:value => valor})
              end
              
              haml_tag :td do
                haml_tag(:div, :id => "descripcion_#{h.usuario.ci}") do
                    haml_concat HistorialAcademico::NOTASPALABRAS[h.nota_final+2]
                end
              end
            end
          }
        end
      end 
      if editar
          haml_tag :br
          haml_concat(submit_tag :Calificar)
      end
    end 
  end

end
