# SW instructions for gripper control

This document provides instructions for using a MATLAB program designed to control a robotic gripper system, specifically with DYNAMIXEL XL430-W250 motors. It covers the necessary steps for hardware preparation, software configuration, and usage of the program’s core functions. By following these instructions, you can ensure the precise and reliable operation of the gripper system.

## Table of Contents
1. [Preparation](#preparation)
   1. [Setting Motor IDs](#setting-motor-ids)
   2. [Connecting Motors](#connecting-motors)
2. [MATLAB Program Overview](#matlab-program-overview)
3. [Basic Settings](#basic-settings)
4. [Calibration](#calibration)
   1. [When and Why to Calibrate?](#when-and-why-to-calibrate)
   2. [How to Calibrate?](#how-to-calibrate)
   3. [Calibration Parameters](#calibration-parameters)
   4. [Manipulating Calibration Parameters](#manipulating-calibration-parameters)
5. [Moving the Gripper Fingers](#moving-the-gripper-fingers)
   1. [Moving a Single Finger](#moving-a-single-finger)
   2. [Moving Multiple Fingers Simultaneously](#moving-multiple-fingers-simultaneously)
6. [Gripping](#gripping)
   1. [Gripping with a Single Finger](#gripping-with-a-single-finger)
   2. [Gripping with Multiple Fingers Simultaneously](#gripping-with-multiple-fingers-simultaneously)
   3. [Practical Tips for Gripping Functions](#practical-tips-for-gripping-functions)
7. [Other Functions](#other-functions)
   1. [Querying the Current Motor Rotation](#querying-the-current-motor-rotation)
   2. [Querying the Current Motor Torque](#querying-the-current-motor-torque)

## Preparation

### Setting Motor IDs

Before running the MATLAB code, it is necessary to set the IDs (addresses/sequence numbers) for the gripper motors. Each motor must be individually connected to the controller and the power supply. The motor has two connectors, allowing the first connector to be connected to the controller via a cable and the second to the power supply, regardless of which is the first or second connector on the motor. Then, launch the Dynamixel program `DYNAMIXEL Wizard 2` to set the motor IDs. The MATLAB program assumes the motor IDs are 1, 2, and 3, so these IDs must be set in the Dynamixel program. If multiple motors with the same ID are connected to the `DYNAMIXEL Wizard 2`, the program will not recognize them.

### Connecting Motors

Next, all gripper motors must be correctly connected. The motors are connected in series (the cable from the previous motor connects to the first connector of the next motor, and the second connector of the next motor connects to the following motor). The first motor in the series is connected to the controller, and the last to the power supply. This concludes the preparation.

## MATLAB Program Overview

The program was written using MATLAB version R2022b.

The MATLAB program operates as follows:
- Between lines 1 and 30, the program loads the necessary libraries, stores the addresses used by the motors, and prepares to connect the motors to MATLAB. These addresses are only valid for DYNAMIXEL XL430-W250 motors and should not be changed for the program to function correctly.
  
- Between lines 31 and 70, the program establishes a connection between MATLAB and the motors.
  
- In the following 20 lines, the basic motor settings are configured, including setting the motor operation mode and the maximum rotation speed. Calibration parameters and the default rotation speed are also set here.
  
- By line 103, the motors are turned on, and the program displays any connection errors.
  
- The main part of the program, marked with the comment "Main," contains the commands or functions that control the gripper.
  
- After the main section, the motors are turned off, and the connection between the motors and MATLAB is terminated.
  
- At the end of the program, all functions used to control the gripper are declared.

## Basic Settings

It is possible to change the operating mode and maximum rotation speed of individual motors. Since the program's functions rely on these settings, it is advisable to leave them as they are. The `offset` and `max` lists can be set after all fingers have been calibrated to avoid recalibrating every time the program runs (except in the cases mentioned below). The last parameter that can be set here is `defaultSpeed`, which determines the speed at which the motors will rotate during movement and gripping functions if no specific speed is provided. The value ranges from 0 to 100, indicating the percentage of the motor's rotation speed, where 0% means the motor is stationary, and 100% represents the maximum rotation speed.

Parameter settings between lines 81 and 87 of the MATLAB program:

```matlab
global offset;
offset = [-7288 -16642 2943];

global max;
max = [23608 23608 23608];

global defaultSpeed;
defaultSpeed = 50;
```

## Calibration

### When and Why to Calibrate?

Calibration is required whenever the gripper is restarted or the gripper configuration is changed. Dynamixel XL430-250-T motors have absolute encoders for only one motor revolution. Multiple revolutions are measured incrementally, so the motor's rotation resets to a value within the first revolution (a number between 0 and 4095) each time it is powered off and on. Configuration changes can alter the working range of each finger. If calibration is not performed in the above scenarios, the finger may move out of its working range during program operation, potentially causing mechanical damage to the finger (e.g., gear breakage).

### How to Calibrate?

Calibration can be performed using the calibrate function. This function requires the motor ID for which calibration is desired. The function definition is as follows:

```matlab
calibrate(ID)
```

Calibration involves the motor closing the finger until it detects that the finger has reached the most closed angle for a given configuration. This is detected by measuring the motor torque, which increases beyond a certain threshold when the finger reaches the end angle. This angle is saved, then the motor reverses direction and similarly detects the other extreme angle of the finger, which is also saved. From the maximum and minimum angles, the function determines the global `offset` and `max` lists for the calibrated motor. Before calibrating, it is important to ensure that there is no object on the gripper, as the `calibrate` function expects the entire working range of the finger. The `offset` and `max` lists store motor calibration data. The `offset` list contains motor rotations at the most closed angle of the finger, while the `max` list contains data on the difference between the motor rotation at the most closed and most open angles of the finger.

The following MATLAB code demonstrates gripper calibration using the calibrate function:

```matlab
calibrate(1)
calibrate(2)
calibrate(3)
```

### Calibration Parameters

The `offset` and `max` lists store motor calibration data. The `offset` list contains motor rotations at the most closed position of the finger, while the `max` list contains data on the difference between the motor rotation at the most closed and most open positions of the finger.

These lists can be defined in the basic MATLAB program settings (see [Basic Settings](#basic-settings)). Calibration can be performed once, and the calibration parameters can then be entered into the basic settings. If the program is run multiple times, the fingers do not need to be recalibrated (unless the motors have been powered off or the gripper configuration has changed).

### Manipulating Calibration Parameters

It is often desirable for all fingers to have the same extreme positions. Some configurations result in fingers being calibrated to very similar extreme positions, while others may result in significantly different positions. To address this issue, the functions `calculateEqualMinimalMax` or `calculateEqualMax` can be used.

- The function `calculateEqualMinimalMax` does not take any input variables and does not return any values. When called, it modifies the offset and `max` lists to set the difference between the maximum and minimum positions of all fingers to the smallest difference between the maximum and minimum positions of any finger from the previous calibration. If executed correctly, the `max` list should contain identical values. After executing this function, the fingers will still have the same positions when fully open, but only the most closed positions of the fingers will change. This function is usually called immediately after finger calibration:

```matlab
calibrate(1)
calibrate(2)
calibrate(3)
calculateEqualMinimalMax()
```

- The function `calculateEqualMax` accepts one input variable, determining the difference between the maximum and minimum positions of all fingers. This function modifies the `offset` and `max` lists accordingly. If executed correctly, the `max` list should contain identical values. The function does not return any values. After executing this function, the fingers will still have the same positions when fully open, but only the most closed positions of the fingers will change. This function is usually called immediately after finger calibration.

In the example below, the fingers are first calibrated, and then the most closed position of the fingers is set to a value of 20,000 (i.e., the motor can rotate up to 20,000 pulses):

```matlab
calibrate(1)
calibrate(2)
calibrate(3)
calculateEqualMax(20000)
```

## Moving the Gripper Fingers

### Moving a Single Finger

To move one of the fingers to a specific angle, use the `moveOne` function. This function accepts three input variables. The first determines the motor ID or finger number, the second specifies the final angle of the finger, and the third is optional and determines the speed of the finger's movement. The function is defined as follows:

```matlab
moveOne(ID, moveTo)
moveOne(ID, moveTo, speed)
```

- The ID is entered as the number 1, 2, or 3.
  
- The final angles are recorded as a number between 0 and 100, representing the percentage of the finger's closure, where 0% is a fully open finger and 100% is a fully closed finger.
  
- If the third input variable is not entered, the function will determine the speed based on the global variable defaultSpeed, defined in the basic settings (see [Basic Settings](#basic-settings)).
  
- To control the finger's speed, enter the third input variable as a number between 0 and 100, representing the percentage of the motor's rotation speed, where 0% is a stationary motor, and 100% is the maximum rotation speed of the motor.

The following MATLAB code demonstrates the use of the moveOne function:

```matlab
moveOne(2, 50)
moveOne(1, 70, 100)
```

The first line closes finger number 2 to 50 %, with the speed determined by the basic settings. The second line closes finger number 1 to 70 % at 100 % speed.

### Moving Multiple Fingers Simultaneously

To move multiple fingers to specific angles simultaneously, use the moveAll function. This function can accept 1, 3, or 4 input variables and is defined as follows:

```matlab
moveAll(moveAllTo)
moveAll(move1To, move2To, move3To)
moveAll(move1To, move2To, move3To, speed)
```

- If only one input variable is entered into the function, it assumes that all three fingers should be moved to the same angles. As with the moveOne function, this value is entered as a number between 0 and 100, representing the percentage of the maximum angle. The fingers will move at a speed determined by the global variable `defaultSpeed`.

- If three input variables are entered into the function, each finger will be moved to its specified angle. From left to right, the variables represent the desired angles for fingers with IDs 1, 2, and 3. In this case, the function will respect the speed value recorded in the global variable `defaultSpeed` (see [Basic Settings](#basic-settings)). The function ensures that all fingers start and stop moving simultaneously. This means that if the fingers need to move different distances, the motor speeds will not be the same. The finger that needs to move the farthest will move at the default speed, while the other two fingers will move more slowly in proportion to the requirement for simultaneous movement.

- If four input variables are entered into the function, it will behave the same as when three variables are entered, except that in this case, the fourth variable determines the speed of the finger movement. The function will take the value entered in the fourth position, which must be recorded as a number between 0 and 100, representing the percentage of the maximum possible motor rotation speed. As with the three-variable case, only the finger that needs to move the farthest will move at the entered speed, while the other two fingers will move more slowly in proportion to the requirement for simultaneous movement.

The following MATLAB code demonstrates the use of the moveAll function:

```matlab
moveAll(30)
moveAll(30, 50, 70)
moveAll(30, 50, 70, 80)
```
The first line of code closes all fingers to 30%, with the speed determined by the basic settings. The second line of code closes the first finger to 30%, the second finger to 50%, and the third finger to 70%, with the speed determined by the basic settings. The third line closes all fingers to the same angles as the previous line but at 80% speed.

## Gripping

### Gripping with a Single Finger

To grip an object with only one finger, use the `grabOne` function. This function accepts three input variables and is defined as follows:

```matlab
grabOne(ID, torque)
grabOne(ID, torque, speed)
```

- The first variable determines the motor ID or finger number.
  
- The second determines the motor torque.
  
- The third is optional and determines the speed of the finger's movement.
  
- The ID is entered as the number 1, 2, or 3.
  
- The motor torque is recorded as a number between 0 and 100, representing the percentage of the maximum allowable motor torque, where 0% means the motor exerts no torque and 100% means the motor exerts the maximum allowable torque.
  
- If the third input variable is not entered, the function will determine the speed based on the global variable `defaultSpeed`, defined in the basic settings (see [Basic Settings](#basic-settings)).
  
- To control the finger's speed, enter the third input variable as a number between 0 and 100, representing the percentage of the motor's rotation speed, where 0% is a stationary motor, and 100% is the maximum rotation speed of the motor.

The function works by gradually closing the finger until the measured torque on the motor exceeds the desired torque. At that point, the motor stops, and the finger remains stationary.

The following MATLAB code demonstrates the use of the `grabOne` function:

```matlab
grabOne(2, 50)
grabOne(1, 70, 100)
```

The first line of code grips with finger number 2 at 50 % torque, with the speed determined by the basic settings. The second line of code grips with finger number 1 at 70 % torque and 100 % speed.

### Gripping with Multiple Fingers Simultaneously

To grip an object with multiple fingers simultaneously, use the `grabAll` function. This function can accept 1, 3, 4, or 6 input variables and is defined as follows:

```matlab
grabAll(torqueAll)
grabAll(torque1, torque2, torque3)
grabAll(torque1, torque2, torque3, speedAll)
grabAll(torque1, torque2, torque3, speed1, speed2, speed3)
```

- If only one input variable is entered into the function, it assumes that all fingers should grip with the same desired maximum torque on all motors. Enter the desired maximum torque value as the sole input variable. The value must be recorded as a number between 0 and 100, which, similar to the `grabOne` function, determines the maximum desired torque value as a percentage of the maximum allowable torque. The fingers will move at a speed determined by the global variable `defaultSpeed` (see [Basic Settings](#basic-settings)). The function begins closing all fingers simultaneously. When the measured torque on any finger exceeds the desired torque, that motor stops, and the finger remains stationary. This action does not affect the other fingers, which can continue moving until all fingers stop due to the conditions mentioned above. The function terminates when all fingers stop. If you want to grip with only two or just one finger, enter a value of 0 for the torque of the motor you do not want to move.

- If three input variables are entered into the function, it will behave the same as with one input variable, except that each motor will stop rotating at its specified maximum torque. From left to right, the three maximum desired torques for motors with IDs 1, 2, and 3 are specified. For each of the three variables, enter a value between 0 and 100, the same as in the previous case and similar to the `grabOne` function. The fingers will move at a speed determined by the global variable `defaultSpeed`.

- If four input variables are entered into the function, it will behave the same as with three input variables, except that now the fourth variable determines the speed of the finger movement. The function takes the value entered in the fourth position instead of the global variable `defaultSpeed`, which must be recorded as a number between 0 and 100, representing the percentage of the maximum possible motor rotation speed. In this case, all three fingers will move at the same entered speed.

- If six input variables are entered into the function, it will behave the same as with three input variables, except that now the last three variables determine the speeds of the fingers' movements. The function takes the values entered in the last three positions instead of the global variable `defaultSpeed`, arranged from left to right as the speeds for motors with IDs 1, 2, and 3. The values must be recorded as a number between 0 and 100, representing the percentage of the maximum possible motor rotation speed.

The following MATLAB code demonstrates the use of the grabAll function:

```matlab
grabAll(30)
grabAll(30, 50, 70)
grabAll(30, 50, 70, 80)
grabAll(30, 50, 70, 20, 60, 80)
```

The first line of code grips with all fingers at 30 % torque, with the speed determined by the basic settings. The second line grips with 30 % torque on the first finger, 50 % on the second finger, and 70 % on the third finger, with the speed determined by the basic settings. The third line grips with the same torques as the previous line, but this time the fingers move at 80 % speed. The last line grips with the same torque as the previous two lines, but now the first motor moves at 20 % speed, the second at 60 % speed, and the third at 80 % speed.

### Practical Tips for Gripping Functions

The `grabAll` function can also be used to move only 2 or just 1 motor. This is done by setting either the desired maximum torque or the speed of the finger that you want to remain stationary to 0. If possible, it is better to set the speed to 0 because in this case, the motor is not initialized, whereas if only the torque is set to 0, the motor will still attempt to move momentarily until it measures the minimum torque. Correct usage examples:

```matlab
grabAll(40, 50, 0, 80)
grabAll(40, 50, 50, 50, 50, 0)
```

In both of the above examples, we grip with the first two fingers while the third finger remains stationary. In the first line of MATLAB code, the third motor's torque is set to 0, while in the second line, the third motor's speed is set to 0.

When setting the desired maximum torque, ensure that it is not set too low. The motor exerts some torque even when it is just moving freely. A general rule of thumb is that this value should be set to at least 30%, otherwise, the motor may stop immediately. At the upper end, nothing limits the user from setting the desired maximum torque above 100%. The motors driving the fingers are strong enough to generate even more than 300% of the maximum allowable torque, but this would likely result in mechanical failure (e.g., the worm gear could break). 100% was chosen in this MATLAB program based on experience with the fingers and represents a confident value at which the fingers should never be damaged. It is possible to go above 100%, but there is no guarantee that the finger will remain undamaged.

## Other Functions

### Querying the Current Motor Rotation

To query the current rotation of a motor for one of the fingers, use the `readRotation` function. This function accepts one input variable that determines the motor ID and returns the current motor rotation value. The value returned by the function already accounts for calibration parameters, so the function would return a rotation of 0 in the most closed position of the finger and the value of the `max` list for the motor with the given ID in the most open position. For other finger positions, the value will fall somewhere between these two values. Example query for the current rotation of the second motor:

```matlab
currentRotation = readRotation(2)
```

### Querying the Current Motor Torque

To query the current torque value on a motor for one of the fingers, use the `readTorque` function. This function accepts one input variable that determines the motor ID and returns the current torque value on that motor. The function always returns a positive torque value, regardless of the direction of torque on the motor. Example query for the current torque on the second motor:

```matlab
currentTorque = readTorque(2)
```
