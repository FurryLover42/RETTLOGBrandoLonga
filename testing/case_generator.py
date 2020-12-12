import sys
import random

starting = int(sys.argv[1])	#starting element
ending = int(sys.argv[2])	#ending element

f = open("random_test.txt", "w")

for i in range(ending - starting + 1):
	addr_list = []
	f.write("\t\t\t\twhen %d =>\n\n" % (starting + i))
	
	for j in range(9):
		random_num = random.getrandbits(7)
		f.write("\t\t\t\tRAM(%d) " %(j))
		f.write("<= assign(%d);\n" %(random_num))
		addr_list.append(random_num)

	#expected value calculation
	f.write("\t\t\t\t--expected ")

	expected = addr_list[8]	#default value, in case the address doesn't belong to any working zone
	result = 0
	for l in range(len(addr_list)-1):
		found = 0
		result = expected - addr_list[l]
		if(result <= 3):	#found a suitable wz
			found = l
			break
	
	if(found != 0):		#you found a wz, now its bin encoding is written on file
		expected_bin = '1' + format(found, '03b') + (("0001" if result == 0 else "0010") if result <= 1 else ("0100" if result == 2 else "1000"))
		f.write(expected_bin[:4] + '.' + expected_bin[4:])
		f.write(' ')
		f.write(str(hex(int(expected_bin, 2)))[2:])
		f.write(' ')
		f.write(str(int(expected_bin, 2)))
		f.write('\n\n')
	else:
		expected_bin = format(expected, '08b')
		f.write(expected_bin[:4] + '.' + expected_bin[4:])	#expected is still the default value, which is now encoded into 8 digit binary number
		f.write(' ')
		f.write(str(hex(expected)[2:]))
		f.write(' ')
		f.write(str(expected))
		f.write('\n\n')

f.close()	#close file