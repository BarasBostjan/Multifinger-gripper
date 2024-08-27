function [torque] = readTorque(ID)   %reads the absolute torque value
    global port_num;            %declares global variables
    global PROTOCOL_VERSION; 
    readTorque = read2ByteTxRx(port_num, PROTOCOL_VERSION , ID, 126);    %reads the torque value
    if readTorque > 32767     %if the read torque is negative in signed number, it converts it to a positive decimal number, otherwise leaves the read torque unchanged
       torque = 65535 - readTorque;
    else
       torque = readTorque;
    end
end