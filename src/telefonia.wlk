/** First Wollok example */

/*
 1) consumo.costo() -> NUMBER
 2)
 * a. linea.costoPromedioConsumosEn(inicio, fin ) -> NUMBER
   b. linea.consumoTotalUltimoMes() -> NUMBER
 3)pack.puedeSatisfacer(consumo)	-> BOOL
 4)linea.agregar(pack)				-> [accion]
 5)linea.puedeRealizar(consumo)		-> BOOL
 6)linea.realizar(consumo)			-> BOOL
 7)
 * a. linea.limpiarPacksInutiles()	-> [accion]
 * b. const consumoNuevo= new Consumo(cantidadConsumo = 40, tipoConsumo = megasLibresMasMas, fecha = hoy)
 8)
 *  */
 
 //1) 
 const hoy = new Date()
 
 const llamadaAtito= new Consumo(cantidadConsumo = 40, tipoConsumo = llamada, fecha = hoy )		// 40 s
 const internetUnLunes = new Consumo(cantidadConsumo = 10, tipoConsumo = internet, fecha = hoy)	// 10 MB 

// 4) packs
 const recarga100Credito = new Pack( tipoPack = credito, cantidadPack = 100)
 const cincuentaMegasLibre = new Pack( tipoPack = megasLibres, cantidadPack = 50)

class Linea{
	var property numero
	var property packs = #{}
	var property consumos = []
	var property plan = comun
	
	//punto 2. a
	method costoPromedioConsumosEn(inicio, fin) = 
		self.costoTotalEn(inicio, fin) / self.consumosEntre(inicio,fin).size()
		
	method costoTotalEn(inicio, fin) =
		self.consumosEntre(inicio, fin).sum({ cons => cons.costo() })
	
	method consumosEntre(inicio , fin) =
		consumos.filter({ cons => cons.fecha().between(inicio,fin) })
		
	// 2.b
	method consumoTotalUltimoMes()	= // 30 dias
		self.costoTotalEn(hoy, hoy.minusDays(30) )
	
	// punto 4
	method agregarPack(pack){
		packs.add(pack)
	}
	// punto 5
/*	method validarPuedeRealizar(consumo){
		if (not self.tieneUnPackQueSatifaga(consumo))
			throw new DomainException(message = "no hay pack vigente que satisfaga completamente el consumo")
	}
*/
	
	// punto 6
	method realizar(consumo){
		plan.validarPuedeRealizar(consumo, packs)
		consumos.add(consumo)
		self.consumirPack(consumo)
	}	
	method consumirPack(consumo){
		self.ultPackQueSatisfaga(consumo).consumir(consumo)
	}
	
	method ultPackQueSatisfaga(consumo) =
		packs.reverse().find({pack=> pack.puedeSatisfacer(consumo) })

	// 7 
	method limpiarPacksInutiles(){
		packs.removeAllSuchThat({pack => pack.esInutil()})
	}
}
//Planes
class Plan{
	method validarPuedeRealizar(consumo, packs){
		if (not self.tieneUnPackQueSatifaga(consumo, packs))
			throw new DomainException(message = "no hay pack vigente que satisfaga completamente el consumo")
	}	
	
	method tieneUnPackQueSatifaga(consumo, packs) = packs.any({pack => pack.puedeSatisfacer(consumo) }) 
	
}
const comun = new Plan()


class Consumo{	// punto 2
	var property cantidadConsumo = 0
	var property tipoConsumo // internet o llamadas
	var property fecha		 // tipo Date
	
	method diaSemana() = fecha.dayOfWeek()
	
	//punto 1
	method costo() = tipoConsumo.costo(cantidadConsumo)	
	
	
}
object internet{
	method costo(megas) = megas * 0.1
}

object llamada{
	var property costoFijo = 1
	method costo(segundos) = costoFijo + self.costoVariable(segundos)
	
	method costoVariable(segundos) =
		(segundos - 30).max(0) * 0.05
	
	
}

class Pack{
	var property tipoPack
	var property cantidadPack = 0
	var property vencimiento = hoy 			//tipo Date
	method puedeSatisfacer(consumo) = 
		self.cubreServicio(consumo.tipoConsumo()) && self.satisfaceCompletamente(consumo)


	method cubreServicio(tipoConsumo) = tipoPack.serviciosCubiertos().contains(tipoConsumo)
	
	method satisfaceCompletamente(consumo) =
		tipoPack.satisfaceCompletamente(consumo, cantidadPack )
	
	// punto 6
	method consumir(consumo) {
		cantidadPack =- tipoPack.gasto(consumo)
	} 
	
	//punto 7
	method esInutil() = self.estaVencido() || self.estaAcabado() 
	method estaVencido() = hoy > vencimiento
	method estaAcabado() = cantidadPack == 0
}




object credito {
	const property serviciosCubiertos = [internet, llamada]
	
	method satisfaceCompletamente(consumo, cantCredito) =   cantCredito > consumo.costo() // cantCredito > ( consumo.costo() )
	
	method gasto(consumo) = consumo.costo()
}

const megasLibre = new PackMegas()	// objeto usado polimorficamente

class PackMegas{					// clase intermedia usada para no repetir logica punto 7
	const property serviciosCubiertos = [internet]
	 
	method satisfaceCompletamente(consumo, megasLibres) = 
		megasLibres > consumo.cantidadConsumo()
	
	method gasto(consumo) =
		consumo.cantidadConsumo()
	
}
object megasLibresMasMas inherits PackMegas{	// punto 7

	override method satisfaceCompletamente(consumo, megasLibres){
		return super(consumo, megasLibres) || consumo.cantidadConsumo() <= 0.1
	}
	// no cambie el gasto por que en ningun momento dice algo de no poder tener gasto negativo
}
object llamadasGratis {
	const property serviciosCubiertos = [llamada]
	var property cantidadPack = ilimitado
	
	method satisfaceCompletamente(_, __) = true
	
	method gasto(consumo) = 0		// no se gasta
	
}
object internetIlimitadoFindes{
	const property serviciosCubiertos = [internet]
	var property cantidadPack = ilimitado
	
	method satisfaceCompletamente(consumo, _) = 
		consumo.diaSemana() == sunday || consumo.diaSemana() == saturday
	
	method gasto(consumo) = 0		// no se gasta
	
}

object ilimitado{}


class LineaBlack inherits Linea{
	var property deuda = 0
	
	override method validarPuedeRealizar(consumo){
		if (not self.tieneUnPackQueSatifaga(consumo)){
			
			self.sumarDeuda( consumo.costo())
			throw new DomainException(message = "no hay pack que satisfaga el consumo, su costo fue agregado a la deuda!")
		}
	}
	
	method sumarDeuda(costo){
		deuda =+ costo
	}
	
}


class LineaPlatinum inherits Linea{
	
}
 /*
 * 
 * Cierta cantidad de crédito disponible.
•	Una cant de MB libres para navegar por Internet.
•	Llamadas gratis.
•	Internet ilimitado los findes (*)
 */	 