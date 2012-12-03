#!/bin/bash
#ppd.sh
#Партионная почта - Доставка
#Version 0.1

#Начало записи лога
date "+%A %d %B %Y %T" >> log;

#Инициализация переменных
declare -a rpo_array[14];
pos_param=;
param=;
blank=;
form=;
quantity=;
fake=;
visual_counter=0;
lock=1;
rpo=;
input=;
family=;
initials=;
street=;
flat=;
repeat=;
repeat_continue=0;
temp=;
temp2=;
temp3=;
length=;
#Инициализация переменных счётчиков
counter=;
i=;
j=0;

#Считывание позиционных параметров
pos_param=$#;
if [ $pos_param != 0 ]; then
for (( i=0; $i<$pos_param; i++ )); do
param=$1;
case $param in
( -b | --blank )
	shift;
	if [ -z $1 ]; then
		cat readme;
		exit;
	fi;
	if [ $1 = 1 ] || [ $1 = 2 ]; then
		 blank=$1;
	else
		cat readme;
		exit;
	fi;
	shift;
	i=$(($i+1));
	continue;;
( -t | --old | --new )
	if [ $param = "-t" ]; then
		shift;
		if [ -z $1 ]; then
			cat readme;
			exit;
		fi;
		if [ $1 = "o" ] || [ $1 = "n" ]	; then
		form=$1;
		else
			cat readme;
			exit;
		fi;
	elif [ $param = "--old" ]; then form=o;
	elif [ $param = "--new" ];then form=n;
	fi;
	shift;
	i=$(($i+1));
	continue;;
( -q | --quantity )
	shift;
	if [ -z $1 ]; then
		cat readme;
		exit;
	fi;
	if [ $1 -gt 0 ]; then
		quantity=$1;
	else
		cat readme;
		exit;
	fi;
	shift;
	i=$(($i+1));
	continue;;
( -f | --fake )
	fake=fake;
	shift;
	i=$(($i+1));
	continue;;
( -c | --counter )
	visual_counter=1;
	shift;
	i=$(($i+1));
	continue;;
( -h | --help )
	cat readme;
	exit;;
	* ) head -n 2 readme;
	exit;;
esac;
shift;
done;
fi;
if [ -z $quantity ]; then quantity=100; fi;
if [ -z $blank ] && [ -z $form ]; then blank=2; fi;
if [ -z $blank ] && [ -n "$form" ]; then blank=2; fi;
if [ -z $form ] && [ $blank = 2 ]; then form=n; fi;
if [ $blank = 1 ] && [ "${#form}" -gt 0 ]; then 
	echo "Параметры -t|--old|--new могут устанавливаться только совместно с параметром --blank 2";
	exit;
fi;
if [ -n "$fake" ] && [ $blank = 1 ]; then
	echo "Параметр -f|--fake может применяться только совместно с параметром --blank 2";
	exit;
fi;

while [ -a lock$lock ]; do
lock=$(($lock+1));
done;
echo $quantity >> lock$lock;
mkdir work$lock;
cp work.tar.bz2 work$lock/;
cd work$lock/;
tar -xjf work.tar.bz2;

#
#Ввод данных
#
#Создание файла данных
sed -n 1p begin$blank$form$fake >> content.xml;
echo -n `sed -n 2p begin$blank$form$fake` >> content.xml;
clear;
echo "Количество: $quantity" >> ../log;
echo -n "Начало ввода: " >> ../log;
date +%T >> ../log;

#Считывание ШПИ через веб-камеру
#zbarcam --nodisplay --raw >> rpo.txt &
zbarcam --raw >> rpo.txt &

for (( counter=1; $counter<=$quantity; counter++ )); do
temp=;
temp2=;
temp3=;
j=0;
#Ввод ШПИ
if [ "$repeat" = "rpo" ] || [ "$repeat" = "" ]; then
if [ $visual_counter -eq 1 ]; then
	echo "№$counter из $quantity";
fi;
echo "Введите ШПИ:";
while [ "`tail -n 1 rpo.txt`" = "$rpo" ] && [ $j -lt 6 ]; do
	sleep 1;
	j=$(($j+1));
done;
if [ "$rpo" = "`tail -n 1 rpo.txt`" ]; then
	echo -n "Ошибка считывания. Введите ШПИ вручную: ";
	read rpo;
	echo $rpo >> rpo.txt;
	else rpo=`tail -n 1 rpo.txt`;
fi;
if [ "${#rpo}" -lt 14 ]; then
		echo "Ошибка ввода. Попробуйте ещё раз.";
		echo;
		counter=$(($counter-1));	
		continue;
fi;
if [ "${rpo:0:6}" = 102536 ] || [ "${rpo:0:6}" = 102743 ] || [ "${rpo:0:6}" = 102428 ] || [ "${rpo:0:6}" = 102453 ] || [ "${rpo:0:6}" = 102466 ] || [ "${rpo:0:6}" = 102469 ] || [ "${rpo:0:6}" = 102470 ] || [ "${rpo:0:6}" = 102471 ] || [ "${rpo:0:6}" = 102472 ] || [ "${rpo:0:6}" = 102473 ]; then
	for (( i=0; $i<14; i++ )); do
		rpo_array[$i]="${rpo:$i:1}";
	done;
	for (( i=0; $i<13; i=$(($i+2)) )); do
		temp2=$(($temp2+${rpo_array[$i]}));
	done;
		temp2=$(($temp2*3));
	for (( i=1; $i<12; i=$(($i+2)) )); do
		temp3=$(($temp3+${rpo_array[$i]}));
	done;
	temp2=$(($temp2+$temp3));
	temp3=0;
	temp=$temp2;
	while (($temp2%10)); do
		temp3=$(($temp3+1));
		temp2=$(($temp+$temp3));
	done;
	if [ "${rpo_array[13]}" != "$temp3" ]; then
		echo "Ошибка ввода. Попробуйте ещё раз.";
		echo;
		counter=$(($counter-1));	
		continue;
	fi;
	else
	echo "Ошибка ввода. Попробуйте ещё раз.";
	echo;
	counter=$(($counter-1));	
	continue;
fi;
echo $rpo;
fi;
#Ввод входящего номера
if [ "$repeat" = "input" ] || [ "$repeat" = "" ]; then
echo "Введите входящий номер [$input]:";
read temp;
if [ "$temp" != "" ]; then input=$temp; fi;
fi;
#Ввод фамилии
if [ "$repeat" = "family" ] || [ "$repeat" = "" ]; then
echo "Введите фамилию [$family]:";
read temp;
if [ "$temp" != "" ]; then
#Вызов встроенной справки по использованию команд ввода/изменения фамилий
	if [ "$temp" = "?" ]; then
		echo;
		echo "Использование встроенных команд:";
		echo '"=" - пытается изменить фамилию на фамилию противоположного пола';
		echo '"+СИМВОЛЫ", "=СИМВОЛЫ" - добавляет СИМВОЛЫ к окончанию текущей фамилии';
		echo '"+-ФАМИЛИЯ", "=-ФАМИЛИЯ" - добавляет ФАМИЛИЮ к текущей (для создания двойной)';
		echo '"-СИМВОЛЫ" - удаляет СИМВОЛЫ из окончания текущей фамилии';
		echo '"--ФАМИЛИЯ" - удаляет ФАМИЛИЮ (только вторую!) из текущей двойной фамилии';
		echo '"?" - вывод этой справки';
		repeat=family;
		repeat_continue=1;
		counter=$(($counter-1));
		continue;
	fi;
#Проверка ввода пользователем пустых команд "+"/"-"	
	if [ "${temp:2:1}" = "" ] && ([ "${temp:1:1}" = "+" ] || [ "${temp:1:1}" = "-" ] || [ "${temp:1:1}" = "=" ]); then
		echo "Ошибка ввода. Попробуйте ещё раз";
		echo;
		repeat=family;
		repeat_continue=1;		
		counter=$(($counter-1));
		continue;
#Простая замена "йи"("ой")/"ая" и ""/"а" по команде "="
#Первый проход для одиночной/первой части двойной фамилии 
	elif [ "$temp" = "=" ]; then
		temp2=`echo $family| sed "s/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\u\1/"`;
		temp3=`echo $family| sed "s/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\u\3/"`;
		temp=$((`echo "${#temp2}"`-2));
		if [ "${temp2:$temp:2}" = "ая" ]; then
			temp2=`echo $temp2| sed "s/\([А-Яа-я]*\)\("${temp2:$temp:2}"\)/\1ий/"`;
		elif [ "${temp2:$temp:2}" = "ий" ] || [ "${temp2:$temp:2}" = "ой" ]; then
			temp2=`echo $temp2| sed "s/\([А-Яа-я]*\)\("${temp2:$temp:2}"\)/\1ая/"`;
		fi;
		temp=$((`echo "${#temp2}"`-1));
		if [ "${temp2:$temp:1}" = "а" ]; then
			temp2=`echo $temp2| sed "s/\([А-Яа-я]*\)\("${temp2:$temp:1}"\)/\1/"`;
		elif [ "${temp2:$temp:1}" != "й" ] && [ "${temp2:$temp:1}" != "я" ]; then
			temp2=`echo $temp2| sed 's/\([А-Яа-я]*\)/\1а/'`;
		fi;
		family=$temp2;
#Второй проход для второй части двойной фамилии
		if [ -n "$temp3" ]; then 
			temp=$((`echo "${#temp3}"`-2));
			if [ "${temp3:$temp:2}" = "ая" ]; then
				temp3=`echo $temp3| sed "s/\([А-Яа-я]*\)\("${temp3:$temp:2}"\)/\1ий/"`;
			elif [ "${temp3:$temp:2}" = "ий" ] || [ "${temp3:$temp:2}" = "ой" ]; then
				temp3=`echo $temp3| sed "s/\([А-Яа-я]*\)\("${temp3:$temp:2}"\)/\1ая/"`;
			fi;
			temp=$((`echo "${#temp3}"`-1));
			if [ "${temp3:$temp:1}" = "а" ]; then
				temp3=`echo $temp3| sed "s/\([А-Яа-я]*\)\("${temp3:$temp:1}"\)/\1/"`;
			elif [ "${temp3:$temp:1}" != "й" ] && [ "${temp3:$temp:1}" != "я" ]; then
				temp3=`echo $temp3| sed 's/\([А-Яа-я]*\)/\1а/'`;
			fi;
			family="$family-$temp3";
		fi;
#Добавление введённых пользователем символов к имеющейся фамилии
#по команде "+ЗНАЧЕНИЕ"
	elif ([ "${temp:0:1}" = "+" ] || [ "${temp:0:1}" = "=" ]) && [ "${temp:1:1}" != "-" ] && [ "${temp:1:1}" != "" ]; then
		temp=`echo $temp| sed 's/\(+*=*\)\([а-я]*\)/\2/'`;
		if [ "`echo $family| sed 's/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\3/'`" != "" ]; then
			family=`echo $family| sed "s/\([А-Яа-я]*\)-\([А-Яа-я]*\)/\1$temp-\2$temp/"`;
		else family=$family$temp;
		fi;
#Создание двойной фамилии из имеющейся и введённой пользователем
#по команде "+-ЗНАЧЕНИЕ"
	elif ([ "${temp:0:1}" = "+" ] || [ "${temp:0:1}" = "=" ])  && [ "${temp:1:1}" = "-" ] && [ "${temp:2:1}" != "" ]; then
		temp=`echo $temp| sed 's/\(+*=*\)\(-\)\([а-я]*\)/\u\3/'`;
		family="$family-$temp";
#Удаление из фамилии введённых пользователем символов
#по команде "-ЗНАЧЕНИЕ"
	elif [ "${temp:0:1}" = "-" ] && [ "${temp:1:1}" != "-" ] && [ "${temp:1:1}" != "" ]; then 
		temp=`echo $temp| sed 's/\(-\)\([а-я]*\)/\2/'`;
		if [ "`echo $family| sed 's/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\3/'`" != "" ]; then
		family=`echo $family| sed "s/\([А-Яа-я]*\)\($temp\)-\([А-Яа-я]*\)\($temp\)/\1-\3/"`;
		else
		family=`echo $family| sed "s/\([а-я]*\)\($temp\)/\1/"`;
		fi;
#Создание одиночной фамилии из двойной путём удаления пользлвателем
#второй части по команде "--ЗНАЧЕНИЕ"
	elif [ "${temp:0:1}" = "-" ] && [ "${temp:1:1}" = "-" ] && [ "${temp:2:1}" != "" ]; then
		temp=`echo $temp| sed 's/\(-\)\(-\)\([а-я]*\)/\2\u\3/'`;
		family=`echo $family| sed "s/\([а-я]*\)\($temp\)/\1/"`;
#Создание фамилии непсредственно из того, что ввёл пользователь
	else
		temp2=`echo $temp| sed "s/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\u\1/"`;
		temp3=`echo $temp| sed "s/\([А-Яа-я]*\)\(-*\)\([А-Яа-я]*\)/\u\3/"`;
		if [ -z "$temp3" ]; then
			family=$temp2;
		else family="$temp2-$temp3";
		fi;
	fi;
fi;
if [ $repeat_continue -eq 1 ]; then
	repeat="";
	repeat_continue=0;
fi;
fi;
#Ввод инициалов
if [ "$repeat" = "initials" ] || [ "$repeat" = "" ]; then
echo "Введите инициалы [$initials]:";
read temp;
if [ "$temp" != "" ]; then
	j=1;
	length=`echo "${#temp}"`;
	if [ "${temp:0:1}" = "*" ] && [ $length -gt 1 ]; then
		initials="";
		temp2="";
		for (( i=1; $i<$length; i++ )); do
			if [ "${temp:$i:1}" = " " ] || [ "${temp:$(($i+1)):1}" = "" ]; then
				temp2=`echo "${temp:$j:$(($i-$j+1))}"| sed 's/\([А-Яа-я]*\)/\u\1/'`;
				j=$(($i+1));
			fi;
			initials=$initials$temp2;
			temp2=;
		done;
	elif [ $length = 3 ]; then initials=`echo $temp| sed 's/\([а-я]\) \([а-я]\)/\u\1. \u\2./'`;
	elif [ $length = 5 ]; then initials=`echo $temp|sed 's/\([а-я]\) \([а-я]\) \([а-я]\)/\u\1. \u\2.-\3./'`;
	else
		echo "Ошибка ввода. Попробуйте ещё раз";
		echo "(инициалы через пробел или *ЗНАЧЕНИЕ для любого набора символов).";
		echo;
		repeat=initials;
		repeat_continue=1;
		counter=$(($counter-1));
		continue;
	fi;
fi;
if [ $repeat_continue -eq 1 ]; then
	repeat="";
	repeat_continue=0;
fi;
fi;
#Ввод улицы
if [ "$repeat" = "street" ] || [ "$repeat" = "" ]; then
echo "Введите улицу [$street]:";
read temp;
if [ "$temp" != "" ]; then
length=`echo "${#temp}"`;
for (( i=0; $i<$length; i++ )); do
if [ "${temp:$i:1}" = ' ' ]; then
	if [ $i = 1 ]; then
	street=`echo $temp| sed 's/\([а-я]\) \([а-я]*\)/\1. \u\2/'`;
	break;
	else street=`echo $temp| sed 's/\([а-я]*\) \([а-я]*\)/\u\1 \u\2/'`;
	break;
	fi;
fi;
done;
if [ $i = $length ]; then street=`echo $temp| sed "s/[а-я]/\u&/"`; fi;
fi;
fi;
#Ввод номера дома
if [ "$repeat" = "house" ] || [ "$repeat" = "" ]; then
echo "Введите номер дома [$house]:";
read temp;
if [ "$temp" != "" ]; then house=$temp; fi;
fi;
#Ввод номера квартиры
if [ "$repeat" = "flat" ] || [ "$repeat" = "" ]; then
echo "Введите квартиру [$flat]:";
read temp;
if [ "$temp" != "" ]; then
	if [ "$temp" = "+" ] || [ "$temp" = "=" ]; then
		flat=$(($flat+1));
	else flat=$temp;
	fi;
fi;
fi;

#Проверка правильности ввода

clear;
echo $input;
echo $family $initials;
echo $street $house\-$flat;
echo $rpo;
echo;
echo "Всё верно [Д/н]?";
read repeat;
while [ "$repeat" != "" ] && [ "$repeat" != "Д" ] && [ "$repeat" != "д" ]; do
	if [ "$repeat" = "Н" ] || [ "$repeat" = "н" ]; then
		repeat="";
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "Ш" ] || [ "$repeat" = "ш" ]; then
		repeat=rpo;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "В" ] || [ "$repeat" = "в" ]; then
		repeat=input;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "Ф" ] || [ "$repeat" = "ф" ]; then
		repeat=family;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "И" ] || [ "$repeat" = "и" ]; then
		repeat=initials;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "У" ] || [ "$repeat" = "у" ]; then
		repeat=street;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "С" ] || [ "$repeat" = "с" ]; then
		repeat=house;
		counter=$(($counter-1));
		continue 2;
	fi;
	if [ "$repeat" = "К" ] || [ "$repeat" = "к" ]; then
		repeat=flat;
		counter=$(($counter-1));
		continue 2;
	fi;
#Встроенная справка по использованию команд для частичного редактирования
#введённых данных
	echo "Использование:";
	echo '"д" - всё верно, переход к следующему письму (значение по умолчанию)';
	echo '"н" - ввод всей информации о данном письме заново';
	echo '"ш" - ввести другой ШПИ';
	echo '"в" - исправить входящий номер';
	echo '"ф" - исправить фамилию';
	echo '"и" - исправить инициалы';
	echo '"у" - исправить название улицы';
	echo '"с" - исправить номер дома (строения)';
	echo '"к" - исправить номер квартиры';
	echo "Что Вы хотите исправить?";
	echo "Или всё верно?";
	read repeat;
done;

#Запись данных в файл

case $blank in
1 )
for (( i=1; $i<=36; i++ )); do
	case $i in
	2 ) echo -n $input >> content.xml;;
	4 ) echo -n "$family " >> content.xml;;
	5 ) echo -n $initials >> content.xml;;
	7 ) echo -n "$street ">> content.xml;;
	8 ) echo -n "$house-" >> content.xml;;
	9 ) echo -n $flat >> content.xml;;
	11 ) echo -n "${rpo_array[0]} " >> content.xml;;
	12 ) echo -n "${rpo_array[1]} " >> content.xml;;
	14 ) echo -n "${rpo_array[2]} " >> content.xml;;
	16 ) echo -n "${rpo_array[3]} " >> content.xml;;
	18 ) echo -n "${rpo_array[4]} " >> content.xml;;
	20 ) echo -n "${rpo_array[5]}" >> content.xml;;
	22 ) echo -n "${rpo_array[6]} " >> content.xml;;
	24 ) echo -n "${rpo_array[7]}" >> content.xml;;
	26 ) echo -n "${rpo_array[8]} " >> content.xml;;
	27 ) echo -n "${rpo_array[9]} " >> content.xml;;
	29 ) echo -n "${rpo_array[10]} " >> content.xml;;
	31 ) echo -n "${rpo_array[11]} " >> content.xml;;
	33 ) echo -n "${rpo_array[12]}" >> content.xml;;
	35 ) echo -n "${rpo_array[13]}" >> content.xml;;
	* ) echo -n `sed -n "$i"p middle_var$blank$form` >> content.xml;;
	esac;
done;;
2 )
case $form in
	o )
	for (( i=1; $i<=32; i++ )); do
		case $i in
		1 ) echo -n $input >> content.xml;;
		3 ) echo -n "$family " >> content.xml;;
		4 ) echo -n $initials >> content.xml;;
		6 ) echo -n "$street ">> content.xml;;
		7 ) echo -n "$house-" >> content.xml;;
		8 ) echo -n $flat >> content.xml;;
		10 ) echo -n "${rpo_array[0]} " >> content.xml;;
		12 ) echo -n "${rpo_array[1]} " >> content.xml;;
		14 ) echo -n "${rpo_array[2]} " >> content.xml;;
		15 ) echo -n "${rpo_array[3]} " >> content.xml;;
		17 ) echo -n "${rpo_array[4]} " >> content.xml;;
		18 ) echo -n "${rpo_array[5]}" >> content.xml;;
		20 ) echo -n "${rpo_array[6]} " >> content.xml;;
		21 ) echo -n "${rpo_array[7]}" >> content.xml;;
		23 ) echo -n "${rpo_array[8]} " >> content.xml;;
		24 ) echo -n "${rpo_array[9]} " >> content.xml;;
		26 ) echo -n "${rpo_array[10]} " >> content.xml;;
		28 ) echo -n "${rpo_array[11]} " >> content.xml;;
		29 ) echo -n "${rpo_array[12]}" >> content.xml;;
		31 ) echo -n "${rpo_array[13]}" >> content.xml;;
		* ) echo -n `sed -n "$i"p middle_var$blank$form` >> content.xml;;
		esac;
	done;;
	n )
	for (( i=1; $i<=27; i++ )); do
		case $i in
		1 ) echo -n $input >> content.xml;;
		3 ) echo -n "$family " >> content.xml;;
		4 ) echo -n $initials >> content.xml;;
		6 ) echo -n "$street ">> content.xml;;
		7 ) echo -n "$house-" >> content.xml;;
		8 ) echo -n $flat >> content.xml;;
		10 ) echo -n "${rpo_array[0]} " >> content.xml;;
		11 ) echo -n "${rpo_array[1]} " >> content.xml;;
		12 ) echo -n "${rpo_array[2]} " >> content.xml;;
		13 ) echo -n "${rpo_array[3]} " >> content.xml;;
		14 ) echo -n "${rpo_array[4]} " >> content.xml;;
		15 ) echo -n "${rpo_array[5]}" >> content.xml;;
		17 ) echo -n "${rpo_array[6]} " >> content.xml;;
		18 ) echo -n "${rpo_array[7]}" >> content.xml;;
		20 ) echo -n "${rpo_array[8]} " >> content.xml;;
		21 ) echo -n "${rpo_array[9]} " >> content.xml;;
		22 ) echo -n "${rpo_array[10]} " >> content.xml;;
		23 ) echo -n "${rpo_array[11]} " >> content.xml;;
		24 ) echo -n "${rpo_array[12]}" >> content.xml;;
		26 ) echo -n "${rpo_array[13]}" >> content.xml;;
		* ) echo -n `sed -n "$i"p middle_var$blank$form` >> content.xml;;
		esac;
	done;;
esac;
esac;
if [ $counter != $quantity ]; then echo -n `cat middle_const$blank$form$fake` >> content.xml; fi;
input=$(($input+1));

#Формирование графического штрих-кода

barcode -b $rpo -g 100x20 -u mm -o rpo_$counter.pdf;
#barcode -b $rpo -o rpo_$counter.pdf;
#barcode -b $rpo -g 40x10 -u mm -o rpo_$counter.pdf;
done;

echo -n "Окончание ввода: " >> ../log;
date +%T >> ../log;
echo -n `cat end` >> content.xml;
killall zbarcam;
sleep 1;

#Формирование выходного файла и печать

rm notice/content.xml;
cp content.xml notice/;
cd notice/;
7z a -tzip notice.zip;
mv notice.zip notice.odt;
echo;
echo "Подготовка к печати...";
libreoffice --invisible --print-to-file notice.odt;
cp notice.ps ../
cd ..
ghostscript  -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=jpeg -r150 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dMaxStripSize=8192 -sOutputFile=page-%d.jpg notice.ps
if [ $blank = 1 ]; then
	temp1=+200;
	temp2=+50;
elif [ "$form" = "n" ]; then
	temp1=+310;
	temp2=+5;
elif [ "$form" = "o" ]; then
	temp1=+310;
	temp2=+36;
fi;
for (( counter=1; $counter<=$quantity; counter++ )); do
ghostscript  -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=tiff24nc -r200 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dMaxStripSize=8192 -sOutputFile=rpo_$counter.tif rpo_$counter.pdf;
convert rpo_$counter.tif -gravity SouthWest -crop 310x100+0+0 rpo_crop_$counter.tif;
#convert -resize 30% rpo_crop_$counter.jpg rpo_small_$counter.jpg;
convert rpo_crop_$counter.tif -transparent "rgb(255,255,255)" rpo_transparent_$counter.tif
composite -compose atop -geometry $temp1$temp2 rpo_transparent_$counter.tif page-$counter.jpg notice-$counter.tif;
done;
if [ $quantity -gt 99 ]; then quantity=99; fi;
for (( counter=1; $counter<=$quantity; counter++ )); do
mv notice-$counter.tif notice-$(printf %03d $counter).tif;
done;
convert notice-*.tif Notices.pdf;
lp -orientation-requested=3 Notices.pdf;
echo -n "Начало печати: " >> ../log;
date +%T >> ../log;
echo >> ../log;
#Удаление временных файлов
echo "Удаление временных файлов...";
ls -Q| grep -v "Notices.pdf" | xargs rm -r;
