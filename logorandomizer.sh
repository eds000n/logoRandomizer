#!/bin/bash

#Options 
num=1
height=256
width=256
convert_options=""
while getopts "hf:n:r:" opt
do
	case $opt in
		h)
			echo "Form of use"
			echo "./logoRandomizer -f filename -n <number_of_images> -r <height>x<width>"
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
	echo "Blur"
#sleep 1s
	radius=`expr $RANDOM % 3`
	sigma=`expr $RANDOM % 3`
	#convert -blur "${radius}x${sigma}" $1 "${outfile}.blur.png"
	convert_options="$convert_options -blur ${radius}x${sigma}"
}

whitenoise(){	#ID 1
	echo "Whitenoise"
	at=0.05
	#convert +noise Gaussian -attenuate $at $1 "${file}.noise.png"
	#convert +noise Impulse -attenuate $at $1 "${outfile}.noise.png"
	convert_options="$convert_options +noise Impulse -attenuate $at"
}

grayscale(){	#ID 2
	echo "Grayscale"
	#convert -colorspace Gray $1 "${outfile}.grayscale.png"
	convert_options="$convert_options -colorspace Gray"
}

colornegation(){	#ID 3
	echo "ColorInvert"
	#convert -negate $1 "${outfile}.invert.png"
	convert_options="$convert_options -negate"
}

modulatecolor(){	#ID 4
	echo "Modulatecolor"
	bright=100
	saturation=80
	hue=`expr $RANDOM % 100`
#sleep 1s
	#convert -modulate "$bright,$saturation,$hue" $1 "${outfile}.colormodulation.png"
	convert_options="$convert_options -modulate $bright,$saturation,$hue"
}

rotation(){	#ID 5
	echo "Rotation"
	angle=`expr $RANDOM % 360`
#sleep 1s
	#convert -rotate $angle $1 "${outfile}.rotate.png"
	convert_options="$convert_options -rotate $angle"
}

waving(){	#ID 6
	echo "Waving"
	amp=`expr $RANDOM % 10`
#sleep 1s
	lambda=`expr $RANDOM % 100`
	#convert -wave "${amp}x${lambda}" $1 "${outfile}.waved.png"
	convert_options="$convert_options -wave ${amp}x${lambda}"
}

editsvg(){	#ID 7
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
editsvg $svgfile

#supports up to 7! transformations
for i in `seq 1 $num`
do
	#FIXME: Check repetions to avoid them
sleep 1s
	convert_options=""
	tr=`expr $RANDOM % 128`
	echo $tr
	tblur=$(($tr&1))
	twhno=$(($tr&2))
	tgray=$(($tr&4))
	tnega=$(($tr&8))
	tmodu=$(($tr&16))
	trota=$(($tr&32))
	twave=$(($tr&64))
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

	echo "convert $convert_options $svgfile $outfile"
	sc=`convert $convert_options $svgfile "$outfile.${i}.png"`
done









