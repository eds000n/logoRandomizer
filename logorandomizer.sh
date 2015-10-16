#!/bin/bash

#Options 
num=1
height=256
width=256
verbose=0
convert_options=""
while getopts "hf:n:r:v" opt
do
	case $opt in
		h)
			echo "Form of use"
			echo "./logoRandomizer -f filename -n <number_of_images> -r <height>x<width> "
			echo "-v for verbosing"
			exit 0
		;;
		n)
			num=$OPTARG
		;;
		r)
			height=`echo $OPTARG|cut -dx -f1`
			width=`echo $OPTARG|cut -dx -f2`
		;;
		\?)
			echo "Invalid argument"
			exit 1
		;;
		f)
			inputfile=$OPTARG
			fname=`echo $OPTARG | cut -d. -f1`
		;;
		v)
			verbose=1
		;;
	esac
done

if [ -z $inputfile ]
then
	echo "-f mandatory argument"
	exit 1
fi

if [ ! -f $inputfile ]
then
	echo "File does not exist"
	exit 1
fi

svgfile="$fname.svg"
outfile="$fname"
#echo $fname
#echo $height
#echo $width
#echo $num

# 2svg image
function_2svg(){
	uniconvertor $1 $svgfile 2>/dev/null
	if [ ! -f $svgfile ]
	then
		echo "Error on conversion to svg, please verify input file"
		exit 1
	fi
	version=`inkscape --version | cut -d' ' -f2 | cut -d. -f2`
	# The version has to be checked because of inkscape changed its behavior since version 0.91 for the FileClose verb.
	if [ "$version" -lt "91" ] 
	then
		inkscape --verb=FitCanvasToDrawing --verb=FileSave --verb=FileClose $svgfile
	else
		inkscape --verb=FitCanvasToDrawing --verb=FileSave --verb=FileClose --verb=FileQuit $svgfile
	fi
}

# resize image width height
function_resize(){
	#convert -trim -resize "$2x$3" $1 "$file.tmp"
	convert -resize "$2x$3" $1 "$file.png"
}


####################################################
######### Set of transformation functions ##########
####################################################
blur(){		#ID 0 
#sleep 1s
	radius=`expr $RANDOM % 3`
	sigma=`expr $RANDOM % 3`
	#convert -blur "${radius}x${sigma}" $1 "${outfile}.blur.png"
	convert_options="$convert_options -blur ${radius}x${sigma}"
	if [ $verbose -eq 1 ]
	then
		echo "==== Blur params===="
		echo "radius: $radius"
		echo "sigma: $sigma"
	fi
}

whitenoise(){	#ID 1
	at=0.05
	#convert +noise Gaussian -attenuate $at $1 "${file}.noise.png"
	#convert +noise Impulse -attenuate $at $1 "${outfile}.noise.png"
	convert_options="$convert_options +noise Impulse -attenuate $at"
	if [ $verbose -eq 1 ]
	then
		echo "==== Whitenoise params ===="
		echo "attenuation: $at"
	fi
}

grayscale(){	#ID 2
	#convert -colorspace Gray $1 "${outfile}.grayscale.png"
	convert_options="$convert_options -colorspace Gray"
	if [ $verbose -eq 1 ]
	then
		echo "==== Grayscale params===="
		echo "colorspace: Gray"
	fi
}

colornegation(){	#ID 3
	#convert -negate $1 "${outfile}.invert.png"
	convert_options="$convert_options -negate"
	if [ $verbose -eq 1 ]
	then
		echo "==== ColorInvert params===="
		echo "negate"
	fi
}

modulatecolor(){	#ID 4
	bright=100
	saturation=80
	hue=`expr $RANDOM % 100`
#sleep 1s
	#convert -modulate "$bright,$saturation,$hue" $1 "${outfile}.colormodulation.png"
	convert_options="$convert_options -modulate $bright,$saturation,$hue"
	if [ $verbose -eq 1 ]
	then
		echo "==== Modulatecolor params===="
		echo "bright: $bright"
		echo "saturation: $saturation"
		echo "hue: $hue"
	fi
}

rotation(){	#ID 5
	angle=`expr $RANDOM % 360`
#sleep 1s
	#convert -rotate $angle $1 "${outfile}.rotate.png"
	convert_options="$convert_options -rotate $angle"
	if [ $verbose -eq 1 ]
	then
		echo "==== Rotation params ===="
		echo "angle: $angle"
	fi
}

waving(){	#ID 6
	amp=`expr $RANDOM % 10`
	lambda=`expr $RANDOM % 100`
	#convert -wave "${amp}x${lambda}" $1 "${outfile}.waved.png"
	convert_options="$convert_options -wave ${amp}x${lambda}"
	if [ $verbose -eq 1 ]
	then
		echo "==== Waving params ===="
		echo "amplitude: $amp"
		echo "lambda: $lambda"
	fi
}

editSVGTranslation(){	#ID 7
	#sed "s/m \([0-9]*\.[0-9]*\),\([0-9]*\.[0-9]*\)/m \1 \2/g"
	#grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*"
	lines=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | wc -l `
	#lines=`grep -E path $1 | wc -l`
	ln=`expr $RANDOM % $lines`
	let "ln+=1"
	#echo "**** ln $ln"
	if [ `expr $ln % 2` -eq 0 ] #check to add or subtract for dx
	then
		dx="1.0`expr $RANDOM % 100`"
	else
		dx="0.0`expr 100 - $RANDOM % 100`"
	fi
	if [ `expr $lines % 2` -eq 0 ] #check to add of subtract for dy
	then
		dy="1.0`expr $RANDOM % 100`"
	else
		dy="0.0`expr 100 - $RANDOM % 100`"
	fi
	#echo "~~~ dx $dx"
	#echo "~~~ dy $dy"
	#valx=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p | awk -F" " '{print \$2}' | awk -F"," '{print \$1}'`
	#valy=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p | awk -F" " '{print \$2}' | awk -F"," '{print \$2}'`
	val=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p`
	val=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p`
	#valy=`grep -E "m [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p`
	#echo "++- val $val"
	val=`echo $val | awk -F " " '{print \$2}'`
	#echo "+++ val $val"
	#valy=`awk -F " " '{print \$2}'`
	valx=`echo $val | awk -F "," '{print \$1}'`	
	valy=`echo $val | awk -F "," '{print \$2}'`	
	#echo ";;; valx $valx"
	#echo ";;; valy $valy"
	valfx=`echo "$dx * $valx" | bc -l`
	valfy=`echo "$dy * $valy" | bc -l`
	#echo "=== valfx $valfx"
	#echo "=== valfy $valfy"
	sed -i "s/m $valx,$valy/m $valfx,$valfy/" $1
	if [ "$verbose" -eq "1" ]
	then
		echo "==== editSVGTranslation params ===="
		echo "line number (after matching): $ln"
		echo "old x,y: $valx,$valy"
		echo "new x,y: $valfx,$valfy"
	fi
}

editSVGColor(){		#ID 8
	lines=`grep -E "fill:#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})" $1 | wc -l`
	ln=`expr $RANDOM % $lines`
	let "ln+=1"
	hexline=`grep -E "fill:#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})" $1 | sed -n ${ln},${ln}p`
	hexval=`echo $hexline | sed "s/.*#\([0-9a-fA-F]\{6\}\).*/\1/g"`
	red=`expr $RANDOM % 256`
	red=`echo "obase=16; $red" | bc`
	green=`expr $RANDOM % 256`
	green=`echo "obase=16; $green" | bc`
	blue=`expr $RANDOM % 256`
	blue=`echo "obase=16; $blue" | bc`
	nhexval="${red}${green}${blue}"
	sed -i "s/$hexval/$nhexval/" $1
	if [ "$verbose" -eq "1" ]
	then
		echo "==== editSVGColor params ===="
		echo "line number (after matching): $ln"
		echo "hexline: $hexline"
		echo "old color: $hexval"
		echo "new color: $nhexval"
	fi
}

editSVGBezier(){	#ID 9
	lines=`grep -E "c [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | wc -l `
	#echo 'grep -E "c [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | wc -l '
	ln=`expr $RANDOM % $lines`
	let "ln+=1"
	cval=`grep -E "c [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]* [-+]?[0-9]*\.?[0-9]*,[-+]?[0-9]*\.?[0-9]*" $1 | sed -n ${ln},${ln}p `
	#multiplier="0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.10"
	multiplier="1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0 4.2 4.4 4.6 4.8 5.0"
	rnd=`expr $RANDOM % 20 + 1`
	pp=`echo $multiplier | awk -F " " -v rnd=$rnd '{print $rnd}'`
	if [ "$verbose" -eq "1" ]
	then
		echo "==== editSVGBezier params ===="
		echo "line number (after matching): $ln"
		echo "multiplying factor:  $pp"
		echo "matching string: $cval"
	fi
	x1=`echo $cval | cut -d c -f 2 | cut -d " " -f 2 | cut -d , -f 1`
	y1=`echo $cval | cut -d c -f 2 | cut -d " " -f 2 | cut -d , -f 2`
	x2=`echo $cval | cut -d c -f 2 | cut -d " " -f 3 | cut -d , -f 1`
	y2=`echo $cval | cut -d c -f 2 | cut -d " " -f 3 | cut -d , -f 2`
	x=`echo $cval | cut -d c -f 2 | cut -d " " -f 4 | cut -d , -f 1`
	y=`echo $cval | cut -d c -f 2 | cut -d " " -f 4 | cut -d , -f 2 | cut -d\" -f 1` #last cut is for some cases on which the line ends with quotation marks
	#echo $x1
	#echo $y1
	#echo $x2
	#echo $y2
	#echo $x
	#echo $y
	nx1=`echo "$x1 * $pp" | bc`
	ny1=`echo "$y1 * $pp" | bc`
	nx2=`echo "$x2 * $pp" | bc`
	ny2=`echo "$y2 * $pp" | bc`
	nx=`echo "$x * $pp" | bc`
	ny=`echo "$y * $pp" | bc`
	sed -i "s/$x1,$y1 $x2,$y2 $x,$y/$nx1,$ny1 $nx2,$ny2 $nx,$ny/" $1 
}

####################################################
######### End of transformation functions ##########
####################################################

applyTransformations(){
	opt=`expr $RANDOM % 7`
#	opt=5
	case $opt in
		0)
			blur $1
		;;
		1)
			whitenoise $1
		;;
		2)
			grayscale $1
		;;
		3)
			colornegation $1
		;;
		4)
			modulatecolor $1
		;;
		5)
			rotation $1
		;;
		6)
			waving $1
		;;
	esac
	return $opt
}


function_2svg $inputfile
if [ $? -ne 0 ]
then
	echo "Error, formato de imagen no reconocido"
	exit 1
fi
function_resize $svgfile $height $width
#applyTransformations $svgfile 
#editSVGTranslation $svgfile
#editSVGColor $svgfile
#editSVGBezier $svgfile
#exit 0

#supports up to 7! transformations
for i in `seq 1 $num`
do
	#FIXME: Check repetions to avoid them
sleep 1s
	cp $svgfile ${svgfile}.old
	convert_options=""
	#tr=`expr $RANDOM % 128`
	tr=`expr $RANDOM % 1024`
	#echo $tr
	tblur=$(($tr&1))
	twhno=$(($tr&2))
	tgray=$(($tr&4))
	tnega=$(($tr&8))
	tmodu=$(($tr&16))
	trota=$(($tr&32))
	twave=$(($tr&64))
	tSVGTranslate=$(($tr&128))
	tSVGColor=$(($tr&256))
	tSVGBezier=$(($tr&512))
	if [ $tblur -eq 0 ]
	then
		blur
	fi
	if [ $twhno -eq 0 ]
	then
		whitenoise
	fi
	if [ $tgray -eq 0 ]
	then
		grayscale
	fi
	if [ $tnega -eq 0 ]
	then
		colornegation
	fi
	if [ $tmodu -eq 0 ]
	then
		modulatecolor
	fi
	if [ $trota -eq 0 ]
	then
		rotation
	fi
	if [ $twave -eq 0 ]
	then
		waving
	fi
	if [ $tSVGTranslate -eq 0 ]
	then
		editSVGTranslation $svgfile
	fi
	if [ $tSVGColor -eq 0 ]
	then
		editSVGColor $svgfile
	fi
	if [ $tSVGBezier -eq 0 ]
	then
		editSVGBezier $svgfile
	fi

	if [ $verbose -eq 1 ]
	then
		echo "convert $convert_options $svgfile $outfile"
		echo " "
	fi
	sc=`convert $convert_options $svgfile "$outfile.${i}.png"`
	mv ${svgfile}.old $svgfile
done

