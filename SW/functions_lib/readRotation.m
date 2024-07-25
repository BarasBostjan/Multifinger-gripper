function [currentRotation] = readRotation(ID)     %reads the current rotation value on the motor (considers calibration parameters)
    global offset;      %declares global variables
    global port_num;
    global PROTOCOL_VERSION ;
    rotation = read4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 132);     %reads the rotation from the motor
    if rotation > 2147483647
        currentRotation = rotation - 4294967295 - offset(ID);      %if it reads a negative signed number, it first converts it to a normal negative decimal number and then considers the offset
    else
        currentRotation = rotation - offset(ID);     %subtracts the offset from the read rotation
    end
end
