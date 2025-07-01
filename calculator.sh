#!/bin/bash

# Prints a welcome message
echo "Simple Calculator in Bash"
echo "Press Ctrl+C or type 'exit' to close."
echo ""

# Infinite loop to keep the calculator running
while true; do
    # Reads the first number
    read -p "Enter the first number: " num1
    # Checks if the user wants to exit
    if [[ "$num1" == "exit" ]]; then
        break
    fi

    # Reads the operation
    read -p "Enter the operation (+, -, *, /): " op

    # Reads the second number
    read -p "Enter the second number: " num2
    # Checks if the user wants to exit
    if [[ "$num2" == "exit" ]]; then
        break
    fi

    # Uses a case statement to determine which operation to perform
    case $op in
        "+")
            # Performs addition using 'bc'
            resultado=$(echo "$num1 + $num2" | bc -l)
            ;;
        "-")
            # Performs subtraction using 'bc'
            resultado=$(echo "$num1 - $num2" | bc -l)
            ;;
        "*")
            # Performs multiplication using 'bc'
            # The asterisk is escaped with \ to not be interpreted by the shell
            resultado=$(echo "$num1 * $num2" | bc -l)
            ;;
        "/")
            # Checks for division by zero
            if (( $(echo "$num2 == 0" | bc -l) )); then
                echo "Error: Division by zero is not allowed."
                continue # Returns to the beginning of the loop
            fi
            # Sets precision (scale) to 4 decimal places and performs division
            resultado=$(echo "scale=4; $num1 / $num2" | bc -l)
            ;;
        *)
            # If the operation is invalid
            echo "Error: Invalid operation."
            continue # Returns to the beginning of the loop
            ;;
    esac

    # Prints the result
    echo "Result: $resultado"
    echo "" # Adds a blank line for better readability
done

echo "Goodbye!"