clc;
clear all;

lib_name = 'dxl_x64_c';
% Load Libraries
if ~libisloaded(lib_name)
    [notfound, warnings] = loadlibrary(lib_name, 'dynamixel_sdk.h', 'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

 ADDR_TORQUE_ENABLE          = 64;
 ADDR_GOAL_POSITION          = 116;
 ADDR_PRESENT_POSITION       = 132;
 DXL_MINIMUM_POSITION_VALUE  = 0; % Dynamixel will rotate between this value
 DXL_MAXIMUM_POSITION_VALUE  = 4095; % and this value (note that the Dynamixel would not move when the position value is out of movable range. Check e-manual about the range of the Dynamixel you use.)
 BAUDRATE                    = 57600;
 global PROTOCOL_VERSION 
 PROTOCOL_VERSION            = 2.0;

 DEVICENAME                  = 'COM6'; 


 % Common Control Table Address and Data 
ADDR_OPERATING_MODE         = 11;          
OPERATING_MODE              = 3;            % value for operating mode for position control                                
TORQUE_ENABLE               = 1;            % Value for enabling the torque
TORQUE_DISABLE              = 0;            % Value for disabling the torque
DXL_MOVING_STATUS_THRESHOLD = 20;           % Dynamixel moving status threshold

COMM_SUCCESS                = 0;            % Communication Success result value
COMM_TX_FAIL                = -1001;        % Communication Tx Failed


% Initialize PortHandler Structs
% Set the port path
% Get methods and members of PortHandlerLinux or PortHandlerWindows
global port_num
port_num = portHandler(DEVICENAME);

% Initialize PacketHandler Structs
packetHandler();

index = 1;
dxl_comm_result = COMM_TX_FAIL;           % Communication result
dxl_goal_position = [DXL_MINIMUM_POSITION_VALUE DXL_MAXIMUM_POSITION_VALUE];         % Goal position

dxl_error = 0;                              % Dynamixel error
dxl_present_position = 0;                   % Present position


% Open port
if (openPort(port_num))
    fprintf('Succeeded to open the port!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to open the port!\n');
    input('Press any key to terminate...\n');
    return;
end


% Set port baudrate
if (setBaudRate(port_num, BAUDRATE))
    fprintf('Succeeded to change the baudrate!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to change the baudrate!\n');
    input('Press any key to terminate...\n');
    return;
end

% setup
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, 11, 4); % Nastavi operating mode (1-hitrost, 3-rotacija na enem obratu, 4-rotacija na več obratih)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 1, 44, 265); % Nastavi velocity limit (default je 265)

write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, 11, 4); % Nastavi operating mode (1-hitrost, 3-rotacija na enem obratu, 4-rotacija na več obratih)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 2, 44, 265); % Nastavi velocity limit (default je 265)

write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, 11, 4); % Nastavi operating mode (1-hitrost, 3-rotacija na enem obratu, 4-rotacija na več obratih)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 3, 44, 265); % Nastavi velocity limit (default je 265)

global offset;
offset = [-7288 -30429 -24634];  %pove pri kateri številki hočemo imeti odčitek enak 0. Torej če motor v skrajnem zaprtem položaju izpisuje -23379 potem mi tej vrednosti odštejemo offset, da nam pokaže 0. 
global max;
max = [23608  33309 26721];  %pove kakšen je maksimalen razmik med vrednostjo na motorju pri najbolj zaprtem in najbolj odprtem prstu. 
                            %V splošnem niso enake vrednosti vendar je idealno, če so (V nadaljevanju sta 2 funkciji za manipuliranje teh vrednosti)
global defaultSpeed;
defaultSpeed = 50;   %nastavitev osnovne hitrosti, ki jo prijemalo uporabi, če uporabnik ne specificira specifične hitrosti premikov v funkcijah


% Enable Dynamixel Torque
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
else
    fprintf('Dynamixel has been successfully connected \n');
end
% Main

%{
calibrate(2)
offset
max
%}

%{
grabOneReadTorque(2, 50)
pause(20)
moveOne(2, 0)
%}

%{
tic
calibrate(2)
toc
tic
moveOne(2, 50, 100)
t0 = toc
zapiranje = zeros(1, 100)
odpiranje = zeros(1, 100)
navor = zeros(1, 100)
rotacija = zeros(1, 100)
j = 1;
while j <= 10
    i = 1;
    while i <= 10
        tic
        navor(10 * j + i - 10) = grabOneReadTorque(2, 100, 100)
        zapiranje(10 * j + i - 10) = toc
        rotacija(10 * j + i - 10) = readRotation(2)
        tic
        moveOne(2, 50, 100)
        odpiranje(10 * j + i - 10) = toc
        i = i + 1
    end
    j = j + 1
    pause(30)
end
moveOne(2, 0, 100)
navor
rotacija
%}

% end Main

grabOne(2, 50) %prime s prstom št. 2 in navorom 50%. Hitrost premikanja osnovna
grabOne(1, 70, 100) %prime s prstom št. 1, navorom 70% in hitrostjo 100%

xlswrite("testni_objekt_7_rotacija.xlsx",rotacija)
xlswrite("testni_objekt_7_navor.xlsx",navor)
xlswrite("testni_objekt_7_odpiranje.xlsx",odpiranje)
xlswrite("testni_objekt_7_zapiranje.xlsx",zapiranje)
t0
%}

% Disable Dynamixel Torque
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
end

% Close port
closePort(port_num);

% Unload Library
unloadlibrary(lib_name);

close all;
disp('konec programa')




%Funkcije
function [] = calibrate(ID)  
    global max   
    global offset
    global port_num
    global PROTOCOL_VERSION 
    offset(ID) = 0;     
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 1);  
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1); 
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - 100);  
    i = 0;
    torque = 0;
    while i < 30   
        torque = readTorque(ID);    
        if torque < 60     
            i = i + 1;
        else
            i = 0;
        end
    end
    torque = 0;   
    while torque < 150   
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0);   
    pause(0.2)   
    offset(ID) = readRotation(ID);  
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 100);   
    i = 0;
    torque = 0;
    while i < 30   
        torque = readTorque(ID);   
        if torque < 60
            i = i + 1;
        else
            i = 0;
        end
    end
    torque = 0;   
    while torque < 150   
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0)   
    pause(0.2) 
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - 100);  
    i = 0;
    while i < 30   
        torque = readTorque(ID);
        if torque < 60
            i = i + 1;
        else
            i = 0;
        end
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0)   
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 4);  
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);  
    max(ID) = readRotation(ID);  
end



function [] = moveOne(ID, moveTo, speed)   %Premakne en prst na želeno pozicijo. Nastavimo ID motorja, želeno pozicijo (v odstotkih), opcijska je hitrost premika (v odstotkih)
    global max    %deklarira globalne spremenljivke
    global offset
    global port_num
    global PROTOCOL_VERSION
    global defaultSpeed
    switch nargin
        case 2    %lahko vpišemo samo ID motorja in želeni položaj, hitrost se nastavni na osnovno hitrost
            speed = defaultSpeed; 
        case 3    %lahko vpišemo vse 3 možne parametre
        otherwise
            disp('Invalid number of inputs')   %če vpišemo neko drugo število parametrov, funkcija javi napako v konzolo
    end
    position = max(ID) * (100 - moveTo) / 100 + offset(ID);   %pretvori pozicijo v odstotkih v pozicijo, ki jo razume motor. Upošteva tudi parametre kalibracije
    if position < 0
        position = position + 4294967296;   %motor razume le predznačen binarni zapis, zato moramo negativnemu številu prišteti še eno "periodo"
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 112, speed / 100 * 264);  %nastavi hitrost
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 116, position);  %nastavi pozicijo
    pause(0.1);   %počaka, da se motor začne vrteti
    movement = 1;
    while movement == 1   %ponavlja dokler je indikator premikanja 1
        movement = read1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 122);   %bere stanje o premikanju, ki je 0 ali 1. Ker je program hitrejši od mehanike je potreben prejšnje čakanje
    end
    %ko je konec zabke je dosežena želena pozicija in to je konec te funkcije
end

                                                   %Prime objekt z enim prstom. Uporabnik določi ID motorja, želeni maksimalni navor (v odstotkih), opcijska je hitrost (v odstotkih)
    function [] = grabOne(ID, maxTorque, speed)    %OPOZORILO: maksimalen želeni navor je mogoče nastaviti nad 100%, kar pa lahko vodi do poškodbe mehanike
    global port_num    %nastavi globalne spremenljivke
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 2         %lahko vpišemo samo ID motorja in želeni položaj, hitrost se nastavni na osnovno hitrost
            speed = defaultSpeed;
        case 3         %lahko vpišemo vse 3 možne parametre
        otherwise
            disp('Invalid number of inputs')     %če vpišemo neko drugo število parametrov, funkcija javi napako v konzolo
    end
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 1);   %nastavi Operating Mode na Velocity control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - speed / 100 * 264);  %začne se premikat
    torque = 0;
    pause(0.3);   %čaka da mine sunek navora preden se začne motor premikati s konstantno hitrostjo
    while torque < maxTorque * 2.5     %čaka, da navor doseže želeno vrednost (2,5 je pretvorba iz odstotkov v navor)
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0);  %motor se ustavi
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 4);   %nastavi Operating Mode na Position control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
end



function [currentRotation] = readRotation(ID)     %prebere trenutno vrednost rotacije na motorju (pri tem upošteva parametre kalibracije)
    global offset;      %deklarira globalne spremenljivke
    global port_num;
    global PROTOCOL_VERSION ;
    rotation = read4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 132);     %prebere rotacijo iz motorja
    if rotation > 2147483647
        currentRotation = rotation - 4294967295 - offset(ID);      %če prebere negativno predznačeno število, ga najprej pretvori v navadno negativno desetiško število in nato upošteva offset
    else
        currentRotation = rotation - offset(ID);     %prebrani rotaciji odšteje offset
    end
end

function [torque] = readTorque(ID)   %prebere absolutno vrednost navora
    global port_num;            %deklarira globalne spremenljivke
    global PROTOCOL_VERSION; 
    readTorque = read2ByteTxRx(port_num, PROTOCOL_VERSION , ID, 126);    %prebere vrednost navora
    if readTorque > 32767     %če je prebrani navor negativen v predznačenem številu, ga pretvori v pozitivno desetiško število, sicer pusti prebrani navor nespremenjen
       torque = 65535 - readTorque;
    else
       torque = readTorque;
    end
end
   

%Funkcija grabAll prijema z vsemi motorji hkrati. Možno je vpisati ali samo
%en navor, ali 3 navore, ali 3 navore in hitrost ali pa 3 navore in 3
%hitrosti. Vse vrednosti so zapisane v odstotkih. Če katerega od 3 prstov
%ne želimo premakniti, nastavimo hitrost ali pa navor na 0 (Bolje je 
% nastaviti hitrost na nič, saj se v tem primeru motor sploh ne aktivira).

function [] = grabAll(maxTorque1, maxTorque2, maxTorque3, speed1, speed2, speed3)    
    global port_num             %deklarira globalne spremenljivke
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 1   %če je vpisana samo ena vrednost, je to vrednost za maksimalni želeni navor pri prijemanju in se bo upoštevala na vseh motorjih. Hitrost motorjev bo nastavljena na osnovno hitrost
            maxTorque2 = maxTorque1;
            maxTorque3 = maxTorque1;
            speed1 = defaultSpeed;
            speed2 = defaultSpeed;
            speed3 = defaultSpeed;
        case 3   %če so vpisane 3 vrednosti, so to vrednosti za maksimalen zaželeni navor za vsak motor posebej. Hitrost motorjev bo nastavljena na osnovno hitrost
            speed1 = defaultSpeed;
            speed2 = defaultSpeed;
            speed3 = defaultSpeed;
        case 4   %če so vpisane 4 vrednosti, so prve 3 vrednosti za maksimalen zaželeni navor za vsak motor posebej. Zadnja vrednost je vrednost hitrosti motorjev in se upošteva na vseh motorjih
            speed2 = speed1;
            speed3 = speed1;
        case 6   %če je vpisanih 6 vrednosti, vsak motor dobi svojo vrednost želenega maksimalnega navora in hitrost premikanja
        otherwise
            disp('Invalid number of inputs')     %če vpišemo neko drugo število parametrov, funkcija javi napako v konzolo
    end
    %Pripravi motorje na Velocity control, če je želena hitrost večja od 0.
    %Če smo za kateri motor nastavili hitrost = 0, se ta motor ne bo
    %nastavil za delovanje
    if speed1 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 11, 1);   %nastavi Operating Mode na Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 104, 4294967295 - speed1 / 100 * 264);  %začne se premikat
        a = 0;
    else
        a = 1;
    end
    if speed2 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 11, 1);   %nastavi Operating Mode na Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 104, 4294967295 - speed2 / 100 * 264);  %začne se premikat
        b = 0;
    else
        b = 1;
    end
    if speed3 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 11, 1);   %nastavi Operating Mode na Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 104, 4294967295 - speed3 / 100 * 264);  %začne se premikat
        c = 0;
    else
        c = 1;
    end
    torque1 = 0;
    torque2 = 0;
    torque3 = 0;
    pause(0.3);  %počaka da je konec sunka navora
    while a == 0 || b == 0 || c == 0    %a, b in c so indikatorji, če je bilo premikanje že zaključeno. Neaktivnim motorjem se še pred izvajanjem zanke nastavi ta parameter na 1.
        torque1 = readTorque(1);   %prebere vse 3 navore
        torque2 = readTorque(2);
        torque3 = readTorque(3);
        if torque1 >= maxTorque1 * 2.5 && a == 0    %čaka na želeni navor motorja, pri čemer mora biti motor še aktiven
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 104, 0);  %ustavi motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 11, 4);   %nastavi Operating Mode na Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 1);   %enable torque
            a = 1;
        end 
        if torque2 >= maxTorque2 * 2.5 && b == 0    %čaka na želeni navor motorja, pri čemer mora biti motor še aktiven
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 104, 0);  %ustavi motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 11, 4);   %nastavi Operating Mode na Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 1);   %enable torque
            b = 1;
        end
        if torque3 >= maxTorque3 * 2.5 && c == 0    %čaka na želeni navor motorja, pri čemer mora biti motor še aktiven
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 104, 0);  %ustavi motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 11, 4);   %nastavi Operating Mode na Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 1);   %enable torque
            c = 1;
        end
    end
end



%Funkcija moveALL premakne vse motorje v želeni položaj. Lahko vpišemo le
%en položaj, ki premakne vse motorje v isti položaj, 3 položaje, za vsak
%motor posebej in lahko določimo še hitrost premikanja še s 4. vpisano
%vrednostjo. Vsi parametri so vpisani v odstotkih. Zapomni si: Možno je
%nastaviti le eno hitrost, saj funkcija določi to hitrost le prstu, ki mora
%izvesti največji premik, ostalim prstom pa določi novo hitrost, ki je
%manjša ali enaka želeni hitrosti na način, da se vsi motorji začnejo in
%končajo premikati naenkrat
function [] = moveAll(position1, position2, position3, speed)    
    global max              %deklarira globalne spremenljivke
    global offset
    global port_num
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 1     %če je vpisana le ena vrednost, ta vrednost predstavlja želeni položaj za vse prste. Hitrost je nastavljena na osnovno hitrost
            position2 = position1;
            position3 = position1;
            speed = defaultSpeed;
        case 3     %Če so vpisane 3 vrednosti, so to 3 vrednosti položajev za vsak prst posebej. Hitrost je nastavljena na osnovno hitrost
            speed = defaultSpeed;
        case 4     %Če so vpisane 3 vrednosti, so to 3 vrednosti položajev za vsak prst posebej. 4. vrednost nastavi hitrost premikanja prstov
        otherwise
            disp('Invalid number of inputs')            %če vpišemo neko drugo število parametrov, funkcija javi napako v konzolo
    end
    location1 = max(1) * (100 - position1) / 100 + offset(1);            %pretvori pozicijo v odstotkih v pozicijo, ki jo razume motor. Upošteva tudi parametre kalibracije
    location2 = max(2) * (100 - position2) / 100 + offset(2);
    location3 = max(3) * (100 - position3) / 100 + offset(3);
    currentLocation1 = readRotation(1) + offset(1);      %prebere trenutno lokacijo prsta (Prištet je offset, ker so položaji iz prejšnih vrstic že pripravljeni za premik motorjev, readRotation pa sicer bere položaj prsta in že upošteva offset. Po domače: ali je in zgornjim vrsticam in tem vrsticam prištet offset ali pa obema ni)
    currentLocation2 = readRotation(2) + offset(2); 
    currentLocation3 = readRotation(3) + offset(3); 
    delta1 = abs(location1 - currentLocation1);     %izračuna spremembo položaja med trenutnim in končnim položajem
    delta2 = abs(location2 - currentLocation2); 
    delta3 = abs(location3 - currentLocation3); 
    if delta1 >= delta2 && delta1 >= delta3       %najde prst, ki mora opraviti največjo spremembo položaja in mu priredi želeno hitrost. Ostalima dvema prstoma proporcionalno s spremembama položaja določi hitrost
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
    if location1 < 0    %Če je lokacija negativna, mu prištejemo "periodo" ker motor razume le binarna predznačena števila
        location1 = location1 + 4294967296;
    end
    if location2 < 0
        location2 = location2 + 4294967296;
    end
    if location3 < 0
        location3 = location3 + 4294967296;
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 112, speed1 / 100 * 265);  %nastavi hitrost
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 112, speed2 / 100 * 265);  %nastavi hitrost
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 112, speed3 / 100 * 265);  %nastavi hitrost
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 116, location1);  %nastavi pozicijo
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 116, location2);  %nastavi pozicijo
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 116, location3);  %nastavi pozicijo
    pause(0.1);   %čaka, da se motorji začnejo premikati (podobno kot pri moveOne)
    movement1 = 1;
    movement2 = 1;
    movement3 = 1;
    while movement1 == 1 || movement2 == 1 || movement3 == 1    %čaka, da se vsi motorji nehajo premikati
        movement1 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 122);
        movement2 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 122);
        movement3 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 122);
    end
end

%Pri kalibraciji vsak motor dobi svoj max oz. svojo razliko med maksimalnim
%in minimalnim položajem. Zaradi različnih razlogov so te max-i med sabo
%lahko zelo različni. To pa lahko pomeni, da se lahko kasneje prijemalo 
% obnaša nekoliko čudno npr. nastavimo enak položaj za vse prste, potem pa 
% se prsti ne postavijo v enak položaj. To popravita funkciji 
% calculateEqualMinimalDelata in calculateEqualDelta, ki nastavita vsem 
% prstom enak max. Funkcije so potrebne saj je položaj 0 prstov definiran, 
% ko je ta najbolj zaprt, 0% pri premikih pa je, ko je prst najbolj odprt. 
% Tako ne moremo le nastaviti vseh max-ov na isto vrednost, temveč moramo 
% tudi primerno spremeniti offset-e.  
function [] = calculateEqualMinimalMax()     %nastavi vse max-e na max od prsta z najmanjšo vrednostjo max-a. 
    global offset           %deklarira globalne spremenljivke
    global max
    if max(1) <= max(2) && max(1) <= max(3)     %išče najmanjši max
        offset(2) = offset(2) + max(2) - max(1);    %offset ostalih dveh prstov spremeni za razliko med starim in novim max-om
        offset(3) = offset(3) + max(3) - max(1);
        max(2) = max(1);            %ostale maxe nastavi na novi max
        max(3) = max(1);
    elseif max(2) <= max(1) && max(2) <= max(3)
        offset(1) = offset(1) + max(1) - max(2);
        offset(3) = offset(3) + max(3) - max(2);
        max(1) = max(2);
        max(3) = max(2);
    else
        offset(1) = offset(1) + max(1) - max(3);
        offset(2) = offset(2) + max(2) - max(3);
        max(1) = max(3);
        max(2) = max(3);
    end
end

function [] = calculateEqualMax(newMax)    %nastavi vse max-e na želeni max (običajen Max je okrog 24000) 
    global offset           %deklarira globalne spremenljivke
    global max
    offset(1) = offset(1) + max(1) - newMax;   %offset-e vseh prstov spremeni za razliko med starim in novim max-om     
    offset(2) = offset(2) + max(2) - newMax;
    offset(3) = offset(3) + max(3) - newMax;
    max(1) = newMax;          %maxe nastavi na novi max
    max(2) = newMax;
    max(3) = newMax;
end 
 
    function a = grabOneReadTorque(ID, maxTorque, speed)    %OPOZORILO: maksimalen želeni navor je mogoče nastaviti nad 100%, kar pa lahko vodi do poškodbe mehanike
    global port_num    %nastavi globalne spremenljivke
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 2         %lahko vpišemo samo ID motorja in želeni položaj, hitrost se nastavni na osnovno hitrost
            speed = defaultSpeed;
        case 3         %lahko vpišemo vse 3 možne parametre
        otherwise
            disp('Invalid number of inputs')     %če vpišemo neko drugo število parametrov, funkcija javi napako v konzolo
    end
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 1);   %nastavi Operating Mode na Velocity control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - speed / 100 * 264);  %začne se premikat
    torque = 0;
    pause(0.3);   %čaka da mine sunek navora preden se začne motor premikati s konstantno hitrostjo
    while torque < maxTorque * 2.5     %čaka, da navor doseže želeno vrednost (2,5 je pretvorba iz odstotkov v navor)
        torque = readTorque(ID);
    end
    a = readTorque(ID);
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0);  %motor se ustavi
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 4);   %nastavi Operating Mode na Position control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
end