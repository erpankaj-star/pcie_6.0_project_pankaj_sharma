#database -open  waves -into -default waves.shm # this is wrong order

database -open waves -into waves.shm -default

probe -create -shm -all -depth all tb_top

run

exit
