import sys
import random

starting = int(sys.argv[1])	#elemento da cui partire (compreso)
ending = int(sys.argv[2])	#elemento con cui finire (compreso)

f = open("random_test.txt", "w")

for i in range(ending - starting + 1):
	f.write("\t\t\t\twhen %d =>\n\n" % (starting + i))
	
	for j in range(9):
		f.write("\t\t\t\tRAM(%d) " %(j))
		f.write("<= assign(%d);\n" %(random.getrandbits(7)))

	f.write("\t\t\t\t--expected\n\n")
f.close()