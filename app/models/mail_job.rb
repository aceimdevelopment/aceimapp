# encoding: utf-8

class MailJob
  #Para levantar la cola correr QUEUE=cola_de_correos rake enviroment resque:work
  #Para matar ps -e -o pid,command | grep [r]esque y hacer kill -9 a cada uno o
  #ps -e -o pid,command | grep [r]esque | awk {'print $1'} | xargs kill -9
  @queue = :cola_de_correos
  extend Resque::Plugins::Progress
  def self.perform(meta_id, *args)
    ruta = nil
    # args[0] << "joygutierrez@hotmail.com"
    args[0] = []
    args[0] << "aceim.development@gmail.com"
    total_correos = args[0].size
    args[0].each_with_index{|p,i|
      ruta = args[3]
      self.enviar_correo(p,args[1],args[2],args[3])
      at(i, total_correos, "Enviando...")
    }
    at(total_correos, total_correos, "Finalizado...")
  end


   def self.enviar_correo(para,asunto,mensaje,adjunto=nil)   
    #para = params[:para].split(" ")
    #aki se debe agregar a joyce
   # para = []#"andresviviani1@gmail.com"
    #puts para.inspect
    #guardando el archivo
    #puts adjunto
    #------
    #puts "a punto de enviar"
#    AdministradorMailer.enviar_correo_general(para,asunto,mensaje,adjunto).deliver
    AdministradorMailer.enviar_correo_general(para,asunto,mensaje,adjunto).deliver
    #puts "enviado" 
    #puts "fin" 
    #borrando el archivo 
   # File.delete("#{ruta}") if File.exist?("#{ruta}")
    #-----
  end


end
