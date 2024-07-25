%The function moveAll moves all motors to the desired position. You can enter only one position, which moves all motors to the same position, 3 positions for each motor separately, and you can also specify the speed of movement with the 4th entered value. All parameters are entered in percentages. Remember: Only one speed can be set, as the function determines this speed only for the finger that needs to make the most significant move, and sets a new speed for the other fingers, which is less than or equal to the desired speed, so that all motors start and finish moving at the same time.
function [] = moveAll(position1, position2, position3, speed)    
    global max              %declares global variables
    global offset
    global port_num
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 1     %if only one value is entered, this value represents the desired position for all fingers. The speed is set to the default speed
            position2 = position1;
            position3 = position1;
            speed = defaultSpeed;
        case 3     %If 3 values are entered, these are the 3 position values for each finger separately. The speed is set to the default speed
            speed = defaultSpeed;
        case 4     %If 4 values are entered, the first 3 values are the position values for each finger separately. The 4th value sets the speed of movement of the fingers
        otherwise
            disp('Invalid number of inputs')            %if you enter another number of parameters, the function reports an error in the console
    end
    location1 = max(1) * (100 - position1) / 100 + offset(1);            %converts the position in percentages to a position that the motor understands. It also considers calibration parameters
    location2 = max(2) * (100 - position2) / 100 + offset(2);
    location3 = max(3) * (100 - position3) / 100 + offset(3);
    currentLocation1 = readRotation(1) + offset(1);      %reads the current finger location (The offset is added because the positions in the previous lines are already prepared for motor movement, readRotation already considers the offset. Simply put: either the offset is added in the previous lines and these lines, or it isn't in both.)
    currentLocation2 = readRotation(2) + offset(2); 
    currentLocation3 = readRotation(3) + offset(3); 
    delta1 = abs(location1 - currentLocation1);     %calculates the change in position between the current and final position
    delta2 = abs(location2 - currentLocation2); 
    delta3 = abs(location3 - currentLocation3); 
    if delta1 >= delta2 && delta1 >= delta3       %finds the finger that needs to make the most significant move and assigns it the desired speed. The other two fingers are proportionally assigned a speed based on the change in position
        speed1 = speed;
        speed2 = delta2 / delta1 * speed;
        speed3 = delta3 / delta1 * speed;
    elseif delta2 >= delta1 && delta2 >= delta3
        speed2 = speed;
        speed1 = delta1 / delta2 * speed;
        speed3 = delta3 / delta2 * speed;
    else
        speed3 = speed;
        speed1 = delta1 / delta3 * speed;
        speed2 = delta2 / delta3 * speed;
    end
    if location1 < 0    %If the location is negative, add "period" because the motor understands only binary signed numbers
        location1 = location1 + 4294967296;
    end
    if location2 < 0
        location2 = location2 + 4294967296;
    end
    if location3 < 0
        location3 = location3 + 4294967296;
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 112, speed1 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 112, speed2 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 112, speed3 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 116, location1);  %sets the position
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 116, location2);  %sets the position
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 116, location3);  %sets the position
    pause(0.1);   %waits for the motors to start moving (similar to moveOne)
    movement1 = 1;
    movement2 = 1;
    movement3 = 1;
    while movement1 == 1 || movement2 == 1 || movement3 == 1    %waits for all motors to stop moving
        movement1 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 122);
        movement2 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 122);
        movement3 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 122);
    end
end