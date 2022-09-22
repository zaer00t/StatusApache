#!/bin/bash
# coded by: Moises Espindola
# nick: zaer00t

# e-mail: zaer00t@gmail.com
# www: http://bluedeb.com
# date: 22/Mayo/2015
# code name: Te Hace falta mas BASH

# Definimos la función
function doStat()
{
	# Define variables
	# Iniciación de variables que vamos a usar
	cnt=0
	cpl=0
	di1=1
	di2=$((1024*1000))
	di3=1024
	max=0
	statusbar=38
	tot=0
	ty1="Mb"
	ty2="Mb"
	ty3="Mb"
	ty4="Mb"
	ty5="Mb"

	# Compruebo si estamos en un servidor con cPanel instalado, ya hay ligeras variaciones en el formato de "TOP"
	# Aquí vemos una sentencia condicional, siempre empieza por if, hay que observar que despúes del corchete "[" siempre hay que dejar un espacio.
	# Igualmente, hay que dejar un espacio antes del corchete de cierre.
	if [ -d /usr/local/cpanel ]; then
		cpl=1
		di1=100
	fi
	# Cerramos la sentencia con "fi"
	# Comprobar si la memoria encontrada en top contiene el caracter "m" para saber que si los resultados se presentan en Mb o Kb
	mck=`top -b -c -n 1|grep -E "apache|httpd"|awk '{print$6}'|grep -c m`
	if [ $mck -ne 0 ]; then
		di1=1
	fi
	# Cargamos en la variable fre la memoria disponible
	fre=`grep -E "^MemFree:" /proc/meminfo|awk '{print$2}'`
	# Cargamos en la variable total la memoria instalada
	total=`grep -E "^MemTotal:" /proc/meminfo|awk '{print$2}'`

	# Cargamos en mem la memoria usada por Apache. La sacamos de la función top.
	mem=`top -b -c -n 1|grep -E "apache|httpd"|grep -v grep | awk '{print$6}'|sed -e 's/[a-zA-Z]//g'`

	# Bucle para mirar cada proceso y calcular ( por proceso )
	# avg - media
	# max - máxima memoria usada
	# tot - total de memoria usada

	for m2 in $mem
	do
		# Comprobamos si la memoria es un valor entero o un valor real. Aquí usamos una expresión regular en la condicional.
		if [[ $m2 =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			#IFS es el valor interno de Bash para el separador de variables internas
			OIFS=IFS
			IFS='.'
			m2=($m2)
			IFS=$OIFS
			# La parte real del número la guardo en m1
			m1=${m2[1]}
			# La parte entera la guardo en m2
			m2=${m2[0]}
			# Miramos el número de caracteres que hay en la parte real. Para hacer las conversiones
			m3=${#m1}
			m4=10
			if [ $m3 -eq 2 ]; then  m4=100; fi
			if [ $m3 -eq 3 ]; then  m4=1000; fi
			# Convertimos a decimal
			m3=$(((m1*1024)/m4))
			# Calculamos tamaño del decimal
			m2=$(((m2*1024)+m3))
		fi
		# Fin de la comprobación de números reales
		m=$((m2/di1))
		# Cargamos en max el proceso que más memoria ocupa
		if [ $m -gt $max ]; then
			max=$m
		fi
		# Incrementamos contador y total
		cnt=$((cnt+1))
		tot=$((tot+m))
		avg=$((tot/cnt))
	done
	# Fin del bucle
	mxu=$((tot*1024))
	# Comprobamos la media y evitamos la división por cero
	if [ $avg -eq 0 ]; then
		avg=1
	fi

	# Obtenemos el número total de los procesos de apache
	# escuchando o conectado
	cnt=`lsof -i :80|grep -iE "esta|ist|esc"|wc -l`

	# Calculamos los procesos disponibles de la máquina
	ava=$(((fre/avg)/100))
	wst=$(((fre/max)/100))
	# Aquí usamos BC. Necesitamos un número real y bash no permite operaciones con estos de forma interna
	pct=`echo "scale=2;($fre/$total)*100"|bc`
	out=`echo "scale=2;($pct/100)*$statusbar"|bc|awk -F\. '{print$1}'`
	# Ajustamos para cPanel si es necesario
	if [ $cpl ] && [ "$out" == '' ]; then
		out=0
	fi

	# Calculamos el uso de la memoria y convertimos a Gb si es necesario
	if [ $fre -ge $di2 ]; then
		ty1="Gb"
		fre=`echo "scale=2;$fre/$di2"|bc`
	else
		if [ $fre -ge $di3 ]; then
			fre=`echo "scale=2;$fre/$di3"|bc`
		fi
	fi
	if [ $mxu -ge $di2 ]; then
		ty2="Gb"
		mxu=`echo "scale=2;$mxu/$di2"|bc`
	else
		if [ $mxu -ge $di3 ]; then
			mxu=`echo "scale=2;$mxu/$di3"|bc`
		fi
	fi

	if [ $total -ge $di2 ]; then
		ty3="Gb"
		total=`echo "scale=2;$total/$di2"|bc`
	fi

	if [ $avg -ge $di2 ]; then
		ty4="Gb"
		avg=`echo "scale=2;$avg/$di2"|bc`
	fi
	if [ $max -ge $di2 ]; then
		ty5="Gb"
		max=`echo "scale=2;$max/$di2"|bc`
	fi

	# Bucle para mostrar una barra de estado
	sloop=$statusbar
	statusbar=$((statusbar+3))
	nline=`seq -s "=" $statusbar|sed 's/[0-9]//g'`

	# Mostramos resultados
	printf "%s\n" $nline
	printf "Procesos y memoria utilizada por Apache.\n"
	printf "%s\n" $nline
	printf "Memoria total: %s%s\n" $total $ty3
	printf "Memoria disponible:      %s%s\n" $fre $ty1
	printf "Porcentaje libre:        %s\45\n" $pct

	# Mostramos la memoria usada en la barra de estado. Observamos que en el bucle while,
	# los corchetes llevan sus espacios después y antes, como en el if que hemos descrito antes.
	printf "Status bar:\n|"
	while [ $sloop -ge 1 ]; do
		cc="-"
		if [ $sloop -ge $out ]; then
			cc="+"
		fi
		printf "%s" $cc
		sloop=$((sloop-1))
	done
	printf "|\n"

	printf "%s\n" $nline
	printf "Utilizado actualmente\n"
	printf "%s\n" $nline
	printf "Proceso: %d\n" $cnt
	printf "Espacio en HD promedio:\t%s %s\n" $avg $ty4
	printf "Maximo de espacio HD:\t%s %s\n" $max $ty5
	printf "HD espacio Total:\t%s %s\n" $mxu $ty2
	printf "%s\n" $nline
	printf "Parcial\n"
	printf "%s\n" $nline
	printf "Lo mejor:  %d mas conexioines\n" $ava
	printf "Lo pior: %d mas conexiones\n" $wst
	printf "%s\n" $nline
}
# Fin de la función
# Ejecutamos la función
doStat
## su pinche madre, no se como ni cuando hice esto, pero de que lo hice lo hice :')
