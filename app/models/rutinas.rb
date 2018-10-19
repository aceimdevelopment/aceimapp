# encoding: utf-8



#require 'barby/outputter/png_outputter'

class Rutinas
  def self.colocar_claves_instructor(periodo_id="C-2011")
    Instructor.all.each_with_index{|inst, ind|
      usuario = inst.usuario 
      clave = inst.clave_propuesta
      puts "UPDATE usuario SET contrasena = '#{clave}' WHERE ci = '#{usuario.ci}';"
      usuario.contrasena = clave
      usuario.save
    }
  end                                                                          
  
  def self.enviar_correos_instructores     
    instructores = Seccion.where(:periodo_id => "C-2011",:esta_abierta =>true).collect{|x|
       x.instructor}.uniq          
    tam = instructores.size
    instructores.each_with_index{|inst,ind|
      puts "#{ind}/#{tam-1}"
      InstructorMailer.inicio_clave(inst.usuario).deliver  
      Bitacora.info(
          :descripcion => "Se le envió el correo de clave al instructor ",
          :usuario_ci => inst.usuario_ci,
          :ip_origen => "127.0.0.1")
  
    }
  end

  def self.enviar_correos_bienvenida_estudiantes    
    i = 1
    registros = HistorialAcademico.where(
      :periodo_id => "C-2011").collect{|x|
      puts i
      i += 1
      EstudianteMailer.bienvenida(x.usuario).deliver
      Bitacora.info(
          :descripcion => "Se le envió el correo de bienvenida",
          :estudiante_usuario_ci => x.usuario_ci,
          :usuario_ci => x.usuario_ci,
          :ip_origen => "127.0.0.1")
    }
  end        

  def self.enviar_correos_recordatorio_estudiantes    
    i = 1
    registros = HistorialAcademico.where(
      :periodo_id => "D-2011").collect{|x|
      i += 1
      EstudianteMailer.recordatorio(x.usuario).deliver
      Bitacora.info(
          :descripcion => "Se le envió el correo de recordatorio",
          :estudiante_usuario_ci => x.usuario_ci,
          :usuario_ci => x.usuario_ci,
          :ip_origen => "127.0.0.1")
    }
  end        
  
  def self.enviar_correo_recordatorio_calificacion
    secciones = Seccion.where(:esta_calificada => false, 
      :periodo_id => ParametroGeneral.periodo_calificacion,
      :esta_abierta => true)
    total = secciones.size            
    plazo = ParametroGeneral.calificacion_plazo    
    begin
    secciones.each_with_index{|sec,ind|          
      usuario = sec.instructor.usuario
      InstructorMailer.recordatorio_calificacion(usuario, sec, plazo).deliver
      Bitacora.info(
          :descripcion => "Se le envió correo de recordatorio al intructor #{usuario.nombre_completo} de la seccion: #{sec.descripcion_con_periodo}",
          :usuario_ci => usuario.ci,
          :ip_origen => "127.0.0.1")
      puts "#{ind+1} de #{total}"
    }    
    rescue
    end
                               
    #joyce Gutiérrez Juárez <joygutierrez@hotmail.com>
    #carlos A. Saavedra A. <saavedraazuaje73@gmail.com>
    destinos = ["sergiorivas@gmail.com","joygutierrez@hotmail.com","saavedraazuaje73@gmail.com"]
    Rutinas.enviar_aviso_general(destinos,
      "Recordatorio Calificacion",
      "Se le envio un correo de recordatorio de calificación a los instructores de #{total} secciones.")                                                      
  end
  
  def self.enviar_correo_listados
    instructores = Seccion.where(
      :periodo_id => ParametroGeneral.periodo_actual,
      :esta_abierta => true).collect{|x| x.instructor }.compact.uniq
    total = instructores.size            
    instructores.each_with_index{|ins,ind|          
      usuario = ins.usuario
      InstructorMailer.bienvenida(usuario).deliver
      Bitacora.info(
          :descripcion => "Se le envió correo de recordatorio al intructor de los listados #{usuario.nombre_completo}",
          :usuario_ci => usuario.ci,
          :ip_origen => "127.0.0.1")
      puts "#{ind+1} de #{total}"
    }
                               
    destinos = ["sergiorivas@gmail.com","joygutierrez@hotmail.com","saavedraazuaje73@gmail.com"]
    Rutinas.enviar_aviso_general(destinos,
      "Se le dio la bienvenida a los instructores",
      "Se le envio un correo de bienvenida a (#{total}) instructores.")                                                      
  end 
  
  def self.enviar_correo_cambio_aulas_instructores
    File.open("#{Rails.root}/attachments/secciones.txt"){|archivo|
      lineas = archivo.readlines
      total = lineas.size
      i = 1
      lineas.each{|linea|
      linea = linea.strip
        idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = linea.split
        puts "#{i} de #{total}"
        seccion = Seccion.where(
              :periodo_id => ParametroGeneral.periodo_actual,
              :esta_abierta => true,
              :idioma_id => idioma_id,
              :tipo_categoria_id => tipo_categoria_id,
              :tipo_nivel_id => tipo_nivel_id,
              :seccion_numero => seccion_numero).limit(1).first
        puts seccion.descripcion
        usuario = seccion.instructor.usuario
        InstructorMailer.cambio_aulas_faces(usuario,seccion).deliver
        Bitacora.info(
            :descripcion => "Se le envió correo de cambio de aula al intructor #{usuario.nombre_completo}",
            :usuario_ci => usuario.ci,
            :ip_origen => "127.0.0.1")
        i += 1   
        if i == total                                                 
          usuario = Usuario.find "13736933"
          InstructorMailer.cambio_aulas_faces(usuario,seccion).deliver
        end
      }
      
    }
  end
  
  def self.enviar_correo_cambio_aulas_estudiantes
    File.open("#{Rails.root}/attachments/secciones.txt"){|archivo|
      lineas = archivo.readlines
      total = lineas.size
      i = 1
      lineas.each{|linea|
      linea = linea.strip
        idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = linea.split
        puts "#{i} de #{total}"
        seccion = Seccion.where(
              :periodo_id => ParametroGeneral.periodo_actual,
              :esta_abierta => true,
              :idioma_id => idioma_id,
              :tipo_categoria_id => tipo_categoria_id,
              :tipo_nivel_id => tipo_nivel_id,
              :seccion_numero => seccion_numero).limit(1).first
        puts seccion.descripcion      
        ests = seccion.estudiantes_inscritos
        ests.each{|est|
          usuario = est.usuario
          EstudianteMailer.cambio_aulas_faces(usuario,seccion).deliver
          Bitacora.info(
              :descripcion => "Se le envió correo de cambio de aula al estudiante #{usuario.nombre_completo}",
              :usuario_ci => usuario.ci,
              :ip_origen => "127.0.0.1")
        }
        i += 1   
        if i == total                                                 
          usuario = Usuario.find "13736933"
          InstructorMailer.cambio_aulas_faces(usuario,seccion).deliver
        end
      }
      
    }
  end  
  
  def self.enviar_no_clases
    titulo = "Suspensión de clases del 25-10-2011"    
    info = "Le informamos que debido al paro de universidades que se llevará a cabo 
    mañana martes 25 de octubre, nos vemos en la necesidad de suspender las 
    actividades de los cursos de idiomas.
     
    Gracias 
    "
    correos = []
    hor = HorarioSeccion.where(:periodo_id => "D-2011",
      :tipo_dia_id => "MA").collect{|x| x.seccion}.uniq
    hor.each{|h|
      correos << h.instructor.usuario.correo if h.instructor
      correos << h.estudiantes_inscritos.collect{|x| x.usuario.correo}.compact.flatten
    }
    correos = correos.uniq
    enviar_aviso_general(correos,titulo,info)
  end
  
  def self.enviar_frances_cambio
    titulo = "Cambio de Aula"    
    info = "Le informamos que debido a que en su curso un estudiante no puede subir las 
    escaleras, la aula del curso a sido cambiada a la 10 de Psicología.
     
    Gracias.
    "
    correos = []
    hor = Seccion.where(:periodo_id => "D-2011",
    :esta_abierta => true,
    :idioma_id => "FR",
    :tipo_categoria_id => "AD",
    :tipo_nivel_id => "BI",
    :seccion_numero => 5)
 
    hor.each{|h|
      correos << h.instructor.usuario.correo if h.instructor
      correos << h.estudiantes_inscritos.collect{|x| x.usuario.correo}.compact.flatten
    }
    correos = correos.uniq
    enviar_aviso_general(correos,titulo,info)
  end 
  
  def self.enviar_suspension_clases
    titulo = "Ultima suspensión de clases"    
    info = "
Le informamos que debido a los actos de violencia ocurridos este viernes 09 de 
diciembre en la UCV nos vemos en la obligación de suspender las actividades hasta el 09 de enero de 2012. 

A continuación le presentamos la nueva planificación:

CURSOS LUNES/MIÉRCOLES
CLASE 17: LUNES 09 DE ENERO (REPASO)
CLASE 18: MIÉRCOLES 11 DE ENERO (EXAMEN ESCRITO)
CLASE 19: LUNES 16 DE ENERO (EXAMEN ORAL)

CURSOS MARTES/JUEVES
CLASE: 17 MARTES 10 DE ENERO (REPASO)
CLASE 18: JUEVES 12 DE ENERO (EXAMEN ESCRITO)
CLASE 19: MARTES 17 DE ENERO 

CURSOS SÁBADOS
CLASE 8: SÁBADO 14 DE ENERO (REPASO)
CLASE 9: SÁBADO 21 DE ENERO (EXAMEN ORAL Y ESCRITO)

Agradecemos hacer circular esta información y una vez más ofrecemos 
disculpas por todos los inconvenientes causados.

Gracias
Saludos
Prof. Joyce Gutiérrez
    
"
    correos = []    
    hor = HorarioSeccion.where(:periodo_id => "D-2011").collect{|x| x.seccion}.uniq#MA","LU"]).collect{|x| x.seccion}.uniq

    hor.each{|h|
      correos << h.instructor.usuario.correo if h.instructor
      correos << h.estudiantes_inscritos.collect{|x| x.usuario.correo}.compact.flatten
    }
    correos = correos.uniq
    enviar_aviso_general(correos,titulo,info)
  end    
  
  def self.enviar_reinicio_clases
    titulo = "Reinicio de clases"    
    info = "Le informamos que las clases se reanudan en todos los horarios.
    Ya comienzan todas las actividades normales de los cursos.
    
    Disculpen los inconvenientes.
     
    Gracias.
    "
    correos = []    
    hor = HorarioSeccion.where(:periodo_id => "D-2011").collect{|x| x.seccion}.uniq#MA","LU"]).collect{|x| x.seccion}.uniq

    hor.each{|h|
      correos << h.instructor.usuario.correo if h.instructor
      correos << h.estudiantes_inscritos.collect{|x| x.usuario.correo}.compact.flatten
    }
    correos = correos.uniq
    enviar_aviso_general(correos,titulo,info)
  end                                                            
  
  def self.enviar_aviso_general(correos,titulo,info)
    destinatarios = correos.to_a.flatten
    destinatarios.each{|correo|
      puts "Enviando a #{correo}"
      AdministradorMailer.aviso_general(correo,titulo,info).deliver
    }
  end      
  
  def self.crear_codigo_barra(texto)
    barcode = Barby::Code128B.new(texto)
    ruta = File.join(Rails.root,"codigos_barra","#{texto}.jpg")
    File.open(ruta, 'wb'){|f|  f.write barcode.to_jpg }
    return ruta
  end

  def self.destruir_codigo_barra(texto)
    ruta = File.join(Rails.root,"codigos_barra","#{texto}.jpg")
    if File.exists? ruta
      FileUtils.rm  ruta
    end
  end

end
