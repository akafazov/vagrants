#!/bin/bash

# List of numbers
leafs=(1 2)
spines=(1 2)
TEMPLATE=configs/config-rack-X-leaf-Y.template

# Loop through each number in the list
for leaf in "${leafs[@]}"
do
    for spine in "${spines[@]}"
    do
        CONFIG=configs/config-rack-$leaf-leaf-$spine.sh
        echo "Config: $CONFIG"
        # Read from the template and replace 'X' with the current number
        # Then write the output to a new file named "output_$number.txt"
        sed "s/X/$leaf/g" $TEMPLATE | sed "s/Y/$spine/g" > "$CONFIG"
        

        # sed "s/X/$leaf/g" template.txt > "output_$number.txt"
        # sed "s/Y/$spine/g" template.txt > "output_$number.txt"
    done
done

# copy and execute configs
LEAFS=(1 2)
RACKS=(1 2)
for rack in "${RACKS[@]}"
do
    for leaf in "${LEAFS[@]}"
    do
        FILE=config-rack-$rack-leaf-$leaf.sh
        VM=rack-$rack-leaf-$leaf
        vagrant scp configs/$FILE $VM:$FILE
        vagrant ssh $VM -c "chmod +x $FILE"
        vagrant ssh $VM -c ./$FILE
    done
done
